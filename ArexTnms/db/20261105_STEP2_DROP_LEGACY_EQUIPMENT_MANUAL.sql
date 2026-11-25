-- STEP 2 / DESTRUCTIVE. Apply only AFTER new code is deployed & tested with STEP 1.
-- Requires web_gateway_device_ref already created by STEP 1.
-- DDL auto commits; DO NOT execute this on active production without fresh backup.
USE arex_tnms;

-- 2. Old exception-group members are tied to old web equipment; discard them before changing FK.
-- Existing exception group/schedule definitions remain, but memberships must be selected again from gateway devices.
DELETE FROM web_dsblty_excp_group_eqpmnt_idct_rel;
DELETE FROM web_dsblty_excp_group_eqpmnt_rel;
ALTER TABLE web_dsblty_excp_group_eqpmnt_rel
  DROP FOREIGN KEY FK_EXCP_EQPMNT_EQPMNT;
ALTER TABLE web_dsblty_excp_group_eqpmnt_rel
  ADD CONSTRAINT FK_EXCP_GW_DEVICE_REF FOREIGN KEY (EQPMNT_SN)
  REFERENCES web_gateway_device_ref(EQPMNT_SN);

-- 3. All obsolete web demo events and procedures are discarded (none are gateway-owned).
DROP EVENT IF EXISTS ev_tnms_demo_gateway_5m;
DROP EVENT IF EXISTS ev_tnms_ui_test_refresh_5m;
DROP PROCEDURE IF EXISTS sp_tnms_demo_seed;
DROP PROCEDURE IF EXISTS sp_tnms_demo_tick;
DROP PROCEDURE IF EXISTS sp_tnms_demo_history;
DROP PROCEDURE IF EXISTS sp_tnms_demo_refresh_stats;
DROP PROCEDURE IF EXISTS sp_tnms_demo_prune;
DROP PROCEDURE IF EXISTS sp_tnms_facility_demo_safe;
DROP PROCEDURE IF EXISTS sp_tnms_ui_test_refresh;

-- 4. Stop deprecated local threshold job before dropping its legacy current-performance inputs.
-- global event_scheduler can stay OFF; the specific event is explicitly dropped.
DROP EVENT IF EXISTS ev_tnms_eval_performance_threshold;
DROP PROCEDURE IF EXISTS sp_tnms_eval_performance_threshold;
DROP FUNCTION IF EXISTS fn_tnms_eqpmnt_main_status;

-- 5. Old UI report/status views that directly refer to the old web equipment master.
-- NOTE: the active live view vw_tnms_gateway_device_live is NOT touched.
DROP VIEW IF EXISTS vw_eqpmnt_main_stts;
DROP VIEW IF EXISTS vw_dashboard_sys_stts;
DROP VIEW IF EXISTS vw_gateway_collection_setting;
ALTER TABLE `web_cctv_info` DROP FOREIGN KEY `FK_CCTV_EQPMNT`;
ALTER TABLE `web_dsblty_info` DROP FOREIGN KEY `FK_DSBLTY_EQPMNT`;
ALTER TABLE `web_enex_evnt_hstry` DROP FOREIGN KEY `FK_ENEX_EVNT_EQPMNT`;
ALTER TABLE `web_eqpmnt_cntn_acnt_info` DROP FOREIGN KEY `FK_EQPMNT_CNTN_ACNT`;
ALTER TABLE `web_eqpmnt_lnk_rel` DROP FOREIGN KEY `FK_EQPMNT_LNK_REL_FROM`;
ALTER TABLE `web_eqpmnt_lnk_rel` DROP FOREIGN KEY `FK_EQPMNT_LNK_REL_TO`;
ALTER TABLE `web_eqpmnt_perf_stts` DROP FOREIGN KEY `FK_PERF_CURR_EQPMNT`;
ALTER TABLE `web_eqpmnt_stng_hstry` DROP FOREIGN KEY `FK_EQPMNT_STNG_EQPMNT`;
ALTER TABLE `web_eqpmnt_stts` DROP FOREIGN KEY `FK_EQPMNT_STTS_EQPMNT`;
ALTER TABLE `web_pbx_info` DROP FOREIGN KEY `FK_PBX_EQPMNT`;
ALTER TABLE `web_perf_day_stats` DROP FOREIGN KEY `FK_PERF_DAY_EQPMNT`;
ALTER TABLE `web_perf_hr_stats` DROP FOREIGN KEY `FK_PERF_HR_EQPMNT`;
ALTER TABLE `web_perf_thrshld_eval_stts` DROP FOREIGN KEY `FK_PERF_THR_EQ`;
ALTER TABLE `web_pids_eqpmnt_lse_rel` DROP FOREIGN KEY `FK_PIDS_LSE_REL_EQPMNT`;
ALTER TABLE `web_pids_eqpmnt_lse_rel` DROP FOREIGN KEY `FK_PIDS_LSE_REL_LSE`;
ALTER TABLE `web_srvr_log_link_info` DROP FOREIGN KEY `FK_SRVR_LOG_EQPMNT`;
ALTER TABLE `web_tnms_demo_device` DROP FOREIGN KEY `FK_TNMS_DEMO_DEVICE`;

-- 6. Remove OLD equipment master only after all inbound foreign keys are dropped.
DROP TABLE web_eqpmnt_info;

-- 7. Explicitly replaced/obsolete WEB tables. Only objects with no live mapper references were selected.
-- Other web tables (fault action history, exception schedules, auth, color config etc.) remain untouched.
DROP TABLE IF EXISTS `web_cctv_info`;
DROP TABLE IF EXISTS `web_pbx_info`;
DROP TABLE IF EXISTS `web_eqpmnt_stts`;
DROP TABLE IF EXISTS `web_eqpmnt_perf_stts`;
DROP TABLE IF EXISTS `web_eqpmnt_cntn_acnt_info`;
DROP TABLE IF EXISTS `web_eqpmnt_lnk_rel`;
DROP TABLE IF EXISTS `web_pids_eqpmnt_lse_rel`;
DROP TABLE IF EXISTS `web_perf_raw_data`;
DROP TABLE IF EXISTS `web_perf_hr_stats`;
DROP TABLE IF EXISTS `web_perf_day_stats`;
DROP TABLE IF EXISTS `web_perf_thrshld_eval_stts`;
DROP TABLE IF EXISTS `web_tnms_demo_device`;
DROP TABLE IF EXISTS `web_tnms_demo_excn_ids`;
DROP TABLE IF EXISTS `web_tnms_demo_run_config`;
DROP TABLE IF EXISTS `web_eqpmnt_stng_hstry`;
DROP TABLE IF EXISTS `web_eqpmnt_sync_hstry`;
DROP TABLE IF EXISTS `web_enex_evnt_hstry`;
DROP TABLE IF EXISTS `web_srvr_log_link_info`;

-- 8. Read-only end check: current COM rows must remain untouched.
SELECT COUNT(*) AS com_device_count FROM com_device_info;
SELECT COUNT(*) AS web_gateway_device_ref_count FROM web_gateway_device_ref;
SELECT COUNT(*) AS exception_members_remaining FROM web_dsblty_excp_group_eqpmnt_rel;
SELECT COUNT(*) AS old_master_exists FROM information_schema.TABLES WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='web_eqpmnt_info';
