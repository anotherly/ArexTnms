/* 기존 AREX_TNMS DB의 SPA형 메뉴 URL을 분리된 화면 URL로 전환합니다. */
USE `arex_tnms`;

UPDATE menu_info SET MENU_NM='통합 대시보드', MENU_URL_ADDR='/main/dashboard.do?screen=dashboard' WHERE MENU_SN=1;
UPDATE menu_info SET MENU_NM='전송설비', MENU_URL_ADDR='/facility/transmission.do?screen=systems', MENU_EXPLN='전송설비 관리' WHERE MENU_SN=3;
UPDATE menu_info SET MENU_NM='행선안내설비', MENU_URL_ADDR='/facility/pids.do?screen=equipment', MENU_EXPLN='행선안내설비 관리' WHERE MENU_SN=4;
UPDATE menu_info SET MENU_NM='전화교환설비', MENU_URL_ADDR='/facility/pbx.do?screen=switch', MENU_EXPLN='전화교환설비 관리' WHERE MENU_SN=5;
UPDATE menu_info SET MENU_NM='영상감시설비(CCTV)', MENU_URL_ADDR='/facility/cctv.do?screen=cctv', MENU_EXPLN='영상감시설비 관리' WHERE MENU_SN=6;
UPDATE menu_info SET MENU_NM='SCADA 출입보안설비', MENU_URL_ADDR='/facility/scada.do?screen=scada', MENU_EXPLN='SCADA 출입보안설비 관리' WHERE MENU_SN=8;
UPDATE menu_info SET MENU_URL_ADDR='/performance/cycle.do?screen=cycle' WHERE MENU_SN=9;
UPDATE menu_info SET MENU_URL_ADDR='/performance/threshold.do?screen=threshold' WHERE MENU_SN=10;
UPDATE menu_info SET MENU_URL_ADDR='/performance/overview.do?screen=performance' WHERE MENU_SN=11;
UPDATE menu_info SET MENU_URL_ADDR='/performance/raw.do?screen=raw' WHERE MENU_SN=12;
UPDATE menu_info SET MENU_URL_ADDR='/fault/realtime.do?screen=faults' WHERE MENU_SN=13;
UPDATE menu_info SET MENU_URL_ADDR='/fault/history.do?screen=faultHistory' WHERE MENU_SN=14;
UPDATE menu_info SET MENU_URL_ADDR='/fault/exceptions.do?screen=exceptions' WHERE MENU_SN=15;
UPDATE menu_info SET MENU_URL_ADDR='/fault/types.do?screen=faultTypes' WHERE MENU_SN=16;
UPDATE menu_info SET MENU_URL_ADDR='/report/fault-performance.do?screen=reports' WHERE MENU_SN=17;
UPDATE menu_info SET MENU_URL_ADDR='/user/list.do?screen=users' WHERE MENU_SN=18;
UPDATE menu_info SET MENU_URL_ADDR='/auth/list.do?screen=auth' WHERE MENU_SN=19;
UPDATE menu_info SET MENU_URL_ADDR='/user/applications.do?screen=applications' WHERE MENU_SN=20;
UPDATE menu_info SET MENU_URL_ADDR='/setting/common-ui.do?screen=settings' WHERE MENU_SN=22;
UPDATE menu_info SET MENU_URL_ADDR='/audit/job-log.do?screen=logs' WHERE MENU_SN=23;
