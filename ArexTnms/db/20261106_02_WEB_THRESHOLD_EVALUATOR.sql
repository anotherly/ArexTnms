-- Web-only performance threshold evaluator. Does NOT change/write com_* or raw_*.
-- Run AFTER 20261106_RESTORE_WEB_BUSINESS_TABLES.sql.
USE arex_tnms;
CREATE TABLE IF NOT EXISTS web_perf_thrshld_eval_state (
 THRSHLD_SN BIGINT UNSIGNED NOT NULL,
 EMS_ID INT NOT NULL,
 DEVICE_ID VARCHAR(50) NOT NULL,
 LAST_USAGE_SEQ BIGINT UNSIGNED NOT NULL DEFAULT 0,
 CANDIDATE_GRADE TINYINT NOT NULL DEFAULT 0,
 CANDIDATE_COUNT INT NOT NULL DEFAULT 0,
 ACTIVE_GRADE TINYINT NOT NULL DEFAULT 0,
 ACTIVE_EVENT_SN BIGINT UNSIGNED DEFAULT NULL,
 LAST_VALUE DECIMAL(8,2) DEFAULT NULL,
 MOD_DT DATETIME DEFAULT NULL,
 PRIMARY KEY(THRSHLD_SN,EMS_ID,DEVICE_ID),
 CONSTRAINT FK_WEB_PERF_STATE_THR FOREIGN KEY(THRSHLD_SN) REFERENCES web_thrshld_info(THRSHLD_SN) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
CREATE TABLE IF NOT EXISTS web_perf_thrshld_event (
 PERF_EVENT_SN BIGINT UNSIGNED NOT NULL AUTO_INCREMENT,
 THRSHLD_SN BIGINT UNSIGNED NOT NULL,
 EMS_ID INT NOT NULL,
 DEVICE_ID VARCHAR(50) NOT NULL,
 PERF_IDCT_CD VARCHAR(20) NOT NULL,
 EVENT_GRADE TINYINT NOT NULL,
 EVENT_YN TINYINT NOT NULL DEFAULT 1,
 EVENT_DT DATETIME NOT NULL,
 EVENT_EDT DATETIME DEFAULT NULL,
 LAST_VALUE DECIMAL(8,2) NOT NULL,
 REG_DT DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
 PRIMARY KEY(PERF_EVENT_SN),
 INDEX IX_WEB_PERF_EVENT_CURRENT(EMS_ID,DEVICE_ID,EVENT_YN,EVENT_DT),
 CONSTRAINT FK_WEB_PERF_EVENT_THR FOREIGN KEY(THRSHLD_SN) REFERENCES web_thrshld_info(THRSHLD_SN)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DELIMITER $$
DROP PROCEDURE IF EXISTS sp_tnms_web_eval_performance_threshold$$
CREATE PROCEDURE sp_tnms_web_eval_performance_threshold()
BEGIN
 DECLARE finished INT DEFAULT 0;
 DECLARE lock_ok INT DEFAULT 0;
 DECLARE v_profile BIGINT UNSIGNED;
 DECLARE v_need INT;
 DECLARE v_info DECIMAL(8,2);
 DECLARE v_warning DECIMAL(8,2);
 DECLARE v_low DECIMAL(8,2);
 DECLARE v_high DECIMAL(8,2);
 DECLARE v_emergency DECIMAL(8,2);
 DECLARE v_metric VARCHAR(20);
 DECLARE v_seq BIGINT UNSIGNED;
 DECLARE v_ems INT;
 DECLARE v_device VARCHAR(50);
 DECLARE v_dt DATETIME;
 DECLARE v_value DECIMAL(8,2);
 DECLARE v_grade INT;
 DECLARE v_candidate INT;
 DECLARE v_count INT;
 DECLARE v_active INT;
 DECLARE v_active_event BIGINT UNSIGNED;
 DECLARE v_new_event BIGINT UNSIGNED;
 DECLARE cur CURSOR FOR
   SELECT T.THRSHLD_SN,T.CONTN_NOCS,T.INFO_VL,T.WARNING_VL,T.LOW_VL,
          T.HIGH_VL,T.EMERGENCY_VL,T.PERF_IDCT_CD,
          R.usage_seq,R.ems_id,R.device_id,R.reg_dt,
          CASE T.PERF_IDCT_CD WHEN 'CPU_USGRT' THEN R.cpu_usage ELSE R.memory_usage END
    FROM raw_usage_log R
    JOIN web_thrshld_info T ON T.USE_YN='Y'
      AND T.PERF_IDCT_CD IN ('CPU_USGRT','MMRY_USGRT')
      AND (T.LINK_SYS_CD IS NULL OR T.LINK_SYS_CD='' OR T.LINK_SYS_CD =
          CASE R.ems_id WHEN 1 THEN 'EMS_TX' WHEN 4 THEN 'VMS' WHEN 11 THEN 'PBX'
            WHEN 13 THEN 'EMS_PIDS' WHEN 16 THEN 'SCADA_SEC' ELSE '_' END)
      AND NOT EXISTS (
        SELECT 1 FROM web_thrshld_info Earlier
        WHERE Earlier.USE_YN='Y' AND Earlier.PERF_IDCT_CD=T.PERF_IDCT_CD
          AND COALESCE(Earlier.LINK_SYS_CD,'')=COALESCE(T.LINK_SYS_CD,'')
          AND Earlier.THRSHLD_SN < T.THRSHLD_SN)
      AND NOT (COALESCE(T.LINK_SYS_CD,'')='' AND EXISTS (
        SELECT 1 FROM web_thrshld_info Specific
        WHERE Specific.USE_YN='Y' AND Specific.PERF_IDCT_CD=T.PERF_IDCT_CD
          AND Specific.LINK_SYS_CD=CASE R.ems_id WHEN 1 THEN 'EMS_TX'
          WHEN 4 THEN 'VMS' WHEN 11 THEN 'PBX' WHEN 13 THEN 'EMS_PIDS'
          WHEN 16 THEN 'SCADA_SEC' ELSE '_' END))
    LEFT JOIN web_perf_thrshld_eval_state S
      ON S.THRSHLD_SN=T.THRSHLD_SN AND S.EMS_ID=R.ems_id AND S.DEVICE_ID=R.device_id
    WHERE R.reg_dt >= NOW() - INTERVAL 10 MINUTE
      AND R.usage_seq > COALESCE(S.LAST_USAGE_SEQ,0)
    ORDER BY R.usage_seq, T.THRSHLD_SN LIMIT 2000;
 DECLARE CONTINUE HANDLER FOR NOT FOUND SET finished=1;
 SELECT GET_LOCK('tnms_web_threshold_evaluator',0) INTO lock_ok;
 IF lock_ok=1 THEN
 OPEN cur;
 read_loop: LOOP
  FETCH cur INTO v_profile,v_need,v_info,v_warning,v_low,v_high,v_emergency,
                 v_metric,v_seq,v_ems,v_device,v_dt,v_value;
  IF finished=1 THEN LEAVE read_loop; END IF;
  SET v_grade=CASE
    WHEN v_value>=v_emergency THEN 1 WHEN v_value>=v_high THEN 2
    WHEN v_value>=v_low THEN 3 WHEN v_value>=v_warning THEN 4
    WHEN v_value>=v_info THEN 5 ELSE 0 END;
  INSERT IGNORE INTO web_perf_thrshld_eval_state
   (THRSHLD_SN,EMS_ID,DEVICE_ID,LAST_USAGE_SEQ,CANDIDATE_GRADE,CANDIDATE_COUNT,ACTIVE_GRADE,MOD_DT)
   VALUES(v_profile,v_ems,v_device,0,0,0,0,NOW());
  SELECT CANDIDATE_GRADE,CANDIDATE_COUNT,ACTIVE_GRADE,ACTIVE_EVENT_SN
    INTO v_candidate,v_count,v_active,v_active_event
    FROM web_perf_thrshld_eval_state
    WHERE THRSHLD_SN=v_profile AND EMS_ID=v_ems AND DEVICE_ID=v_device FOR UPDATE;
  IF v_candidate=v_grade THEN SET v_count=v_count+1;
  ELSE SET v_candidate=v_grade; SET v_count=1; END IF;
  SET v_new_event=v_active_event;
  IF v_count>=v_need AND v_active<>v_grade THEN
    IF v_active_event IS NOT NULL THEN
      UPDATE web_perf_thrshld_event
         SET EVENT_YN=0,EVENT_EDT=v_dt,LAST_VALUE=v_value
       WHERE PERF_EVENT_SN=v_active_event AND EVENT_YN=1;
    END IF;
    SET v_new_event=NULL;
    IF v_grade<>0 THEN
      INSERT INTO web_perf_thrshld_event
        (THRSHLD_SN,EMS_ID,DEVICE_ID,PERF_IDCT_CD,EVENT_GRADE,EVENT_YN,EVENT_DT,LAST_VALUE)
      VALUES(v_profile,v_ems,v_device,v_metric,v_grade,1,v_dt,v_value);
      SET v_new_event=LAST_INSERT_ID();
    END IF;
    SET v_active=v_grade;
  END IF;
  UPDATE web_perf_thrshld_eval_state
    SET LAST_USAGE_SEQ=v_seq,CANDIDATE_GRADE=v_candidate,CANDIDATE_COUNT=v_count,
        ACTIVE_GRADE=v_active,ACTIVE_EVENT_SN=v_new_event,LAST_VALUE=v_value,MOD_DT=NOW()
  WHERE THRSHLD_SN=v_profile AND EMS_ID=v_ems AND DEVICE_ID=v_device;
 END LOOP;
 CLOSE cur;
 DO RELEASE_LOCK('tnms_web_threshold_evaluator');
 END IF;
END$$
DELIMITER ;

-- Web-only evaluator; no modifications to gateway events/triggers.
CREATE EVENT IF NOT EXISTS ev_tnms_web_eval_performance_threshold
 ON SCHEDULE EVERY 1 MINUTE
 DO CALL sp_tnms_web_eval_performance_threshold();
-- Verify MariaDB global event_scheduler is ON; this script does not change global server settings.
