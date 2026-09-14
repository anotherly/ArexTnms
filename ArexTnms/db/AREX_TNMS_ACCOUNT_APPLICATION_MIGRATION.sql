/*
 * 계정신청 기능 보강 컬럼 마이그레이션
 * - 비밀번호 원문은 저장하지 않고 애플리케이션에서 BCrypt 해시 후 USER_ENPSWD에 저장.
 * - MariaDB 10.6 기준.
 *
 * 신규/최종 스키마는 AREX_TNMS_MariaDB_DDL.sql을 기준으로 하며,
 * 기존 DB에서 USER_SN/APLY_SN 등 자연키 전환까지 수행할 경우
 * 이 파일 실행 후 AREX_TNMS_NATURAL_KEY_MIGRATION.sql을 이어서 실행하십시오.
 */
USE `arex_tnms`;

ALTER TABLE user_acnt_aply_info
    ADD COLUMN IF NOT EXISTS USER_ENPSWD VARCHAR(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '사용자암호화비밀번호' AFTER USER_NM,
    ADD COLUMN IF NOT EXISTS USER_SE_NM VARCHAR(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '사용자구분명(내부/외부)' AFTER USER_ENPSWD,
    ADD COLUMN IF NOT EXISTS MBL_TELNO VARCHAR(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '휴대전화번호' AFTER DEPT_NM;
