-- 계정 신청 화면에서 승인 전 계정 정보를 보관하기 위한 컬럼입니다.
-- 비밀번호 원문은 저장하지 않고 애플리케이션에서 BCrypt 해시 후 USER_ENPSWD에 저장합니다.
-- MariaDB 10.6 기준. 재실행해도 오류가 나지 않도록 IF NOT EXISTS를 사용합니다.
ALTER TABLE user_acnt_aply_info
    ADD COLUMN IF NOT EXISTS USER_ENPSWD varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '사용자암호화비밀번호' AFTER USER_NM,
    ADD COLUMN IF NOT EXISTS USER_SE_NM varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '사용자구분명(내부/외부)' AFTER USER_ENPSWD,
    ADD COLUMN IF NOT EXISTS MBL_TELNO varchar(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '휴대전화번호' AFTER DEPT_NM;
