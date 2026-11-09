-- TNMS 2026-11-06 사후 검증 (SELECT 전용)
SELECT DATABASE() AS target_schema, NOW() AS inspected_at;
SELECT TABLE_NAME FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE()
  AND TABLE_NAME IN ('web_cctv_info','web_cctv_info_bak_260923','web_clct_cycle_info','web_clct_excn_hstry','web_dsblty_actn_hstry','web_dsblty_excp_group_eqpmnt_idct_rel','web_dsblty_excp_group_eqpmnt_rel','web_dsblty_excp_group_info','web_dsblty_excp_schdl_grd_rel','web_dsblty_excp_schdl_info','web_dsblty_exprs_info','web_dsblty_info','web_dsblty_type_info','web_ems_info','web_enex_evnt_hstry','web_eqpmnt_clsf_info','web_eqpmnt_cntn_acnt_info','web_eqpmnt_info','web_eqpmnt_lnk_rel','web_eqpmnt_mtbf_info','web_eqpmnt_perf_stts','web_eqpmnt_qty_stts','web_eqpmnt_stng_hstry','web_eqpmnt_stts','web_eqpmnt_sync_hstry','web_link_raw_data','web_pbx_info','web_perf_day_stats','web_perf_hr_stats','web_perf_idct_info','web_perf_raw_data','web_perf_thrshld_eval_stts','web_pids_eqpmnt_lse_rel','web_sms_trsm_hstry','web_srvr_log_link_info','web_sys_health_stts','web_thrshld_info','web_tnms_demo_device','web_tnms_demo_excn_ids','web_tnms_demo_run_config','web_gateway_device_ref') ORDER BY TABLE_NAME;
SELECT EVENT_NAME FROM information_schema.EVENTS WHERE EVENT_SCHEMA=DATABASE();
SELECT ROUTINE_NAME,ROUTINE_TYPE FROM information_schema.ROUTINES WHERE ROUTINE_SCHEMA=DATABASE();
SELECT TRIGGER_NAME,EVENT_OBJECT_TABLE FROM information_schema.TRIGGERS WHERE TRIGGER_SCHEMA=DATABASE();
SELECT COUNT(*) AS gateway_devices FROM com_device_info;
SELECT COUNT(*) AS latest_performance_rows FROM com_device_usage;
SELECT COUNT(*) AS ping_source_rows FROM raw_ping_log;
SELECT COUNT(*) AS usage_source_rows FROM raw_usage_log;
SELECT COUNT(*) AS fault_source_rows FROM raw_event_log;
SELECT COUNT(*) AS current_fault_rows FROM raw_event_action WHERE event_yn=1 AND event_grade IN ('1','2','3','4','5');
SELECT COUNT(*) AS gateway_view_rows FROM vw_tnms_gateway_device_live;
SELECT MENU_NM,MENU_USE_YN FROM web_menu_info WHERE MENU_URL_ADDR IN
 ('/performance/threshold.do?screen=threshold','/fault/exceptions.do?screen=exceptions');
