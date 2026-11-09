-- TNMS 2026-11-04 / 개발·검수 준비 / 수동 실행 전용
-- 중요: 실제 게이트웨이 수집 테이블 raw_* / com_* 및 모든 트리거는 변경하지 않습니다.
-- 전체 백업 확보 + 최신 소스 적용/보고서 확인 후 이 파일을 별도로 실행합니다.
-- HeidiSQL에서 하나의 트랜잭션으로 되돌릴 수 없습니다. DDL은 자동 COMMIT 됩니다.
USE arex_tnms;

-- 1) 시연용 스케줄러가 재실행되는 일부터 차단
DROP EVENT IF EXISTS ev_tnms_demo_gateway_5m;
DROP EVENT IF EXISTS ev_tnms_ui_test_refresh_5m;

-- 2) 기존 웹 시연용 성능 임계치 평가 이벤트는 아직 새 com_device_usage 기반으로
--    전환되지 않았으므로 삭제 대신 비활성화합니다. 해당 업무용 프로시저는 유지합니다.
--    event_scheduler 전역 OFF 상태와 별도 설정입니다.
ALTER EVENT ev_tnms_eval_performance_threshold DISABLE;

-- 3) demo 전용 프로시저 7개 제거 (업무용 sp_tnms_eval_performance_threshold 제외)
DROP PROCEDURE IF EXISTS sp_tnms_demo_seed;
DROP PROCEDURE IF EXISTS sp_tnms_demo_tick;
DROP PROCEDURE IF EXISTS sp_tnms_demo_history;
DROP PROCEDURE IF EXISTS sp_tnms_demo_refresh_stats;
DROP PROCEDURE IF EXISTS sp_tnms_demo_prune;
DROP PROCEDURE IF EXISTS sp_tnms_facility_demo_safe;
DROP PROCEDURE IF EXISTS sp_tnms_ui_test_refresh;

-- 4) 시연 전용 메타 테이블 3개만 제거 (웹 실장비/이력 원본은 유지)
DROP TABLE IF EXISTS web_tnms_demo_device;
DROP TABLE IF EXISTS web_tnms_demo_excn_ids;
DROP TABLE IF EXISTS web_tnms_demo_run_config;

-- 5) 검증: 시스템 업무 이벤트는 비활성화 상태로 남아야 합니다.
SELECT EVENT_NAME, STATUS
FROM information_schema.EVENTS WHERE EVENT_SCHEMA='arex_tnms';
SELECT ROUTINE_NAME, ROUTINE_TYPE
FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA='arex_tnms'
ORDER BY ROUTINE_NAME;
SELECT TRIGGER_NAME, EVENT_OBJECT_TABLE
FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA='arex_tnms'
ORDER BY TRIGGER_NAME;

-- 삭제하지 않는 테이블: web_dsblty_info/web_eqpmnt_info/web_perf_raw_data 등
-- 미전환 화면(예외/조치/수집주기/임계치/알림)에서 아직 참조할 수 있으므로 보존합니다.
-- 과거 시연성 장애 데이터 web_dsblty_info.PERF-* 역시 자동삭제하지 않습니다.
