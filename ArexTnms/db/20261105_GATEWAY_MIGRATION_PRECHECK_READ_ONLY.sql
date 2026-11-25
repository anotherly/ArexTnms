-- TNMS 2026-11-05 / 최신 DB 11:32:59 스키마 기준 / 조회 전용
-- 실행해도 데이터 변경 없음. 아래 결과를 검토한 뒤 DROP 스크립트 사용.
USE arex_tnms;

-- 1) 제거 후보별 원본 행수: COUNT는 실제 남아 있는 데이터의 규모 확인용.
SELECT 'web_com_cd_group_info' AS object_name, COUNT(*) AS rows_count FROM web_com_cd_group_info
UNION ALL SELECT 'web_com_cd_info', COUNT(*) FROM web_com_cd_info
UNION ALL SELECT 'web_clct_cycle_info', COUNT(*) FROM web_clct_cycle_info
UNION ALL SELECT 'web_clct_excn_hstry', COUNT(*) FROM web_clct_excn_hstry
UNION ALL SELECT 'web_perf_raw_data', COUNT(*) FROM web_perf_raw_data
UNION ALL SELECT 'web_perf_hr_stats', COUNT(*) FROM web_perf_hr_stats
UNION ALL SELECT 'web_perf_day_stats', COUNT(*) FROM web_perf_day_stats
UNION ALL SELECT 'web_eqpmnt_stts', COUNT(*) FROM web_eqpmnt_stts
UNION ALL SELECT 'web_eqpmnt_perf_stts', COUNT(*) FROM web_eqpmnt_perf_stts
UNION ALL SELECT 'web_eqpmnt_info', COUNT(*) FROM web_eqpmnt_info
UNION ALL SELECT 'web_dsblty_info', COUNT(*) FROM web_dsblty_info;

-- 2) 외래키가 가리키는 대상 테이블, 변경 시 선행해야 할 자식 테이블 확인.
SELECT TABLE_NAME AS child_table, CONSTRAINT_NAME,
       REFERENCED_TABLE_NAME AS parent_table
  FROM information_schema.KEY_COLUMN_USAGE
 WHERE TABLE_SCHEMA=DATABASE() AND REFERENCED_TABLE_SCHEMA=DATABASE()
   AND REFERENCED_TABLE_NAME IN
    ('web_com_cd_group_info','web_com_cd_info','web_clct_cycle_info',
     'web_clct_excn_hstry','web_perf_raw_data','web_perf_hr_stats',
     'web_perf_day_stats','web_eqpmnt_stts','web_eqpmnt_perf_stts',
     'web_eqpmnt_info','web_dsblty_info')
 ORDER BY REFERENCED_TABLE_NAME,TABLE_NAME;

-- 3) VIEW / FUNCTION / PROCEDURE / EVENT / TRIGGER 본문이 이전 테이블을 사용하는지 검토.
SELECT 'VIEW' AS object_type, TABLE_NAME AS object_name, LEFT(VIEW_DEFINITION,300) AS preview
  FROM information_schema.VIEWS
 WHERE TABLE_SCHEMA=DATABASE() AND (
       VIEW_DEFINITION LIKE '%web_eqpmnt_%' OR VIEW_DEFINITION LIKE '%web_perf_%'
       OR VIEW_DEFINITION LIKE '%web_clct_%' OR VIEW_DEFINITION LIKE '%web_com_cd_%')
UNION ALL
SELECT ROUTINE_TYPE, ROUTINE_NAME, LEFT(ROUTINE_DEFINITION,300)
  FROM information_schema.ROUTINES
 WHERE ROUTINE_SCHEMA=DATABASE() AND (
       ROUTINE_DEFINITION LIKE '%web_eqpmnt_%' OR ROUTINE_DEFINITION LIKE '%web_perf_%'
       OR ROUTINE_DEFINITION LIKE '%web_clct_%' OR ROUTINE_DEFINITION LIKE '%web_com_cd_%')
UNION ALL
SELECT 'EVENT', EVENT_NAME, LEFT(EVENT_DEFINITION,300)
  FROM information_schema.EVENTS
 WHERE EVENT_SCHEMA=DATABASE() AND (
       EVENT_DEFINITION LIKE '%web_eqpmnt_%' OR EVENT_DEFINITION LIKE '%web_perf_%'
       OR EVENT_DEFINITION LIKE '%web_clct_%' OR EVENT_DEFINITION LIKE '%web_com_cd_%')
UNION ALL
SELECT 'TRIGGER', TRIGGER_NAME, LEFT(ACTION_STATEMENT,300)
  FROM information_schema.TRIGGERS
 WHERE TRIGGER_SCHEMA=DATABASE() AND (
       ACTION_STATEMENT LIKE '%web_eqpmnt_%' OR ACTION_STATEMENT LIKE '%web_perf_%'
       OR ACTION_STATEMENT LIKE '%web_clct_%' OR ACTION_STATEMENT LIKE '%web_com_cd_%');

-- 4) 신규 공통코드가 이관되었는지 확인
SELECT COM_CD_GROUP_ID,COUNT(*) AS code_count FROM com_cd_info GROUP BY COM_CD_GROUP_ID ORDER BY COM_CD_GROUP_ID;
-- 5) 실제 장비 및 최근 수신
SELECT ems_id,COUNT(*) AS devices,MAX(ping_dt) AS latest_ping
  FROM com_device_info WHERE use_yn='Y' GROUP BY ems_id;
SELECT ems_id,MAX(reg_dt) AS latest_usage FROM raw_usage_log GROUP BY ems_id;
