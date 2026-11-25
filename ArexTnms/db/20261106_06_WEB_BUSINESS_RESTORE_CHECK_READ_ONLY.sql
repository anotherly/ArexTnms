-- Web-only restoration review. All statements read-only.
USE arex_tnms;
SELECT TABLE_NAME FROM information_schema.TABLES
 WHERE TABLE_SCHEMA='arex_tnms' AND TABLE_NAME IN
 ('web_fault_process_info','web_fault_process_action','web_dsblty_excp_group_info',
 'web_dsblty_excp_group_eqpmnt_rel','web_dsblty_excp_schdl_info',
 'web_dsblty_excp_schdl_grd_rel','web_thrshld_info','web_perf_thrshld_eval_state',
 'web_perf_thrshld_event') ORDER BY TABLE_NAME;
SELECT COUNT(*) AS registered_devices FROM com_device_info;
SELECT COUNT(*) AS gateway_faults FROM raw_event_action WHERE event_yn=1;
SELECT COUNT(*) AS gateway_history FROM raw_event_log;
SELECT COUNT(*) AS thresholds FROM web_thrshld_info;
SELECT COUNT(*) AS web_threshold_events, SUM(EVENT_YN=1) AS web_threshold_open FROM web_perf_thrshld_event;
SELECT COUNT(*) AS web_exception_groups FROM web_dsblty_excp_group_info;
SELECT COUNT(*) AS web_exception_schedules FROM web_dsblty_excp_schdl_info;
SELECT COUNT(*) AS web_workflow_rows FROM web_fault_process_info;
SELECT EVENT_NAME,STATUS,EVENT_DEFINITION FROM information_schema.EVENTS
 WHERE EVENT_SCHEMA='arex_tnms' AND EVENT_NAME='ev_tnms_web_eval_performance_threshold';
SHOW VARIABLES LIKE 'event_scheduler';
SELECT TABLE_NAME,TRIGGER_NAME FROM information_schema.TRIGGERS
 WHERE TRIGGER_SCHEMA='arex_tnms' AND TABLE_NAME IN
 ('raw_ping_log','raw_usage_log','raw_event_log','raw_action_log');
SELECT ems_id,COUNT(*) AS devices FROM com_device_info GROUP BY ems_id ORDER BY ems_id;
