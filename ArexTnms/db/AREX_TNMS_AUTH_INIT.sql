/*
 * AREX TNMS 로그인·사용자·권한 초기 데이터
 * 선행: AREX_TNMS_MariaDB_DDL.sql 실행
 * 초기 관리자: admin / Tnms1234!
 * 최초 로그인 후 반드시 비밀번호를 변경하십시오.
 */
USE `AREX_TNMS`;

INSERT INTO menu_info
(MENU_SN, UP_MENU_SN, MENU_NM, MENU_URL_ADDR, MENU_SEQ, MENU_LV, MENU_EXPLN, MENU_USE_YN)
VALUES
(1,NULL,'통합 대시보드','/main/dashboard.do?screen=dashboard',1,'1','통합 관제 대시보드','Y'),
(2,NULL,'역사·선로 현황','/main/dashboard.do?screen=route',2,'1','역사 및 선로 현황','Y'),
(3,NULL,'연동시스템 관리','/main/dashboard.do?screen=systems',3,'1','연동시스템 관리','Y'),
(4,NULL,'장비 관리','/main/dashboard.do?screen=equipment',4,'1','장비 관리','Y'),
(5,NULL,'교환기 관리','/main/dashboard.do?screen=switch',5,'1','교환기 관리','Y'),
(6,NULL,'CCTV 상태관리','/main/dashboard.do?screen=cctv',6,'1','CCTV 상태관리','Y'),
(7,NULL,'CCTV 영상관리','/main/dashboard.do?screen=video',7,'1','CCTV 영상관리','Y'),
(8,NULL,'SCADA 출입보안','/main/dashboard.do?screen=scada',8,'1','SCADA 출입보안','Y'),
(9,NULL,'연동주기 관리','/main/dashboard.do?screen=cycle',9,'1','연동주기 관리','Y'),
(10,NULL,'임계치 관리','/main/dashboard.do?screen=threshold',10,'1','임계치 관리','Y'),
(11,NULL,'성능관리','/main/dashboard.do?screen=performance',11,'1','성능관리','Y'),
(12,NULL,'Raw 데이터 관리','/main/dashboard.do?screen=raw',12,'1','Raw 데이터 관리','Y'),
(13,NULL,'실시간 장애','/main/dashboard.do?screen=faults',13,'1','실시간 장애','Y'),
(14,NULL,'장애이력·조치','/main/dashboard.do?screen=faultHistory',14,'1','장애이력 및 조치','Y'),
(15,NULL,'장애 예외설정','/main/dashboard.do?screen=exceptions',15,'1','장애 예외설정','Y'),
(16,NULL,'장애유형 관리','/main/dashboard.do?screen=faultTypes',16,'1','장애유형 관리','Y'),
(17,NULL,'장애·성능 보고서','/main/dashboard.do?screen=reports',17,'1','장애 및 성능 보고서','Y'),
(18,NULL,'사용자 계정 설정','/main/dashboard.do?screen=users',18,'1','사용자 계정 설정','Y'),
(19,NULL,'권한 관리','/main/dashboard.do?screen=auth',19,'1','메뉴 및 기능 권한 관리','Y'),
(20,NULL,'계정 신청 현황','/main/dashboard.do?screen=applications',20,'1','계정 신청 현황','Y'),
(21,NULL,'알림·SMS 설정','/main/dashboard.do?screen=notify',21,'1','알림 및 SMS 설정','Y'),
(22,NULL,'공통코드·UI 설정','/main/dashboard.do?screen=settings',22,'1','공통코드 및 UI 설정','Y'),
(23,NULL,'작업로그 조회','/main/dashboard.do?screen=logs',23,'1','사용자 작업로그 조회','Y')
ON DUPLICATE KEY UPDATE MENU_NM=VALUES(MENU_NM), MENU_URL_ADDR=VALUES(MENU_URL_ADDR),
MENU_SEQ=VALUES(MENU_SEQ), MENU_EXPLN=VALUES(MENU_EXPLN), MENU_USE_YN='Y';

INSERT INTO authrt_info
(AUTHRT_SN, AUTHRT_NM, AUTHRT_EXPLN, AUTHRT_STTS_NM, USE_YN)
VALUES
(1,'시스템 관리자','TNMS 전체 기능 및 권한 관리','사용','Y'),
(2,'운영 관리자','운영 기능 관리 및 사용자 조회','사용','Y'),
(3,'운영자','관제·장애·성능 업무 수행','사용','Y'),
(4,'설비 담당자','담당 설비 조회 및 장애 조치','사용','Y'),
(5,'조회 사용자','조회 전용','사용','Y')
ON DUPLICATE KEY UPDATE AUTHRT_NM=VALUES(AUTHRT_NM), AUTHRT_EXPLN=VALUES(AUTHRT_EXPLN),
AUTHRT_STTS_NM='사용', USE_YN='Y';

INSERT INTO authrt_menu_rel
(AUTHRT_SN, MENU_SN, LIST_AUTHRT_YN, DTL_AUTHRT_YN, REG_AUTHRT_YN, MDFCN_AUTHRT_YN, DEL_AUTHRT_YN, CTRL_AUTHRT_YN)
SELECT 1, MENU_SN, 'Y','Y','Y','Y','Y','Y' FROM menu_info WHERE MENU_USE_YN='Y'
ON DUPLICATE KEY UPDATE LIST_AUTHRT_YN='Y', DTL_AUTHRT_YN='Y', REG_AUTHRT_YN='Y',
MDFCN_AUTHRT_YN='Y', DEL_AUTHRT_YN='Y', CTRL_AUTHRT_YN='Y';

INSERT INTO authrt_menu_rel
(AUTHRT_SN, MENU_SN, LIST_AUTHRT_YN, DTL_AUTHRT_YN, REG_AUTHRT_YN, MDFCN_AUTHRT_YN, DEL_AUTHRT_YN, CTRL_AUTHRT_YN)
SELECT 2, MENU_SN, 'Y','Y',
       CASE WHEN MENU_SN IN (1,2,17,20,23) THEN 'N' ELSE 'Y' END,
       CASE WHEN MENU_SN IN (1,2,17,20,23) THEN 'N' ELSE 'Y' END,
       CASE WHEN MENU_SN IN (3,4,9,10,15,16,18,21,22) THEN 'Y' ELSE 'N' END,
       CASE WHEN MENU_SN IN (3,4,5,6,7,8,13,14) THEN 'Y' ELSE 'N' END
FROM menu_info WHERE MENU_USE_YN='Y'
ON DUPLICATE KEY UPDATE LIST_AUTHRT_YN=VALUES(LIST_AUTHRT_YN), DTL_AUTHRT_YN=VALUES(DTL_AUTHRT_YN),
REG_AUTHRT_YN=VALUES(REG_AUTHRT_YN), MDFCN_AUTHRT_YN=VALUES(MDFCN_AUTHRT_YN),
DEL_AUTHRT_YN=VALUES(DEL_AUTHRT_YN), CTRL_AUTHRT_YN=VALUES(CTRL_AUTHRT_YN);

INSERT INTO authrt_menu_rel
(AUTHRT_SN, MENU_SN, LIST_AUTHRT_YN, DTL_AUTHRT_YN, REG_AUTHRT_YN, MDFCN_AUTHRT_YN, DEL_AUTHRT_YN, CTRL_AUTHRT_YN)
SELECT 3, MENU_SN,
       CASE WHEN MENU_SN IN (18,19,20,21,22,23) THEN 'N' ELSE 'Y' END,
       CASE WHEN MENU_SN IN (18,19,20,21,22,23) THEN 'N' ELSE 'Y' END,
       CASE WHEN MENU_SN IN (13,14) THEN 'Y' ELSE 'N' END,
       CASE WHEN MENU_SN IN (13,14) THEN 'Y' ELSE 'N' END,
       'N', CASE WHEN MENU_SN IN (5,6,7,8,13) THEN 'Y' ELSE 'N' END
FROM menu_info WHERE MENU_USE_YN='Y'
ON DUPLICATE KEY UPDATE LIST_AUTHRT_YN=VALUES(LIST_AUTHRT_YN), DTL_AUTHRT_YN=VALUES(DTL_AUTHRT_YN),
REG_AUTHRT_YN=VALUES(REG_AUTHRT_YN), MDFCN_AUTHRT_YN=VALUES(MDFCN_AUTHRT_YN),
DEL_AUTHRT_YN=VALUES(DEL_AUTHRT_YN), CTRL_AUTHRT_YN=VALUES(CTRL_AUTHRT_YN);

INSERT INTO authrt_menu_rel
(AUTHRT_SN, MENU_SN, LIST_AUTHRT_YN, DTL_AUTHRT_YN, REG_AUTHRT_YN, MDFCN_AUTHRT_YN, DEL_AUTHRT_YN, CTRL_AUTHRT_YN)
SELECT 4, MENU_SN,
       CASE WHEN MENU_SN IN (1,2,3,4,5,6,7,8,13,14,17) THEN 'Y' ELSE 'N' END,
       CASE WHEN MENU_SN IN (3,4,5,6,7,8,13,14) THEN 'Y' ELSE 'N' END,
       'N', CASE WHEN MENU_SN IN (13,14) THEN 'Y' ELSE 'N' END, 'N',
       CASE WHEN MENU_SN IN (5,6,7,8,13) THEN 'Y' ELSE 'N' END
FROM menu_info WHERE MENU_USE_YN='Y'
ON DUPLICATE KEY UPDATE LIST_AUTHRT_YN=VALUES(LIST_AUTHRT_YN), DTL_AUTHRT_YN=VALUES(DTL_AUTHRT_YN),
REG_AUTHRT_YN=VALUES(REG_AUTHRT_YN), MDFCN_AUTHRT_YN=VALUES(MDFCN_AUTHRT_YN),
DEL_AUTHRT_YN=VALUES(DEL_AUTHRT_YN), CTRL_AUTHRT_YN=VALUES(CTRL_AUTHRT_YN);

INSERT INTO authrt_menu_rel
(AUTHRT_SN, MENU_SN, LIST_AUTHRT_YN, DTL_AUTHRT_YN, REG_AUTHRT_YN, MDFCN_AUTHRT_YN, DEL_AUTHRT_YN, CTRL_AUTHRT_YN)
SELECT 5, MENU_SN,
       CASE WHEN MENU_SN IN (18,19,20,21,22,23) THEN 'N' ELSE 'Y' END,
       'N','N','N','N','N'
FROM menu_info WHERE MENU_USE_YN='Y'
ON DUPLICATE KEY UPDATE LIST_AUTHRT_YN=VALUES(LIST_AUTHRT_YN), DTL_AUTHRT_YN='N',
REG_AUTHRT_YN='N', MDFCN_AUTHRT_YN='N', DEL_AUTHRT_YN='N', CTRL_AUTHRT_YN='N';

INSERT INTO user_info
(USER_ID, USER_NM, USER_ENPSWD, OGDP_BZENTY_NM, DEPT_NM, USER_STTS_NM,
 PSWD_EXPRY_YMD, LGN_FAIL_NOCS, USE_YN)
VALUES
('admin','시스템관리자','$2a$10$n3UL88OtFJB7L96YiBlwJupIPtRPUIfsNzJehj/ySFzNhEeyupjx6',
 '공항철도','정보통신팀','정상',DATE_ADD(CURDATE(), INTERVAL 90 DAY),0,'Y')
ON DUPLICATE KEY UPDATE USER_NM=VALUES(USER_NM), USER_STTS_NM='정상', USE_YN='Y';

DELETE FROM user_authrt_rel WHERE USER_SN = (SELECT USER_SN FROM user_info WHERE USER_ID='admin');
INSERT INTO user_authrt_rel (USER_SN, AUTHRT_SN, AUTHRT_BGNG_DT, AUTHRT_END_DT)
SELECT USER_SN,1,NOW(),NULL FROM user_info WHERE USER_ID='admin'
ON DUPLICATE KEY UPDATE AUTHRT_BGNG_DT=VALUES(AUTHRT_BGNG_DT), AUTHRT_END_DT=NULL;
