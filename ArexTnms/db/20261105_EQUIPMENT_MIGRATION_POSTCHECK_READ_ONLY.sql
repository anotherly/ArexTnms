-- After apply: read-only gateway+web checks.
USE arex_tnms;
SELECT COUNT(*) AS web_master_should_be_zero FROM information_schema.TABLES
 WHERE TABLE_SCHEMA=DATABASE() AND TABLE_NAME='web_eqpmnt_info';
SELECT COUNT(*) AS new_ref_count,COUNT(DISTINCT EMS_ID,DEVICE_ID) AS distinct_gateway_keys
 FROM web_gateway_device_ref;
SELECT COUNT(*) AS gateway_count FROM com_device_info;
SELECT R.EQPMNT_SN,R.EMS_ID,R.DEVICE_ID,D.device_nm,D.use_yn
 FROM web_gateway_device_ref R JOIN com_device_info D ON D.ems_id=R.EMS_ID AND D.device_id=R.DEVICE_ID
 WHERE R.EMS_ID IN (1,13) LIMIT 20;
SELECT COUNT(*) AS stale_orphan_ref FROM web_gateway_device_ref R
 LEFT JOIN com_device_info D ON D.ems_id=R.EMS_ID AND D.device_id=R.DEVICE_ID
 WHERE D.device_id IS NULL;
SELECT TABLE_NAME,CONSTRAINT_NAME FROM information_schema.KEY_COLUMN_USAGE
 WHERE TABLE_SCHEMA=DATABASE() AND REFERENCED_TABLE_NAME='web_eqpmnt_info';
SELECT COUNT(*) AS live_device_view_rows FROM vw_tnms_gateway_device_live;
SELECT ems_id,COUNT(*) AS count_devices FROM com_device_info GROUP BY ems_id;
