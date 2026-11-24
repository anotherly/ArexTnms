-- 2026-11-10 SQL 01 실행 후 검증 (데이터 변경 없음)
USE arex_tnms;
SELECT C.COM_CD, C.COM_CD_NM, C.GW_CD, L.LINK_SYS_CD, L.DEVICE_COM_CD
  FROM com_cd_info C JOIN web_link_sys_info L ON L.DEVICE_COM_CD=C.COM_CD
 WHERE C.COM_CD_GROUP_ID='CD_DVIC' AND C.GW_SRC_COL='ems_id' AND C.COM_CD_USE_YN='Y'
 ORDER BY C.COM_CD_SEQ;

SELECT COUNT(*) AS mapping_count,
       COUNT(DISTINCT ems_id) AS unique_ems,
       COUNT(DISTINCT link_sys_cd) AS unique_web_systems
  FROM vw_tnms_system_map;
-- 세 개 값 모두 5 예상. 5가 아니면 WEB 배포 중단, 공통코드/연계 매핑 확인.

SELECT ems_id, COUNT(*) AS duplicated
  FROM vw_tnms_system_map GROUP BY ems_id HAVING COUNT(*)<>1;
SELECT link_sys_cd, COUNT(*) AS duplicated
  FROM vw_tnms_system_map GROUP BY link_sys_cd HAVING COUNT(*)<>1;
-- 위 두 쿼리 0행 예상.

SELECT (SELECT COUNT(*) FROM com_device_info D
        WHERE D.use_yn='Y' AND EXISTS(SELECT 1 FROM vw_tnms_system_map S WHERE S.ems_id=D.ems_id)) AS expected_devices,
       (SELECT COUNT(*) FROM vw_tnms_device_base) AS base_devices,
       (SELECT COUNT(*) FROM vw_tnms_device_status) AS status_devices,
       (SELECT COUNT(*) FROM vw_tnms_device_performance) AS perf_devices,
       (SELECT COUNT(*) FROM vw_tnms_gateway_device_live) AS legacy_devices;
-- 위 다섯 수는 동일해야 하며, 장비목록에 미등록 EMS가 존재하면 expected_devices부터 조사.

SELECT D.link_sys_cd, COUNT(*) AS device_count,
       SUM(D.stts_cd='NORMAL') AS normal_count,
       SUM(D.stts_cd='OFFLINE') AS offline_count,
       SUM(D.stts_cd='UNKNOWN') AS unknown_count,
       SUM(D.stts_cd='CRITICAL') AS critical_count,
       SUM(D.stts_cd='CAUTION') AS caution_count
  FROM vw_tnms_device_status D GROUP BY D.link_sys_cd ORDER BY D.link_sys_cd;

SELECT D.link_sys_cd, COUNT(*) AS device_count,
       SUM(D.usage_fresh_yn='Y') AS usage_fresh_count,
       MAX(D.usage_dt) AS latest_usage_dt
  FROM vw_tnms_device_performance D GROUP BY D.link_sys_cd ORDER BY D.link_sys_cd;

SELECT COUNT(*) AS active_fault_devices FROM vw_tnms_active_fault_summary;

-- 실행계획 확인: EXPLAIN은 쿼리 데이터 수정 없음
EXPLAIN SELECT D.device_id, D.stts_cd FROM vw_tnms_device_status D WHERE D.link_sys_cd='EMS_PIDS';
EXPLAIN SELECT D.device_id, D.cpu_usage FROM vw_tnms_device_performance D
 WHERE D.link_sys_cd='EMS_PIDS' ORDER BY D.usage_dt DESC LIMIT 10;

-- 원천 테이블 인덱스 상태만 조사. 인덱스 추가는 Gateway 개발자 협의 사항.
SHOW INDEX FROM raw_ping_log;
SHOW INDEX FROM raw_usage_log;
EXPLAIN SELECT ems_id,COUNT(*) FROM raw_ping_log
 WHERE reg_dt >= NOW()-INTERVAL 5 MINUTE GROUP BY ems_id;
