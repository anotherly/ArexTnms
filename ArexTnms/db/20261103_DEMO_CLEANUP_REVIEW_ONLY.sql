-- [확인용 / 읽기 전용] TNMS 시연 데이터 및 자동 생성 객체 점검
-- 이 파일에는 DROP/DELETE/UPDATE를 넣지 않았습니다.
-- 실제 게이트웨이 장애/성능 수집 및 웹 조회를 검증하기 전에는 삭제하지 마세요.
USE arex_tnms;

-- 시연/업무 이벤트의 설정 확인. MariaDB 전역 event_scheduler와는 별개입니다.
SHOW EVENTS FROM arex_tnms;
SHOW VARIABLES LIKE 'event_scheduler';

-- 시연 전용 프로시저와 업무용 평가 프로시저 확인
SELECT ROUTINE_NAME, ROUTINE_TYPE, CREATED, LAST_ALTERED
FROM information_schema.ROUTINES
WHERE ROUTINE_SCHEMA = 'arex_tnms'
ORDER BY ROUTINE_TYPE, ROUTINE_NAME;

-- 보존해야 하는 원천 트리거 목록
SELECT TRIGGER_NAME, EVENT_OBJECT_TABLE, ACTION_TIMING, EVENT_MANIPULATION
FROM information_schema.TRIGGERS
WHERE TRIGGER_SCHEMA='arex_tnms'
ORDER BY TRIGGER_NAME;

-- 시연만을 위한 3개 테이블 존재 여부 및 기본 데이터 확인
SELECT TABLE_NAME, TABLE_ROWS
FROM information_schema.TABLES
WHERE TABLE_SCHEMA='arex_tnms'
AND TABLE_NAME IN ('web_tnms_demo_device','web_tnms_demo_excn_ids','web_tnms_demo_run_config');

-- 기존 웹 장비/장애에서 시연 데이터로 확인되는 수량
SELECT COUNT(*) AS demo_equipment_count
FROM web_eqpmnt_info WHERE RGTR_ID='TNMS_DEMO';
SELECT LEFT(DSBLTY_NO,5) AS fault_no_prefix, COUNT(*) AS cnt
FROM web_dsblty_info WHERE DSBLTY_NO LIKE 'PERF-%'
GROUP BY LEFT(DSBLTY_NO,5);

-- 공유 공통코드 정책에서 제외하기로 한 4개 그룹. 존재 여부만 확인
SELECT COM_CD_GROUP_ID, COM_CD_GROUP_NM
FROM com_cd_group_info
WHERE COM_CD_GROUP_ID IN ('CD_PING','CD_CHKM','CD_EVTY','CD_RECV');

-- 제거 후보 (자동 실행하지 않습니다)
-- EVENT: ev_tnms_demo_gateway_5m, ev_tnms_ui_test_refresh_5m
-- PROCEDURE: sp_tnms_demo_seed / demo_tick / demo_history / demo_refresh_stats / demo_prune
-- PROCEDURE: sp_tnms_facility_demo_safe, sp_tnms_ui_test_refresh
-- TABLE: web_tnms_demo_device, web_tnms_demo_excn_ids, web_tnms_demo_run_config
-- [별도 검토 필수] ev_tnms_eval_performance_threshold,
--                  sp_tnms_eval_performance_threshold (기존 web_eqpmnt_perf_stts 기반)
-- [유지] 4개 raw_* -> com_* 원천 트리거 및 모든 raw_* / com_device_* 테이블
