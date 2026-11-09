-- STEP 1 / SAFE. Run BEFORE deploying new Java/MyBatis sources.
-- Creates web-only bridge table; no deletes, no COM/RAW changes.
USE arex_tnms;
-- 1. New web-only mapping of runtime device keys: 1 row per (ems_id, device_id).
-- Deliberately start at 1,000,000,000 to avoid mixing historic web equipment serials (<=~2533).
CREATE TABLE web_gateway_device_ref (
  EQPMNT_SN BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '웹 예외 그룹 장비 참조키. com 원천장비가 아님',
  EMS_ID INT NOT NULL COMMENT 'com_device_info.ems_id',
  DEVICE_ID VARCHAR(50) NOT NULL COMMENT 'com_device_info.device_id',
  REG_DT DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (EQPMNT_SN),
  UNIQUE KEY UK_WEB_GW_DEVICE_KEY (EMS_ID, DEVICE_ID)
) ENGINE=InnoDB AUTO_INCREMENT=1000000000 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='웹 전용 게이트웨이 장비 참조(공통 원천장비는 변경 금지)';

INSERT IGNORE INTO web_gateway_device_ref(EMS_ID, DEVICE_ID)
SELECT ems_id,device_id FROM com_device_info WHERE ems_id IN (1,4,11,13,16);

