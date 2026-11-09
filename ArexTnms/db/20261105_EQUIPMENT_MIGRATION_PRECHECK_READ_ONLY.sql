-- 2026-11-05 backup based, safe inspection. No DML/DDL.
USE arex_tnms;
SELECT TABLE_NAME, COLUMN_NAME, CONSTRAINT_NAME
FROM information_schema.KEY_COLUMN_USAGE
WHERE REFERENCED_TABLE_SCHEMA='arex_tnms' AND REFERENCED_TABLE_NAME='web_eqpmnt_info'
ORDER BY TABLE_NAME, CONSTRAINT_NAME;
SELECT COUNT(*) AS gateway_device_count FROM com_device_info;
SELECT COUNT(*) AS legacy_device_count FROM web_eqpmnt_info;
SELECT COUNT(*) AS exception_group_members_legacy FROM web_dsblty_excp_group_eqpmnt_rel;
SELECT COUNT(*) AS exception_group_member_indicators_legacy FROM web_dsblty_excp_group_eqpmnt_idct_rel;
SELECT COUNT(*) AS gateway_ref_count FROM information_schema.TABLES WHERE TABLE_SCHEMA='arex_tnms' AND TABLE_NAME='web_gateway_device_ref';
SELECT ROUTINE_TYPE, ROUTINE_NAME FROM information_schema.ROUTINES
 WHERE ROUTINE_SCHEMA='arex_tnms' AND ROUTINE_DEFINITION LIKE '%web_eqpmnt_info%';
SELECT TABLE_NAME, VIEW_DEFINITION FROM information_schema.VIEWS
 WHERE TABLE_SCHEMA='arex_tnms' AND VIEW_DEFINITION LIKE '%web_eqpmnt_info%';
