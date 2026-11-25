-- Re-enable existing web-only management pages. Does not change com/raw.
USE arex_tnms;
UPDATE web_menu_info SET MENU_USE_YN='Y'
WHERE MENU_URL_ADDR LIKE '/performance/threshold.do%' OR MENU_URL_ADDR LIKE '/fault/exceptions.do%';
-- Grant nothing automatically: existing role-specific privileges are retained.
SELECT MENU_SN,MENU_NM,MENU_USE_YN,MENU_URL_ADDR FROM web_menu_info
WHERE MENU_URL_ADDR LIKE '/performance/threshold.do%' OR MENU_URL_ADDR LIKE '/fault/exceptions.do%';
