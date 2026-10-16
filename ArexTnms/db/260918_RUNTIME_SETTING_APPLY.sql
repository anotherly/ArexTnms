/* TNMS 운영·UI 설정 실제 동작 반영용 마이그레이션 (MariaDB 10.6) */
ALTER TABLE user_info
  ADD COLUMN IF NOT EXISTS PSWD_CHG_DT DATETIME NULL COMMENT '비밀번호최종변경일시' AFTER PSWD_EXPRY_YMD;

UPDATE user_info
   SET PSWD_CHG_DT = COALESCE(
       CASE WHEN PSWD_EXPRY_YMD IS NOT NULL THEN DATE_SUB(CAST(PSWD_EXPRY_YMD AS DATETIME), INTERVAL 90 DAY) END,
       REG_DT, NOW())
 WHERE PSWD_CHG_DT IS NULL;

UPDATE user_info
   SET PSWD_EXPRY_YMD = DATE(TIMESTAMPADD(
       MONTH,
       CAST((SELECT UI_STNG_VL FROM ui_stng_info WHERE UI_STNG_CD='PSWD_CHG_NOTICE_DAY' AND USE_YN='Y') AS UNSIGNED),
       PSWD_CHG_DT));

DELETE R
  FROM authrt_menu_rel R
  JOIN menu_info M ON M.MENU_SN = R.MENU_SN
 WHERE SUBSTRING_INDEX(M.MENU_URL_ADDR, 'screen=', -1) = 'dashboard';

/* 현재 화면에 실제 존재하지 않는 기능권한 정리 */
UPDATE authrt_menu_rel R
JOIN menu_info M ON M.MENU_SN = R.MENU_SN
SET R.CTRL_AUTHRT_YN = 'N',
    R.DTL_AUTHRT_YN = CASE
        WHEN SUBSTRING_INDEX(M.MENU_URL_ADDR, 'screen=', -1) IN ('systems','equipment','scada','switch','cctv','users','auth','logs') THEN R.DTL_AUTHRT_YN
        ELSE 'N' END,
    R.REG_AUTHRT_YN = CASE
        WHEN SUBSTRING_INDEX(M.MENU_URL_ADDR, 'screen=', -1) IN ('systems','equipment','scada','switch','cctv','users','auth','settings') THEN R.REG_AUTHRT_YN
        ELSE 'N' END,
    R.MDFCN_AUTHRT_YN = CASE
        WHEN SUBSTRING_INDEX(M.MENU_URL_ADDR, 'screen=', -1) IN ('systems','equipment','scada','switch','cctv','users','auth','settings') THEN R.MDFCN_AUTHRT_YN
        ELSE 'N' END,
    R.DEL_AUTHRT_YN = CASE
        WHEN SUBSTRING_INDEX(M.MENU_URL_ADDR, 'screen=', -1) IN ('systems','equipment','scada','switch','cctv','users','auth') THEN R.DEL_AUTHRT_YN
        ELSE 'N' END;

SELECT UI_STNG_CD, UI_STNG_VL
  FROM ui_stng_info
 WHERE UI_STNG_CD IN ('LIST_ROW_CNT','PSWD_CHG_NOTICE_DAY','DASHBOARD_REFRESH_SEC','DASHBOARD_OFFLINE_MIN')
 ORDER BY UI_STNG_CD;
