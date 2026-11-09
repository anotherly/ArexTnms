-- TNMS 2026-11-06 WEB 장비/성능/장애 더미 객체 제거
-- !!! 파괴적 DDL: 전체 백업 및 소스 재배포 / 사전점검 통과 후 수동 실행 !!!
-- com_* 및 raw_* 테이블/데이터/원천 트리거 4개: 변경 없음.
-- 현재 운영 개발 DB명으로 명시. 다른 DB 실행 금지.
USE `arex_tnms`;
SELECT DATABASE() AS target_schema;

-- STEP 1: 구형 스케줄러. 성능 임계치 자동 장애 생성은 종료됨.
DROP EVENT IF EXISTS `ev_tnms_demo_gateway_5m`;
DROP EVENT IF EXISTS `ev_tnms_eval_performance_threshold`;
DROP EVENT IF EXISTS `ev_tnms_ui_test_refresh_5m`;

-- STEP 2: web 장비 상태/장애 관련 구형 VIEW 삭제. 새 게이트웨이 VIEW는 유지!
DROP VIEW IF EXISTS `vw_active_fault_exception_equipment`;
DROP VIEW IF EXISTS `vw_dashboard_dsblty_summary`;
DROP VIEW IF EXISTS `vw_dashboard_sys_stts`;
DROP VIEW IF EXISTS `vw_eqpmnt_main_stts`;
DROP VIEW IF EXISTS `vw_gateway_collection_setting`;

-- STEP 3: web 시연/임계치/장비 상태 프로시저 및 함수 제거. 게이트웨이 트리거는 절대 삭제하지 않음.
DROP PROCEDURE IF EXISTS `sp_tnms_demo_history`;
DROP PROCEDURE IF EXISTS `sp_tnms_demo_prune`;
DROP PROCEDURE IF EXISTS `sp_tnms_demo_refresh_stats`;
DROP PROCEDURE IF EXISTS `sp_tnms_demo_seed`;
DROP PROCEDURE IF EXISTS `sp_tnms_demo_tick`;
DROP PROCEDURE IF EXISTS `sp_tnms_eval_performance_threshold`;
DROP PROCEDURE IF EXISTS `sp_tnms_facility_demo_safe`;
DROP PROCEDURE IF EXISTS `sp_tnms_ui_test_refresh`;
DROP FUNCTION IF EXISTS `fn_tnms_eqpmnt_main_status`;
DROP FUNCTION IF EXISTS `fn_tnms_grade_to_main_status`;

-- STEP 4: web 관련 FK 자식부터 DROP. FOREIGN_KEY_CHECKS 강제 해제하지 않음.
DROP TABLE IF EXISTS `web_cctv_info`;
DROP TABLE IF EXISTS `web_cctv_info_bak_260923`;
DROP TABLE IF EXISTS `web_dsblty_actn_hstry`;
DROP TABLE IF EXISTS `web_dsblty_excp_group_eqpmnt_idct_rel`;
DROP TABLE IF EXISTS `web_dsblty_excp_schdl_grd_rel`;
DROP TABLE IF EXISTS `web_dsblty_exprs_info`;
DROP TABLE IF EXISTS `web_ems_info`;
DROP TABLE IF EXISTS `web_enex_evnt_hstry`;
DROP TABLE IF EXISTS `web_eqpmnt_cntn_acnt_info`;
DROP TABLE IF EXISTS `web_eqpmnt_lnk_rel`;
DROP TABLE IF EXISTS `web_eqpmnt_mtbf_info`;
DROP TABLE IF EXISTS `web_eqpmnt_perf_stts`;
DROP TABLE IF EXISTS `web_eqpmnt_qty_stts`;
DROP TABLE IF EXISTS `web_eqpmnt_stng_hstry`;
DROP TABLE IF EXISTS `web_eqpmnt_stts`;
DROP TABLE IF EXISTS `web_eqpmnt_sync_hstry`;
DROP TABLE IF EXISTS `web_link_raw_data`;
DROP TABLE IF EXISTS `web_pbx_info`;
DROP TABLE IF EXISTS `web_perf_day_stats`;
DROP TABLE IF EXISTS `web_perf_hr_stats`;
DROP TABLE IF EXISTS `web_perf_raw_data`;
DROP TABLE IF EXISTS `web_perf_thrshld_eval_stts`;
DROP TABLE IF EXISTS `web_pids_eqpmnt_lse_rel`;
DROP TABLE IF EXISTS `web_sms_trsm_hstry`;
DROP TABLE IF EXISTS `web_srvr_log_link_info`;
DROP TABLE IF EXISTS `web_sys_health_stts`;
DROP TABLE IF EXISTS `web_thrshld_info`;
DROP TABLE IF EXISTS `web_tnms_demo_device`;
DROP TABLE IF EXISTS `web_tnms_demo_excn_ids`;
DROP TABLE IF EXISTS `web_tnms_demo_run_config`;
DROP TABLE IF EXISTS `web_clct_excn_hstry`;
DROP TABLE IF EXISTS `web_dsblty_excp_group_eqpmnt_rel`;
DROP TABLE IF EXISTS `web_dsblty_excp_schdl_info`;
DROP TABLE IF EXISTS `web_dsblty_info`;
DROP TABLE IF EXISTS `web_perf_idct_info`;
DROP TABLE IF EXISTS `web_clct_cycle_info`;
DROP TABLE IF EXISTS `web_dsblty_excp_group_info`;
DROP TABLE IF EXISTS `web_dsblty_type_info`;
DROP TABLE IF EXISTS `web_eqpmnt_info`;
DROP TABLE IF EXISTS `web_eqpmnt_clsf_info`;

-- STEP 4-1: 지난번 제안한 불필요한 웹 장비 참조 테이블이 생성돼 있다면 삭제.
-- 원천장비의 PK는 오직 (com_device_info.ems_id,device_id) 사용.
DROP TABLE IF EXISTS `web_gateway_device_ref`;

-- STEP 5: 현재 사용할 수 없는 UI 기능(임계치 편집, 장애 예외)을 메뉴에서 숨김.
-- 다른 메뉴·권한 설정은 보존.
UPDATE web_menu_info SET MENU_USE_YN='N'
 WHERE MENU_URL_ADDR IN ('/performance/threshold.do?screen=threshold','/fault/exceptions.do?screen=exceptions');

-- POSTCHECK: 원천 테이블과 뷰 존속 확인 (데이터는 수정하지 않음)
SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE()
 AND TABLE_NAME IN ('com_device_info','com_device_usage','raw_event_log','raw_event_action','raw_ping_log','raw_usage_log','vw_tnms_gateway_device_live');
SELECT TRIGGER_NAME, EVENT_OBJECT_TABLE FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE();
