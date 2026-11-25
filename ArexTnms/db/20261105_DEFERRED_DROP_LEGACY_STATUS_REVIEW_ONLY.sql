-- 절대 지금 실행하지 마세요. 레거시 임계치 평가를 com_device_usage 기반으로 교체한 후 검토.
-- 현재 sp_tnms_eval_performance_threshold는 web_eqpmnt_perf_stts 등을 조회함.
-- 해당 기능이 소멸하면 웹의 성능 임계치 관리가 장애를 만들지 못합니다.
-- 다음 DDL은 향후 정리 절차 참고용입니다. 실행하려면 주석 해제 필요.
USE arex_tnms;

-- 1) 새 임계치 평가/장애 처리 로직 검증 후 이벤트·루틴 정리
-- DROP EVENT IF EXISTS ev_tnms_eval_performance_threshold;
-- DROP PROCEDURE IF EXISTS sp_tnms_eval_performance_threshold;
-- DROP VIEW IF EXISTS vw_eqpmnt_main_stts;
-- DROP VIEW IF EXISTS vw_dashboard_sys_stts;
-- DROP FUNCTION IF EXISTS fn_tnms_eqpmnt_main_status;
-- DROP FUNCTION IF EXISTS fn_tnms_grade_to_main_status;
-- DROP TABLE IF EXISTS web_perf_thrshld_eval_stts;
-- DROP TABLE IF EXISTS web_eqpmnt_perf_stts;
-- DROP TABLE IF EXISTS web_eqpmnt_stts;

-- 절대 삭제 금지 (현재 웹 기능, FK/입력부가정보 아직 존재):
-- DROP TABLE web_eqpmnt_info;
-- DROP TABLE web_dsblty_info;
