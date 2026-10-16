-- TNMS 장애/성능관리 1차 구현 반영
-- 기준: 2026-10-08 확정사항
-- MariaDB 10.6 / arex_tnms
-- 1) 메인 역사상태: 2안 그룹매핑(심각/주의/정상) + 사용자 매핑/우선순위
-- 2) 통신단절: 설정시간 동안 데이터 미수집 상태, 기본 심각 그룹
-- 3) 성능지표: PERF-SEND 명시 CPU/MEMORY만 사용
-- 4) 성능 임계치: 정보(5)-경고(4)-낮음(3)-높음(2)-긴급(1), 해제(0)
-- 5) 임계치 발생/해제 모두 연속 N회, 성능장애는 dsblty_info에 생성
-- 6) 동일 장비 복수 장애는 긴급>높음>낮음>경고>정보 순 우선

USE `arex_tnms`;

/* --------------------------------------------------------------------------
 * 1. 메인 역사 상태 그룹 매핑 설정
 * -------------------------------------------------------------------------- */
INSERT INTO ui_stng_info
(UI_STNG_CD,UI_STNG_NM,UI_STNG_VL,UI_STNG_EXPLN,USE_YN,REG_DT,RGTR_ID)
VALUES
('DASHBOARD_CRITICAL_GRADES','심각 매핑 장애등급','EMERGENCY,HIGH,UNKNOWN','메인 심각 상태로 매핑할 원천 장애등급. UNKNOWN은 통신단절 가상등급','Y',NOW(),'SYSTEM'),
('DASHBOARD_CAUTION_GRADES','주의 매핑 장애등급','LOW,WARNING,INFO','메인 주의 상태로 매핑할 원천 장애등급','Y',NOW(),'SYSTEM'),
('DASHBOARD_NORMAL_GRADES','정상 매핑 장애등급','CLEAR','메인 정상 상태로 매핑할 원천 장애등급','Y',NOW(),'SYSTEM')
ON DUPLICATE KEY UPDATE
 UI_STNG_NM=VALUES(UI_STNG_NM), UI_STNG_EXPLN=VALUES(UI_STNG_EXPLN), USE_YN='Y';

UPDATE ui_stng_info
   SET UI_STNG_VL='CRITICAL,CAUTION,NORMAL',
       UI_STNG_EXPLN='앞에 위치한 메인 상태부터 역사 대표색으로 우선 적용',
       MDFCN_DT=NOW(), MDFR_ID='SYSTEM'
 WHERE UI_STNG_CD='STATION_STATUS_PRIORITY';

UPDATE com_cd_info SET COM_CD_NM='정상', COM_CD_SEQ=3 WHERE COM_CD_GROUP_ID='SYS_STTS' AND COM_CD='NORMAL';
UPDATE com_cd_info SET COM_CD_SEQ=1 WHERE COM_CD_GROUP_ID='SYS_STTS' AND COM_CD='CRITICAL';
UPDATE com_cd_info SET COM_CD_SEQ=2 WHERE COM_CD_GROUP_ID='SYS_STTS' AND COM_CD='CAUTION';
-- UNKNOWN은 장비별 통신단절 표시용 코드로 보존하되 역사 대표상태 우선순위에서는 제외함.
UPDATE com_cd_info SET COM_CD_SEQ=4 WHERE COM_CD_GROUP_ID='SYS_STTS' AND COM_CD='UNKNOWN';

-- 실제 연동 장애등급 6개를 사용하고, 기존 화면 샘플용 CAUTION/CRITICAL 코드는 이력 호환용으로만 보존한다.
UPDATE com_cd_group_info
   SET COM_CD_GROUP_EXPLN='실제 연동 장애등급: 긴급(1), 높음(2), 낮음(3), 경고(4), 정보(5), 해제(0)'
 WHERE COM_CD_GROUP_ID='DSBLTY_GRD';
UPDATE com_cd_info SET COM_CD_USE_YN='Y', COM_CD_SEQ=1, EXT1_CN='1' WHERE COM_CD_GROUP_ID='DSBLTY_GRD' AND COM_CD='EMERGENCY';
UPDATE com_cd_info SET COM_CD_USE_YN='Y', COM_CD_SEQ=2, EXT1_CN='2' WHERE COM_CD_GROUP_ID='DSBLTY_GRD' AND COM_CD='HIGH';
UPDATE com_cd_info SET COM_CD_USE_YN='Y', COM_CD_SEQ=3, EXT1_CN='3' WHERE COM_CD_GROUP_ID='DSBLTY_GRD' AND COM_CD='LOW';
UPDATE com_cd_info SET COM_CD_USE_YN='Y', COM_CD_SEQ=4, EXT1_CN='4' WHERE COM_CD_GROUP_ID='DSBLTY_GRD' AND COM_CD='WARNING';
UPDATE com_cd_info SET COM_CD_USE_YN='Y', COM_CD_SEQ=5, EXT1_CN='5' WHERE COM_CD_GROUP_ID='DSBLTY_GRD' AND COM_CD='INFO';
UPDATE com_cd_info SET COM_CD_USE_YN='Y', COM_CD_SEQ=6, EXT1_CN='0' WHERE COM_CD_GROUP_ID='DSBLTY_GRD' AND COM_CD='CLEAR';
UPDATE com_cd_info SET COM_CD_USE_YN='N' WHERE COM_CD_GROUP_ID='DSBLTY_GRD' AND COM_CD IN ('CAUTION','CRITICAL');

/* --------------------------------------------------------------------------
 * 2. 성능 임계치 5단계 확장
 * 실제 연동등급: 긴급=1, 높음=2, 낮음=3, 경고=4, 정보=5, 해제=0
 * -------------------------------------------------------------------------- */
ALTER TABLE thrshld_info
  ADD COLUMN IF NOT EXISTS INFO_VL decimal(20,6) DEFAULT NULL COMMENT '정보 임계값' AFTER PERF_IDCT_CD,
  ADD COLUMN IF NOT EXISTS WARNING_VL decimal(20,6) DEFAULT NULL COMMENT '경고 임계값' AFTER INFO_VL,
  ADD COLUMN IF NOT EXISTS LOW_VL decimal(20,6) DEFAULT NULL COMMENT '낮음 임계값' AFTER WARNING_VL,
  ADD COLUMN IF NOT EXISTS HIGH_VL decimal(20,6) DEFAULT NULL COMMENT '높음 임계값' AFTER LOW_VL,
  ADD COLUMN IF NOT EXISTS EMERGENCY_VL decimal(20,6) DEFAULT NULL COMMENT '긴급 임계값' AFTER HIGH_VL,
  ADD COLUMN IF NOT EXISTS CONTN_NOCS int unsigned NOT NULL DEFAULT 3 COMMENT '연속 발생/해제 확인 횟수' AFTER CONTN_SEC;

-- 기존 임계치 테이블이 비어 있어 운영값을 임의 생성하지 않음.
-- 화면에서 CPU/MEMORY 프로파일은 표시되도록 공통 프로파일만 생성하며 임계값은 사용자가 입력해야 함.
INSERT INTO thrshld_info
(LINK_SYS_CD,EQPMNT_SE_CD,PERF_IDCT_CD,INFO_VL,WARNING_VL,LOW_VL,HIGH_VL,EMERGENCY_VL,
 CMPR_OPRTR_CD,CONTN_SEC,CONTN_NOCS,ALRM_USE_YN,SMS_USE_YN,USE_YN,REG_DT,RGTR_ID)
SELECT NULL,NULL,'CPU_USGRT',NULL,NULL,NULL,NULL,NULL,'GE',0,3,'Y','N','Y',NOW(),'SYSTEM'
WHERE NOT EXISTS (SELECT 1 FROM thrshld_info WHERE PERF_IDCT_CD='CPU_USGRT' AND LINK_SYS_CD IS NULL AND EQPMNT_SE_CD IS NULL);

INSERT INTO thrshld_info
(LINK_SYS_CD,EQPMNT_SE_CD,PERF_IDCT_CD,INFO_VL,WARNING_VL,LOW_VL,HIGH_VL,EMERGENCY_VL,
 CMPR_OPRTR_CD,CONTN_SEC,CONTN_NOCS,ALRM_USE_YN,SMS_USE_YN,USE_YN,REG_DT,RGTR_ID)
SELECT NULL,NULL,'MMRY_USGRT',NULL,NULL,NULL,NULL,NULL,'GE',0,3,'Y','N','Y',NOW(),'SYSTEM'
WHERE NOT EXISTS (SELECT 1 FROM thrshld_info WHERE PERF_IDCT_CD='MMRY_USGRT' AND LINK_SYS_CD IS NULL AND EQPMNT_SE_CD IS NULL);

/* --------------------------------------------------------------------------
 * 3. 성능 임계치 판정상태
 * -------------------------------------------------------------------------- */
CREATE TABLE IF NOT EXISTS perf_thrshld_eval_stts (
  EQPMNT_SN bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  PERF_IDCT_CD varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '성능지표코드',
  LAST_CLCT_DT datetime DEFAULT NULL COMMENT '마지막 판정 수집일시',
  CAND_GRD_CD varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '연속확인 후보등급',
  CAND_NOCS int unsigned NOT NULL DEFAULT 0 COMMENT '연속확인횟수',
  ACTIVE_GRD_CD varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '현재 발생 성능장애등급',
  ACTIVE_DSBLTY_NO varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '현재 성능장애번호',
  MDFCN_DT datetime DEFAULT NULL COMMENT '수정일시',
  PRIMARY KEY (EQPMNT_SN,PERF_IDCT_CD),
  KEY IX_PERF_THR_ACTIVE (ACTIVE_DSBLTY_NO),
  CONSTRAINT FK_PERF_THR_EQ FOREIGN KEY (EQPMNT_SN) REFERENCES eqpmnt_info(EQPMNT_SN),
  CONSTRAINT FK_PERF_THR_IDCT FOREIGN KEY (PERF_IDCT_CD) REFERENCES perf_idct_info(PERF_IDCT_CD)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='성능임계치연속판정상태';

/* --------------------------------------------------------------------------
 * 4. 원천 장애등급 -> 메인 상태 변환 함수
 * -------------------------------------------------------------------------- */
DROP FUNCTION IF EXISTS fn_tnms_grade_to_main_status;
DELIMITER $$
CREATE FUNCTION fn_tnms_grade_to_main_status(p_grade varchar(20))
RETURNS varchar(20)
READS SQL DATA
BEGIN
  DECLARE v_critical varchar(4000) DEFAULT 'EMERGENCY,HIGH,UNKNOWN';
  DECLARE v_caution  varchar(4000) DEFAULT 'LOW,WARNING,INFO';
  DECLARE v_normal   varchar(4000) DEFAULT 'CLEAR';
  DECLARE v_grade varchar(20);

  SET v_grade = CASE p_grade WHEN 'CRITICAL' THEN 'EMERGENCY' WHEN 'CAUTION' THEN 'WARNING' ELSE p_grade END;
  SELECT COALESCE(MAX(CASE WHEN UI_STNG_CD='DASHBOARD_CRITICAL_GRADES' THEN UI_STNG_VL END),v_critical),
         COALESCE(MAX(CASE WHEN UI_STNG_CD='DASHBOARD_CAUTION_GRADES' THEN UI_STNG_VL END),v_caution),
         COALESCE(MAX(CASE WHEN UI_STNG_CD='DASHBOARD_NORMAL_GRADES' THEN UI_STNG_VL END),v_normal)
    INTO v_critical,v_caution,v_normal
    FROM ui_stng_info
   WHERE UI_STNG_CD IN ('DASHBOARD_CRITICAL_GRADES','DASHBOARD_CAUTION_GRADES','DASHBOARD_NORMAL_GRADES') AND USE_YN='Y';

  IF FIND_IN_SET(v_grade,v_critical) > 0 THEN RETURN 'CRITICAL'; END IF;
  IF FIND_IN_SET(v_grade,v_caution) > 0 THEN RETURN 'CAUTION'; END IF;
  IF FIND_IN_SET(v_grade,v_normal) > 0 THEN RETURN 'NORMAL'; END IF;
  RETURN 'NORMAL';
END$$
DELIMITER ;

DROP FUNCTION IF EXISTS fn_tnms_eqpmnt_main_status;
DELIMITER $$
CREATE FUNCTION fn_tnms_eqpmnt_main_status(p_eqpmnt_sn bigint unsigned)
RETURNS varchar(20)
READS SQL DATA
BEGIN
  DECLARE v_cntn char(1) DEFAULT NULL;
  DECLARE v_clct datetime DEFAULT NULL;
  DECLARE v_stts varchar(20) DEFAULT NULL;
  DECLARE v_offline_min int DEFAULT 5;
  DECLARE v_fault_grade varchar(20) DEFAULT NULL;
  DECLARE v_fault_status varchar(20) DEFAULT 'NORMAL';
  DECLARE v_disconnect_status varchar(20) DEFAULT NULL;
  DECLARE v_priority varchar(4000) DEFAULT 'CRITICAL,CAUTION,NORMAL';
  DECLARE v_fault_rank int DEFAULT 999;
  DECLARE v_disconnect_rank int DEFAULT 999;

  SELECT MAX(CNTN_YN),MAX(CLCT_DT),MAX(STTS_CD)
    INTO v_cntn,v_clct,v_stts
    FROM eqpmnt_stts WHERE EQPMNT_SN=p_eqpmnt_sn;

  SELECT COALESCE(MAX(CAST(UI_STNG_VL AS UNSIGNED)),5) INTO v_offline_min
    FROM ui_stng_info WHERE UI_STNG_CD='DASHBOARD_OFFLINE_MIN' AND USE_YN='Y';
  SELECT COALESCE(MAX(UI_STNG_VL),'CRITICAL,CAUTION,NORMAL') INTO v_priority
    FROM ui_stng_info WHERE UI_STNG_CD='STATION_STATUS_PRIORITY' AND USE_YN='Y';

  SELECT SUBSTRING_INDEX(
           GROUP_CONCAT(D.DSBLTY_GRD_CD ORDER BY FIELD(
             CASE D.DSBLTY_GRD_CD WHEN 'CRITICAL' THEN 'EMERGENCY' WHEN 'CAUTION' THEN 'WARNING' ELSE D.DSBLTY_GRD_CD END,
             'EMERGENCY','HIGH','LOW','WARNING','INFO','CLEAR') SEPARATOR ','),
           ',',1)
    INTO v_fault_grade
    FROM dsblty_info D
   WHERE D.EQPMNT_SN=p_eqpmnt_sn AND D.DSBLTY_END_DT IS NULL AND D.EXCP_APLY_YN='N';

  IF v_fault_grade IS NOT NULL THEN SET v_fault_status=fn_tnms_grade_to_main_status(v_fault_grade); END IF;
  IF v_clct IS NULL OR v_cntn='N' OR v_clct < DATE_SUB(NOW(),INTERVAL v_offline_min MINUTE) OR v_stts='OFFLINE' THEN
    SET v_disconnect_status=fn_tnms_grade_to_main_status('UNKNOWN');
  END IF;

  IF v_disconnect_status IS NULL THEN RETURN v_fault_status; END IF;
  SET v_fault_rank=COALESCE(NULLIF(FIND_IN_SET(v_fault_status,v_priority),0),999);
  SET v_disconnect_rank=COALESCE(NULLIF(FIND_IN_SET(v_disconnect_status,v_priority),0),999);
  IF v_disconnect_rank < v_fault_rank THEN RETURN v_disconnect_status; END IF;
  RETURN v_fault_status;
END$$
DELIMITER ;

CREATE OR REPLACE VIEW vw_eqpmnt_main_stts AS
SELECT E.EQPMNT_SN, fn_tnms_eqpmnt_main_status(E.EQPMNT_SN) AS STTS_CD
  FROM eqpmnt_info E
 WHERE E.USE_YN='Y';

/* --------------------------------------------------------------------------
 * 5. 성능 임계치 연속 판정 -> dsblty_info 장애 생성/해제
 * 새 PERF-SEND 값이 eqpmnt_perf_stts에 반영된 경우에만 1회 카운트함.
 * -------------------------------------------------------------------------- */
DROP PROCEDURE IF EXISTS sp_tnms_eval_performance_threshold;
DELIMITER $$
CREATE PROCEDURE sp_tnms_eval_performance_threshold()
BEGIN
  DECLARE done int DEFAULT 0;
  DECLARE v_eq bigint unsigned;
  DECLARE v_idct varchar(50);
  DECLARE v_value decimal(20,6);
  DECLARE v_clct datetime;
  DECLARE v_info decimal(20,6);
  DECLARE v_warning decimal(20,6);
  DECLARE v_low decimal(20,6);
  DECLARE v_high decimal(20,6);
  DECLARE v_emergency decimal(20,6);
  DECLARE v_need int unsigned;
  DECLARE v_grade varchar(20);
  DECLARE v_count int unsigned;
  DECLARE v_active_no varchar(50);
  DECLARE v_active_grade varchar(20);
  DECLARE v_fault_no varchar(50);
  DECLARE v_excp char(1);
  DECLARE v_ems varchar(20);
  DECLARE v_sou varchar(100);
  DECLARE v_place varchar(300);
  DECLARE v_name varchar(100);

  DECLARE cur CURSOR FOR
    SELECT P.EQPMNT_SN,P.PERF_IDCT_CD,P.MSRMT_VL,P.CLCT_DT,
           T.INFO_VL,T.WARNING_VL,T.LOW_VL,T.HIGH_VL,T.EMERGENCY_VL,COALESCE(T.CONTN_NOCS,3)
      FROM eqpmnt_perf_stts P
      JOIN eqpmnt_info E ON E.EQPMNT_SN=P.EQPMNT_SN AND E.USE_YN='Y'
      JOIN thrshld_info T ON T.THRSHLD_SN=(
           SELECT T2.THRSHLD_SN FROM thrshld_info T2
            WHERE T2.PERF_IDCT_CD=P.PERF_IDCT_CD AND T2.USE_YN='Y'
              AND (T2.LINK_SYS_CD IS NULL OR T2.LINK_SYS_CD=E.LINK_SYS_CD)
              AND (T2.EQPMNT_SE_CD IS NULL OR T2.EQPMNT_SE_CD=E.EQPMNT_SE_CD)
            ORDER BY (T2.LINK_SYS_CD IS NOT NULL) DESC,(T2.EQPMNT_SE_CD IS NOT NULL) DESC,T2.THRSHLD_SN DESC LIMIT 1)
      LEFT JOIN perf_thrshld_eval_stts S ON S.EQPMNT_SN=P.EQPMNT_SN AND S.PERF_IDCT_CD=P.PERF_IDCT_CD
     WHERE P.PERF_IDCT_CD IN ('CPU_USGRT','MMRY_USGRT')
       AND P.MSRMT_VL IS NOT NULL
       AND T.INFO_VL IS NOT NULL AND T.WARNING_VL IS NOT NULL AND T.LOW_VL IS NOT NULL AND T.HIGH_VL IS NOT NULL AND T.EMERGENCY_VL IS NOT NULL
       AND (S.LAST_CLCT_DT IS NULL OR P.CLCT_DT>S.LAST_CLCT_DT);
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_eq,v_idct,v_value,v_clct,v_info,v_warning,v_low,v_high,v_emergency,v_need;
    IF done=1 THEN LEAVE read_loop; END IF;

    SET v_grade = CASE
      WHEN v_value >= v_emergency THEN 'EMERGENCY'
      WHEN v_value >= v_high THEN 'HIGH'
      WHEN v_value >= v_low THEN 'LOW'
      WHEN v_value >= v_warning THEN 'WARNING'
      WHEN v_value >= v_info THEN 'INFO'
      ELSE 'CLEAR' END;

    INSERT INTO perf_thrshld_eval_stts(EQPMNT_SN,PERF_IDCT_CD,LAST_CLCT_DT,CAND_GRD_CD,CAND_NOCS,MDFCN_DT)
    VALUES(v_eq,v_idct,v_clct,v_grade,1,NOW())
    ON DUPLICATE KEY UPDATE
      LAST_CLCT_DT=VALUES(LAST_CLCT_DT),
      CAND_NOCS=IF(CAND_GRD_CD=VALUES(CAND_GRD_CD),CAND_NOCS+1,1),
      CAND_GRD_CD=VALUES(CAND_GRD_CD),MDFCN_DT=NOW();

    UPDATE eqpmnt_perf_stts SET STTS_CD=v_grade WHERE EQPMNT_SN=v_eq AND PERF_IDCT_CD=v_idct;

    SELECT CAND_NOCS,ACTIVE_DSBLTY_NO,ACTIVE_GRD_CD INTO v_count,v_active_no,v_active_grade
      FROM perf_thrshld_eval_stts WHERE EQPMNT_SN=v_eq AND PERF_IDCT_CD=v_idct;

    IF v_count >= v_need THEN
      IF v_grade='CLEAR' THEN
        IF v_active_no IS NOT NULL THEN
          UPDATE dsblty_info SET DSBLTY_END_DT=v_clct,OCRN_RCVR_SE_CD='0',LAST_MDFCN_DT=NOW()
           WHERE DSBLTY_NO=v_active_no AND DSBLTY_END_DT IS NULL;
          UPDATE perf_thrshld_eval_stts SET ACTIVE_DSBLTY_NO=NULL,ACTIVE_GRD_CD=NULL,MDFCN_DT=NOW()
           WHERE EQPMNT_SN=v_eq AND PERF_IDCT_CD=v_idct;
        END IF;
      ELSE
        IF v_active_no IS NULL THEN
          SELECT E.EMS_ID,E.SOU_EQPMNT_ID,COALESCE(S.STN_NM,E.INSTL_PLC_NM,E.EQPMNT_NM),E.EQPMNT_NM
            INTO v_ems,v_sou,v_place,v_name
            FROM eqpmnt_info E LEFT JOIN stn_info S ON S.STN_CD=E.STN_CD WHERE E.EQPMNT_SN=v_eq;
          SET v_excp=IF(EXISTS(
              SELECT 1 FROM dsblty_excp_group_eqpmnt_rel R
              JOIN dsblty_excp_schdl_info X ON X.EXCP_GROUP_SN=R.EXCP_GROUP_SN AND X.USE_YN='Y'
              WHERE R.EQPMNT_SN=v_eq AND R.ALL_IDCT_YN='Y' AND v_clct BETWEEN X.BGNG_DT AND X.END_DT), 'Y','N');
          SET v_fault_no=CONCAT('PERF-',v_eq,'-',IF(v_idct='CPU_USGRT','CPU','MEM'),'-',DATE_FORMAT(v_clct,'%Y%m%d%H%i%s'));
          INSERT INTO dsblty_info(DSBLTY_NO,EMS_ID,SOU_EQPMNT_ID,EQPMNT_SN,DSBLTY_OCRN_PLC_NM,DSBLTY_GRD_CD,OCRN_RCVR_SE_CD,
                                  DSBLTY_OCRN_DT,DSBLTY_OCRN_CN,DSBLTY_JGMT_CD,PRCS_STTS_CD,EXCP_APLY_YN,SRC_EVNT_NO,LAST_MDFCN_DT)
          VALUES(v_fault_no,v_ems,v_sou,v_eq,v_place,v_grade,'1',v_clct,
                 CONCAT(IF(v_idct='CPU_USGRT','CPU 사용률','MEMORY 사용률'),' 임계치 ',v_grade,' 발생 (',v_value,'%)'),
                 'STATUS','UNCONFIRMED',v_excp,CONCAT('PERF:',v_eq,':',v_idct),NOW());
          UPDATE perf_thrshld_eval_stts SET ACTIVE_DSBLTY_NO=v_fault_no,ACTIVE_GRD_CD=v_grade,MDFCN_DT=NOW()
           WHERE EQPMNT_SN=v_eq AND PERF_IDCT_CD=v_idct;
        ELSEIF v_active_grade <> v_grade THEN
          UPDATE dsblty_info SET DSBLTY_GRD_CD=v_grade,
                 DSBLTY_OCRN_CN=CONCAT(IF(v_idct='CPU_USGRT','CPU 사용률','MEMORY 사용률'),' 임계치 ',v_grade,' 발생 (',v_value,'%)'),LAST_MDFCN_DT=NOW()
           WHERE DSBLTY_NO=v_active_no AND DSBLTY_END_DT IS NULL;
          UPDATE perf_thrshld_eval_stts SET ACTIVE_GRD_CD=v_grade,MDFCN_DT=NOW()
           WHERE EQPMNT_SN=v_eq AND PERF_IDCT_CD=v_idct;
        END IF;
      END IF;
    END IF;
  END LOOP;
  CLOSE cur;
END$$
DELIMITER ;

-- 1분마다 신규 성능값만 판정. event_scheduler가 OFF인 운영 DB에서는 DBA가 ON 설정 필요.
DROP EVENT IF EXISTS ev_tnms_eval_performance_threshold;
CREATE EVENT ev_tnms_eval_performance_threshold
ON SCHEDULE EVERY 1 MINUTE
DO CALL sp_tnms_eval_performance_threshold();

-- 최초 1회 즉시 실행
CALL sp_tnms_eval_performance_threshold();
