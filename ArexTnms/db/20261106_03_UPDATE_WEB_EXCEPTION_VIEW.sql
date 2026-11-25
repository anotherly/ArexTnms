-- 웹 예외설정 필터와 웹 임계치 장애를 반영한 읽기 전용 VIEW. com/raw 원천 변경 없음.
-- com_/raw_ 원본 테이블, 트리거, 이벤트/프로시저는 수정하지 않습니다.
-- 먼저 전체 DB를 백업한 후 HeidiSQL에서 이 파일만 실행하십시오.
USE arex_tnms;

CREATE OR REPLACE VIEW vw_tnms_gateway_device_live AS
SELECT
 D.ems_id, D.device_id, D.device_nm, D.device_type, D.device_ip,
 D.device_station, D.stn_cd, D.device_desc, D.device_model, D.server_ip,
 D.device_maker, D.device_check, D.test_yn, D.ping_alive, D.ping_dt,
 CASE D.ems_id WHEN 1 THEN 'EMS_TX' WHEN 4 THEN 'VMS'
   WHEN 11 THEN 'PBX' WHEN 13 THEN 'EMS_PIDS' WHEN 16 THEN 'SCADA_SEC'
   ELSE NULL END AS link_sys_cd,
 U.cpu_usage, U.memory_usage, U.disk_usage, U.reg_dt AS usage_dt,
 F.fault_count, F.severe_grade, F.last_event_dt,
 CASE WHEN U.reg_dt >= NOW() - INTERVAL 5 MINUTE THEN 'Y' ELSE 'N' END AS usage_fresh_yn,
 CASE
   WHEN D.ping_dt IS NULL OR D.ping_alive = 0 THEN 'UNKNOWN'
   WHEN TIMESTAMPDIFF(SECOND, D.ping_dt, NOW()) >
      60 * GREATEST(1, COALESCE((SELECT CAST(UI_STNG_VL AS UNSIGNED)
            FROM web_ui_stng_info
            WHERE UI_STNG_CD = 'DASHBOARD_OFFLINE_MIN' AND USE_YN = 'Y'
            LIMIT 1), 5)) THEN 'UNKNOWN'
   WHEN D.ping_alive = -1 THEN 'OFFLINE'
   WHEN D.ping_alive <> 1 THEN 'UNKNOWN'
   WHEN F.severe_grade IN (1, 2) THEN 'CRITICAL'
   WHEN F.severe_grade IN (3, 4, 5) THEN 'CAUTION'
   ELSE 'NORMAL'
 END AS stts_cd,
 CASE
   WHEN D.ping_alive = 0 OR D.ping_dt IS NULL THEN 'PING 미확인'
   WHEN TIMESTAMPDIFF(SECOND, D.ping_dt, NOW()) >
      60 * GREATEST(1, COALESCE((SELECT CAST(UI_STNG_VL AS UNSIGNED)
            FROM web_ui_stng_info
            WHERE UI_STNG_CD = 'DASHBOARD_OFFLINE_MIN' AND USE_YN = 'Y'
            LIMIT 1), 5)) THEN 'PING 수집 지연'
   WHEN D.ping_alive = -1 THEN 'PING 실패'
   WHEN F.severe_grade IS NOT NULL THEN CONCAT('발생 장애(등급 ', F.severe_grade, ')')
   ELSE '정상'
 END AS stts_expln
FROM com_device_info D
LEFT JOIN com_device_usage U ON U.ems_id=D.ems_id AND U.device_id=D.device_id
LEFT JOIN (
 SELECT Q.ems_id,Q.device_id,COUNT(*) AS fault_count,
        MIN(CAST(Q.event_grade AS UNSIGNED)) AS severe_grade,
        MAX(Q.event_dt) AS last_event_dt
 FROM (
   SELECT ems_id,device_id,event_grade,event_dt FROM raw_event_action
    WHERE event_yn=1 AND event_grade IN ('1','2','3','4','5')
   UNION ALL
   SELECT EMS_ID AS ems_id,DEVICE_ID AS device_id,CAST(EVENT_GRADE AS CHAR) AS event_grade,
           EVENT_DT AS event_dt FROM web_perf_thrshld_event WHERE EVENT_YN=1
 ) Q WHERE 1=1

    AND NOT EXISTS (
      SELECT 1 FROM web_dsblty_excp_group_eqpmnt_rel M
      JOIN web_dsblty_excp_group_info G ON G.EXCP_GROUP_SN=M.EXCP_GROUP_SN AND G.USE_YN='Y'
      JOIN web_dsblty_excp_schdl_info X ON X.EXCP_GROUP_SN=G.EXCP_GROUP_SN AND X.USE_YN='Y'
      WHERE M.EMS_ID=Q.ems_id AND M.DEVICE_ID=Q.device_id
        AND NOW() >= X.BGNG_DT
        AND (X.NO_END_YN='Y' OR X.END_DT IS NULL OR NOW() <= X.END_DT)
        AND (NOT EXISTS (SELECT 1 FROM web_dsblty_excp_schdl_grd_rel R WHERE R.EXCP_SCHDL_SN=X.EXCP_SCHDL_SN)
             OR EXISTS (SELECT 1 FROM web_dsblty_excp_schdl_grd_rel R WHERE R.EXCP_SCHDL_SN=X.EXCP_SCHDL_SN
               AND R.DSBLTY_GRD_CD=CASE CAST(Q.event_grade AS CHAR)
                WHEN '1' THEN 'EMERGENCY' WHEN '2' THEN 'HIGH' WHEN '3' THEN 'LOW'
                WHEN '4' THEN 'WARNING' WHEN '5' THEN 'INFO' END))
        AND (X.REPT_CYCLE_CN='ONCE'
           OR (X.REPT_CYCLE_CN LIKE 'REPEAT|%'
              AND (X.REPT_CYCLE_CN LIKE 'REPEAT|DAILY|%'
                OR (X.REPT_CYCLE_CN LIKE 'REPEAT|WEEKLY|%' AND
                   FIND_IN_SET(ELT(WEEKDAY(NOW())+1,'MON','TUE','WED','THU','FRI','SAT','SUN'),
                     SUBSTRING_INDEX(X.REPT_CYCLE_CN,'|',-1)) > 0)
                OR (X.REPT_CYCLE_CN LIKE 'REPEAT|MONTHLY|%'
                  AND DAYOFMONTH(NOW())=DAYOFMONTH(X.BGNG_DT)))
              AND (X.REPT_START_TM IS NULL OR X.REPT_END_TM IS NULL
                OR (X.REPT_START_TM<=X.REPT_END_TM AND TIME(NOW()) BETWEEN X.REPT_START_TM AND X.REPT_END_TM)
                OR (X.REPT_START_TM>X.REPT_END_TM AND
                  (TIME(NOW())>=X.REPT_START_TM OR TIME(NOW())<=X.REPT_END_TM)))))
    )
 GROUP BY Q.ems_id,Q.device_id
) F ON F.ems_id=D.ems_id AND F.device_id=D.device_id
WHERE D.use_yn='Y' AND D.ems_id IN (1,4,11,13,16);

-- 확인용: 전송(1)·행선(13) 실시간 수집현황
SELECT ems_id, COUNT(*) AS total_devices,
 SUM(stts_cd='NORMAL') AS normal_count,
 SUM(stts_cd='CAUTION') AS caution_count,
 SUM(stts_cd='CRITICAL') AS critical_count,
 SUM(stts_cd='OFFLINE') AS offline_count,
 SUM(stts_cd='UNKNOWN') AS unknown_count,
 MAX(ping_dt) AS latest_ping_dt, MAX(usage_dt) AS latest_usage_dt
FROM vw_tnms_gateway_device_live
GROUP BY ems_id ORDER BY ems_id;
