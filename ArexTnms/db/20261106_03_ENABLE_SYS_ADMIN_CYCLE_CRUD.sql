-- 수집주기관리(기존 cycle 메뉴)의 SYS_ADMIN 등록/상세/삭제 권한 활성화
-- web_authrt_menu_rel 기존 1개 권한 행만 변경하며 그 외 web/com/raw 데이터는 변경하지 않습니다.
-- 타 역할에 허용하려면 권한 관리 메뉴에서 해당 권한에 등록/상세/수정/삭제를 설정하세요.
USE arex_tnms;
UPDATE web_authrt_menu_rel
   SET REG_AUTHRT_YN='Y', DTL_AUTHRT_YN='Y', MDFCN_AUTHRT_YN='Y', DEL_AUTHRT_YN='Y'
 WHERE AUTHRT_CD='SYS_ADMIN'
   AND MENU_SN IN (SELECT MENU_SN FROM web_menu_info WHERE MENU_URL_ADDR LIKE '/performance/cycle.do%');

SELECT R.AUTHRT_CD, R.MENU_SN, R.REG_AUTHRT_YN, R.DTL_AUTHRT_YN, R.MDFCN_AUTHRT_YN, R.DEL_AUTHRT_YN
  FROM web_authrt_menu_rel R
  JOIN web_menu_info M ON M.MENU_SN=R.MENU_SN
 WHERE R.AUTHRT_CD='SYS_ADMIN' AND M.MENU_URL_ADDR LIKE '/performance/cycle.do%';
