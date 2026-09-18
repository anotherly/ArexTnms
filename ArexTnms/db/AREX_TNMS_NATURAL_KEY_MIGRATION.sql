/*
 * AREX TNMS natural-key / public-data standard migration
 * 기준 스키마: arex_tnms(2).sql (2026-09-04 제공본)
 * 대상 DB: MariaDB 10.6
 *
 * 핵심 변경
 *  1) 사용자 식별: USER_SN 제거, USER_ID PK/FK 사용 + user_authrt_rel 제거 후 user_info.AUTHRT_SN 단일권한 FK 사용
 *  2) 계정신청: APLY_SN 제거, APLY_NO PK 사용(공통표준 번호V20에 맞춰 20자)
 *  3) 장애: DSBLTY_SN 제거, DSBLTY_NO PK/FK 사용
 *  4) 1:1 상세/중복 PK 제거: CCTV/PBX/PIDS/SCADA/TRSM -> EQPMNT_SN PK
 *  5) 중복 일련번호 제거: PROTCL_MSG_FIELD_SN, SYNC_SCHDL_SN, RPTP_SN
 *  6) 사용자 감사 컬럼: *_SN -> 사용자 ID 계열 컬럼으로 치환
 *  7) 공공데이터 공통표준 용어/약어 보정: HIST->HSTRY, CFG->STNG,
 *     ACSS->ENEX, SUCC_NOCS->SCS_NOCS, REQ_YN->ESNTL_YN
 *
 * 주의
 *  - DDL은 자동 COMMIT됩니다. 실행 전 DB 전체 백업 권장.
 *  - 본 파일은 제공받은 최신 스키마의 제약조건/인덱스명을 기준으로 작성됨.
 *  - 백업 테이블(*_bak_20260814)은 보존 목적으로 자동 삭제/변경하지 않음.
 */

USE `arex_tnms`;

/* --------------------------------------------------------------------------
 * 0. 사전 검증: 변환 중 데이터 유실/키 충돌 가능성이 있으면 즉시 중단
 * -------------------------------------------------------------------------- */
DROP PROCEDURE IF EXISTS sp_tnms_natural_key_precheck;
DELIMITER //
CREATE PROCEDURE sp_tnms_natural_key_precheck()
BEGIN
    /* APLY_NO에서 '-' 제거 후 20자를 초과하면 공통표준 번호V20으로 안전하게 바꿀 수 없음 */
    IF EXISTS (
        SELECT 1
          FROM user_acnt_aply_info
         WHERE CHAR_LENGTH(REPLACE(APLY_NO, '-', '')) > 20
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration aborted: APLY_NO exceeds 20 chars after normalization.';
    END IF;

    /* '-' 제거 후 신청번호가 충돌하면 PK 전환 불가 */
    IF EXISTS (
        SELECT 1
          FROM (
                SELECT REPLACE(APLY_NO, '-', '') AS NEW_APLY_NO, COUNT(*) AS CNT
                  FROM user_acnt_aply_info
                 GROUP BY REPLACE(APLY_NO, '-', '')
                HAVING COUNT(*) > 1
               ) X
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration aborted: duplicated APLY_NO after hyphen removal.';
    END IF;

    /* TNMS는 사용자당 현재 권한 1개 정책. 활성 권한이 둘 이상이면 자동 이관하지 않음 */
    IF EXISTS (
        SELECT 1
          FROM user_authrt_rel
         WHERE AUTHRT_BGNG_DT <= NOW()
           AND (AUTHRT_END_DT IS NULL OR AUTHRT_END_DT > NOW())
         GROUP BY USER_SN
        HAVING COUNT(*) > 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration aborted: a user has multiple active authorities.';
    END IF;

    /* 사용중인 사용자는 현재 유효 권한이 하나 있어야 함 */
    IF EXISTS (
        SELECT 1
          FROM user_info U
          LEFT JOIN user_authrt_rel R
            ON R.USER_SN = U.USER_SN
           AND R.AUTHRT_BGNG_DT <= NOW()
           AND (R.AUTHRT_END_DT IS NULL OR R.AUTHRT_END_DT > NOW())
         WHERE U.USE_YN != 'N'
           AND R.AUTHRT_SN IS NULL
         LIMIT 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration aborted: an active user has no active authority.';
    END IF;

    /* USER_SN을 실제 USER_ID로 바꿀 수 없는 고아 참조가 하나라도 있으면 중단 */
    IF EXISTS (
        SELECT 1 FROM user_authrt_rel R
         LEFT JOIN user_info U ON U.USER_SN = R.USER_SN
        WHERE R.USER_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM sms_group_user_rel R
         LEFT JOIN user_info U ON U.USER_SN = R.USER_SN
        WHERE R.USER_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM authrt_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM authrt_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM bzenty_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM bzenty_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM clct_cycle_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM clct_cycle_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM com_cd_group_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM com_cd_group_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM com_cd_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM com_cd_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM dsblty_excp_group_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM dsblty_excp_group_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM dsblty_excp_schdl_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM dsblty_excp_schdl_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM dsblty_type_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM dsblty_type_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM eqpmnt_cfg_hist T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM eqpmnt_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM eqpmnt_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM link_sys_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM link_sys_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM menu_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM menu_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM sms_group_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM sms_group_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM stn_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM stn_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM thrshld_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM thrshld_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM ui_stng_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM ui_stng_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM user_info T LEFT JOIN user_info U ON U.USER_SN = T.RGTR_SN
        WHERE T.RGTR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM user_info T LEFT JOIN user_info U ON U.USER_SN = T.MDFR_SN
        WHERE T.MDFR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM link_sys_chg_hist T LEFT JOIN user_info U ON U.USER_SN = T.CHGR_SN
        WHERE T.CHGR_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM dsblty_info T LEFT JOIN user_info U ON U.USER_SN = T.IDNTY_USER_SN
        WHERE T.IDNTY_USER_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM dsblty_actn_hist T LEFT JOIN user_info U ON U.USER_SN = T.ACTN_USER_SN
        WHERE T.ACTN_USER_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM rptp_otpt_hist T LEFT JOIN user_info U ON U.USER_SN = T.OTPT_USER_SN
        WHERE T.OTPT_USER_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM user_acnt_aply_info T LEFT JOIN user_info U ON U.USER_SN = T.APRV_USER_SN
        WHERE T.APRV_USER_SN IS NOT NULL AND U.USER_ID IS NULL LIMIT 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration aborted: orphan USER_SN reference exists.';
    END IF;

    /* 장애 자식 참조도 장애번호로 매핑 가능해야 함 */
    IF EXISTS (
        SELECT 1 FROM dsblty_actn_hist A
         LEFT JOIN dsblty_info D ON D.DSBLTY_SN = A.DSBLTY_SN
        WHERE A.DSBLTY_SN IS NOT NULL AND D.DSBLTY_NO IS NULL LIMIT 1
    ) OR EXISTS (
        SELECT 1 FROM sms_trsm_hist S
         LEFT JOIN dsblty_info D ON D.DSBLTY_SN = S.DSBLTY_SN
        WHERE S.DSBLTY_SN IS NOT NULL AND D.DSBLTY_NO IS NULL LIMIT 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration aborted: orphan DSBLTY_SN reference exists.';
    END IF;
END//
DELIMITER ;

CALL sp_tnms_natural_key_precheck();
DROP PROCEDURE sp_tnms_natural_key_precheck;

SET FOREIGN_KEY_CHECKS = 0;

/* 변환용 매핑은 USER_SN / DSBLTY_SN을 제거하기 전에 고정 */
DROP TEMPORARY TABLE IF EXISTS tmp_user_sn_map;
CREATE TEMPORARY TABLE tmp_user_sn_map (
    USER_SN BIGINT UNSIGNED NOT NULL PRIMARY KEY,
    USER_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NOT NULL UNIQUE
) ENGINE=MEMORY;
INSERT INTO tmp_user_sn_map (USER_SN, USER_ID)
SELECT USER_SN, USER_ID FROM user_info;

DROP TEMPORARY TABLE IF EXISTS tmp_dsblty_sn_map;
CREATE TEMPORARY TABLE tmp_dsblty_sn_map (
    DSBLTY_SN BIGINT UNSIGNED NOT NULL PRIMARY KEY,
    DSBLTY_NO VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL UNIQUE
) ENGINE=MEMORY;
INSERT INTO tmp_dsblty_sn_map (DSBLTY_SN, DSBLTY_NO)
SELECT DSBLTY_SN, DSBLTY_NO FROM dsblty_info;

/* --------------------------------------------------------------------------
 * 1. 사용자 감사/처리자 컬럼을 USER_ID 계열로 변환
 * -------------------------------------------------------------------------- */

/* RGTR_SN + MDFR_SN 공통 테이블 */
ALTER TABLE authrt_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                        ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE authrt_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE authrt_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE bzenty_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                        ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE bzenty_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE bzenty_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN,
                        MODIFY COLUMN BZENTY_NM VARCHAR(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '업체명';

ALTER TABLE clct_cycle_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                           ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE clct_cycle_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE clct_cycle_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE com_cd_group_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                             ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE com_cd_group_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE com_cd_group_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE com_cd_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                       ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE com_cd_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE com_cd_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE dsblty_excp_group_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                                  ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE dsblty_excp_group_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE dsblty_excp_group_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE dsblty_excp_schdl_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                                  ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE dsblty_excp_schdl_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE dsblty_excp_schdl_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE dsblty_type_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                            ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE dsblty_type_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE dsblty_type_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE eqpmnt_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                        ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE eqpmnt_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE eqpmnt_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE link_sys_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                          ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE link_sys_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE link_sys_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE menu_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                      ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE menu_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE menu_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE sms_group_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                           ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE sms_group_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE sms_group_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE stn_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                     ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE stn_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE stn_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE thrshld_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                         ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE thrshld_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE thrshld_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

ALTER TABLE ui_stng_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                         ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE ui_stng_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE ui_stng_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

/* user_info 자체의 등록/수정자도 USER_SN이 살아 있을 때 먼저 변환 */
ALTER TABLE user_info ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT,
                      ADD COLUMN MDFR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '수정자아이디' AFTER MDFCN_DT;
UPDATE user_info T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN LEFT JOIN tmp_user_sn_map M ON M.USER_SN=T.MDFR_SN
   SET T.RGTR_ID=R.USER_ID, T.MDFR_ID=M.USER_ID;
ALTER TABLE user_info DROP COLUMN RGTR_SN, DROP COLUMN MDFR_SN;

/* eqpmnt 설정이력(추후 표준명으로 테이블명/컬럼명도 변경) */
ALTER TABLE eqpmnt_cfg_hist ADD COLUMN RGTR_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '등록자아이디' AFTER REG_DT;
UPDATE eqpmnt_cfg_hist T LEFT JOIN tmp_user_sn_map R ON R.USER_SN=T.RGTR_SN SET T.RGTR_ID=R.USER_ID;
ALTER TABLE eqpmnt_cfg_hist DROP COLUMN RGTR_SN;

/* 역할별 사용자 일련번호 -> 역할별 사용자아이디 */
ALTER TABLE link_sys_chg_hist ADD COLUMN CHNRG_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '변경자아이디' AFTER CHG_DT;
UPDATE link_sys_chg_hist T LEFT JOIN tmp_user_sn_map U ON U.USER_SN=T.CHGR_SN SET T.CHNRG_ID=U.USER_ID;
ALTER TABLE link_sys_chg_hist DROP COLUMN CHGR_SN;

ALTER TABLE dsblty_info ADD COLUMN IDNTY_USER_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '확인사용자아이디' AFTER PRCS_STTS_CD;
UPDATE dsblty_info T LEFT JOIN tmp_user_sn_map U ON U.USER_SN=T.IDNTY_USER_SN SET T.IDNTY_USER_ID=U.USER_ID;
ALTER TABLE dsblty_info DROP COLUMN IDNTY_USER_SN;

ALTER TABLE dsblty_actn_hist ADD COLUMN ACTN_USER_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '조치사용자아이디' AFTER ACTN_PIC_NM;
UPDATE dsblty_actn_hist T LEFT JOIN tmp_user_sn_map U ON U.USER_SN=T.ACTN_USER_SN SET T.ACTN_USER_ID=U.USER_ID;
ALTER TABLE dsblty_actn_hist DROP COLUMN ACTN_USER_SN;

ALTER TABLE rptp_otpt_hist ADD COLUMN OTPT_USER_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '출력사용자아이디' AFTER RPTP_WRT_YMD;
UPDATE rptp_otpt_hist T LEFT JOIN tmp_user_sn_map U ON U.USER_SN=T.OTPT_USER_SN SET T.OTPT_USER_ID=U.USER_ID;
ALTER TABLE rptp_otpt_hist DROP COLUMN OTPT_USER_SN;

ALTER TABLE user_acnt_aply_info ADD COLUMN APRV_USER_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '승인사용자아이디' AFTER APLY_STTS_NM;
UPDATE user_acnt_aply_info T LEFT JOIN tmp_user_sn_map U ON U.USER_SN=T.APRV_USER_SN SET T.APRV_USER_ID=U.USER_ID;
ALTER TABLE user_acnt_aply_info DROP COLUMN APRV_USER_SN;

/* --------------------------------------------------------------------------
 * 2. USER_SN 완전 제거 + USER_ID 사용자 PK/FK + 단일 권한을 user_info로 직접 이관
 * -------------------------------------------------------------------------- */
ALTER TABLE user_authrt_rel DROP FOREIGN KEY FK_USER_AUTHRT_USER;
ALTER TABLE sms_group_user_rel DROP FOREIGN KEY FK_SMS_GROUP_USER_USER, DROP INDEX FK_SMS_GROUP_USER_USER;

/* 기존 현재 유효 권한 1개를 user_info에 직접 보관. 삭제 사용자는 NULL 유지. */
ALTER TABLE user_info ADD COLUMN AUTHRT_SN BIGINT(20) UNSIGNED NULL COMMENT '권한일련번호' AFTER USER_ENPSWD;
UPDATE user_info U
LEFT JOIN user_authrt_rel R
  ON R.USER_SN = U.USER_SN
 AND R.AUTHRT_BGNG_DT <= NOW()
 AND (R.AUTHRT_END_DT IS NULL OR R.AUTHRT_END_DT > NOW())
SET U.AUTHRT_SN = CASE WHEN U.USE_YN = 'N' THEN NULL ELSE R.AUTHRT_SN END;

/* 사용자-권한 관계 테이블은 단일권한 정책에서 불필요하므로 제거 */
DROP TABLE user_authrt_rel;

ALTER TABLE sms_group_user_rel ADD COLUMN USER_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NULL COMMENT '사용자아이디' AFTER SMS_GROUP_SN;
UPDATE sms_group_user_rel R JOIN tmp_user_sn_map U ON U.USER_SN=R.USER_SN SET R.USER_ID=U.USER_ID;
ALTER TABLE sms_group_user_rel DROP PRIMARY KEY,
                               DROP COLUMN USER_SN,
                               MODIFY COLUMN USER_ID VARCHAR(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '사용자아이디',
                               ADD PRIMARY KEY (SMS_GROUP_SN, USER_ID);

/* 접속/작업로그는 이미 USER_ID를 보유하므로 중복 USER_SN만 제거 */
ALTER TABLE cntn_log DROP INDEX IX_CNTN_LOG_USER_DT,
                     DROP COLUMN USER_SN,
                     ADD KEY IX_CNTN_LOG_USER_DT (USER_ID, CNTN_BGNG_DT);
ALTER TABLE job_log DROP INDEX IX_JOB_LOG_USER_DT,
                    DROP COLUMN USER_SN,
                    ADD KEY IX_JOB_LOG_USER_DT (USER_ID, LOG_CRT_DT);

/* USER_ID를 실제 PK로 승격하고 권한 FK/활성 사용자 무결성 제약 추가 */
ALTER TABLE user_info DROP PRIMARY KEY,
                      DROP INDEX UK_USER_ID,
                      DROP COLUMN USER_SN,
                      ADD PRIMARY KEY (USER_ID),
                      ADD KEY FK_USER_AUTHRT (AUTHRT_SN),
                      ADD CONSTRAINT FK_USER_AUTHRT FOREIGN KEY (AUTHRT_SN) REFERENCES authrt_info (AUTHRT_SN),
                      ADD CONSTRAINT CK_USER_AUTHRT CHECK (USE_YN = 'N' OR AUTHRT_SN IS NOT NULL);

ALTER TABLE sms_group_user_rel ADD KEY FK_SMS_GROUP_USER_USER (USER_ID),
                               ADD CONSTRAINT FK_SMS_GROUP_USER_USER FOREIGN KEY (USER_ID) REFERENCES user_info (USER_ID);

/* --------------------------------------------------------------------------
 * 3. 계정신청: APLY_SN 제거, APLY_NO PK
 *    기존 APLY-YYYYMMDD-XXXXXXXX -> APLYYYYYMMDDXXXXXXXX(20자)
 * -------------------------------------------------------------------------- */
UPDATE user_acnt_aply_info
   SET APLY_NO = REPLACE(APLY_NO, '-', '')
 WHERE APLY_NO LIKE 'APLY-%';

ALTER TABLE user_acnt_aply_info DROP PRIMARY KEY,
                                 DROP INDEX UK_USER_APLY_NO,
                                 DROP COLUMN APLY_SN,
                                 MODIFY COLUMN APLY_NO VARCHAR(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '신청번호',
                                 ADD PRIMARY KEY (APLY_NO);

/* --------------------------------------------------------------------------
 * 4. 장애: DSBLTY_SN 제거, DSBLTY_NO PK/FK
 * -------------------------------------------------------------------------- */
ALTER TABLE dsblty_actn_hist DROP FOREIGN KEY FK_DSBLTY_ACTN_DSBLTY;
ALTER TABLE sms_trsm_hist DROP FOREIGN KEY FK_SMS_TRSM_DSBLTY, DROP INDEX FK_SMS_TRSM_DSBLTY;

ALTER TABLE dsblty_actn_hist ADD COLUMN DSBLTY_NO VARCHAR(50) COLLATE utf8mb4_unicode_ci NULL COMMENT '장애번호' AFTER ACTN_SN;
UPDATE dsblty_actn_hist A JOIN tmp_dsblty_sn_map D ON D.DSBLTY_SN=A.DSBLTY_SN SET A.DSBLTY_NO=D.DSBLTY_NO;
ALTER TABLE dsblty_actn_hist DROP INDEX IX_DSBLTY_ACTN,
                              DROP COLUMN DSBLTY_SN,
                              MODIFY COLUMN DSBLTY_NO VARCHAR(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장애번호',
                              ADD KEY IX_DSBLTY_ACTN (DSBLTY_NO, ACTN_DT);

ALTER TABLE sms_trsm_hist ADD COLUMN DSBLTY_NO VARCHAR(50) COLLATE utf8mb4_unicode_ci NULL COMMENT '장애번호' AFTER SMS_GROUP_SN;
UPDATE sms_trsm_hist S LEFT JOIN tmp_dsblty_sn_map D ON D.DSBLTY_SN=S.DSBLTY_SN SET S.DSBLTY_NO=D.DSBLTY_NO;
ALTER TABLE sms_trsm_hist DROP COLUMN DSBLTY_SN;

ALTER TABLE dsblty_info DROP PRIMARY KEY,
                        DROP INDEX UK_DSBLTY_NO,
                        DROP COLUMN DSBLTY_SN,
                        ADD PRIMARY KEY (DSBLTY_NO);

ALTER TABLE dsblty_actn_hist ADD CONSTRAINT FK_DSBLTY_ACTN_DSBLTY FOREIGN KEY (DSBLTY_NO) REFERENCES dsblty_info (DSBLTY_NO);
ALTER TABLE sms_trsm_hist ADD KEY FK_SMS_TRSM_DSBLTY (DSBLTY_NO),
                          ADD CONSTRAINT FK_SMS_TRSM_DSBLTY FOREIGN KEY (DSBLTY_NO) REFERENCES dsblty_info (DSBLTY_NO);

/* --------------------------------------------------------------------------
 * 5. 명백한 중복 일련번호 제거
 * -------------------------------------------------------------------------- */
/* 장비 1:1 상세 테이블: 자체 SN은 EQPMNT_SN과 완전히 중복 */
ALTER TABLE cctv_info DROP PRIMARY KEY, DROP INDEX UK_CCTV_EQPMNT, DROP COLUMN CCTV_SN, ADD PRIMARY KEY (EQPMNT_SN);
ALTER TABLE pbx_info  DROP PRIMARY KEY, DROP INDEX UK_PBX_EQPMNT,  DROP COLUMN PBX_SN,  ADD PRIMARY KEY (EQPMNT_SN);
ALTER TABLE pids_info DROP PRIMARY KEY, DROP INDEX UK_PIDS_SN_EQPMNT, DROP COLUMN PIDS_SN, ADD PRIMARY KEY (EQPMNT_SN);
ALTER TABLE scada_info DROP PRIMARY KEY, DROP INDEX UK_SCADA_SN_EQPMNT, DROP COLUMN SCADA_SN, ADD PRIMARY KEY (EQPMNT_SN);
ALTER TABLE trsm_info DROP PRIMARY KEY, DROP INDEX UK_TRSM_SN_EQPMNT, DROP COLUMN TRSM_SN, ADD PRIMARY KEY (EQPMNT_SN);

/* 메시지필드는 메시지유형+순서가 이미 유일 */
ALTER TABLE protcl_msg_field_info DROP PRIMARY KEY,
                                  DROP INDEX UK_PROTCL_MSG_FIELD,
                                  DROP COLUMN PROTCL_MSG_FIELD_SN,
                                  ADD PRIMARY KEY (PROTCL_MSG_TYPE_SN, FIELD_SEQ);

/* 동기화일정은 연계시스템+방향이 이미 유일 */
ALTER TABLE sync_schdl_info DROP PRIMARY KEY,
                            DROP INDEX UK_SYNC_SCHDL,
                            DROP COLUMN SYNC_SCHDL_SN,
                            ADD PRIMARY KEY (LINK_SYS_SN, SYNC_DRCT_NM);

/* 보고서번호가 이미 고정 유일 식별번호 */
ALTER TABLE rptp_otpt_hist DROP PRIMARY KEY,
                           DROP INDEX UK_RPTP_NO,
                           DROP COLUMN RPTP_SN,
                           ADD PRIMARY KEY (RPTP_NO);

/* --------------------------------------------------------------------------
 * 6. 공공데이터 공통표준 용어/약어 보정
 * -------------------------------------------------------------------------- */
/* 필수여부: 공통표준 ESNTL_YN */
ALTER TABLE protcl_msg_field_info CHANGE COLUMN REQ_YN ESNTL_YN CHAR(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '필수여부';

/* 설정: 공통표준 단어 약어 STNG 사용(CFG 비표준 약어 제거) */
ALTER TABLE sync_schdl_info CHANGE COLUMN CFG_FILE_APLY_YN STNG_FILE_APLY_YN CHAR(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '설정파일적용여부';
ALTER TABLE eqpmnt_cfg_hist
    CHANGE COLUMN EQPMNT_CFG_HIST_SN EQPMNT_STNG_HSTRY_SN BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '장비설정이력일련번호',
    CHANGE COLUMN CFG_VER_NO STNG_VER_NO VARCHAR(50) COLLATE utf8mb4_unicode_ci NULL COMMENT '설정버전번호',
    CHANGE COLUMN CFG_FILE_NM STNG_FILE_NM VARCHAR(300) COLLATE utf8mb4_unicode_ci NULL COMMENT '설정파일명',
    CHANGE COLUMN CFG_FILE_PATH_NM STNG_FILE_PATH_NM VARCHAR(300) COLLATE utf8mb4_unicode_ci NULL COMMENT '설정파일경로명',
    RENAME INDEX IX_EQPMNT_CFG_HIST TO IX_EQPMNT_STNG_HSTRY;
ALTER TABLE eqpmnt_cfg_hist DROP FOREIGN KEY FK_EQPMNT_CFG_EQPMNT;
ALTER TABLE eqpmnt_cfg_hist ADD CONSTRAINT FK_EQPMNT_STNG_EQPMNT FOREIGN KEY (EQPMNT_SN) REFERENCES eqpmnt_info (EQPMNT_SN);

/* 출입: 공통표준 ENEX 사용(ACSS는 '접근' 의미로 오해될 수 있음) */
ALTER TABLE acss_evnt_hist
    CHANGE COLUMN ACSS_EVNT_SN ENEX_EVNT_SN BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '출입이벤트일련번호',
    CHANGE COLUMN ACSS_DT ENEX_DT DATETIME NOT NULL COMMENT '출입일시',
    CHANGE COLUMN ACSS_RSLT_CD ENEX_RSLT_CD VARCHAR(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '출입결과코드',
    RENAME INDEX IX_ACSS_EVNT_DT TO IX_ENEX_EVNT_DT;
ALTER TABLE acss_evnt_hist DROP FOREIGN KEY FK_ACSS_EVNT_EQPMNT;
ALTER TABLE acss_evnt_hist ADD CONSTRAINT FK_ENEX_EVNT_EQPMNT FOREIGN KEY (EQPMNT_SN) REFERENCES eqpmnt_info (EQPMNT_SN);

/* 성공건수: 공통표준 SCS_NOCS */
ALTER TABLE clct_excn_hist CHANGE COLUMN SUCC_NOCS SCS_NOCS BIGINT(20) UNSIGNED NOT NULL DEFAULT 0 COMMENT '성공건수';

/* 이력: 공통표준 HSTRY 사용(HIST 비표준 약어 제거) */
ALTER TABLE eqpmnt_sync_hist
    CHANGE COLUMN SYNC_HIST_SN SYNC_HSTRY_SN BIGINT(20) UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '동기화이력일련번호',
    RENAME INDEX IX_SYNC_HIST_SYS_DT TO IX_SYNC_HSTRY_SYS_DT;
ALTER TABLE eqpmnt_sync_hist DROP FOREIGN KEY FK_SYNC_HIST_SYS;
ALTER TABLE eqpmnt_sync_hist ADD CONSTRAINT FK_SYNC_HSTRY_SYS FOREIGN KEY (LINK_SYS_SN) REFERENCES link_sys_info (LINK_SYS_SN);

/* 공통표준 단어 약어 추가 보정
 * 모니터링=MNTR, 재시도=RTRY, 기본=BSC, 재전송=RTRSM, 확정=CFMTN,
 * 비밀번호=PSWD, 이관=TRNSF, 표출=EXPRS, 지표=IDCT, 값=VL, 지속=CONTN
 */
ALTER TABLE clct_cycle_info RENAME COLUMN STTS_MNTRG_CYCLE_SEC TO STTS_MNTR_CYCLE_SEC,
                            RENAME COLUMN RETRY_NOCS TO RTRY_NOCS;
ALTER TABLE eqpmnt_info RENAME COLUMN PING_MNTRG_YN TO PING_MNTR_YN;
ALTER TABLE dsblty_type_info RENAME COLUMN DFLT_GRD_CD TO BSC_GRD_CD;
ALTER TABLE sms_group_info RENAME COLUMN RETRSM_CYCLE_MIN TO RTRSM_CYCLE_MIN;
ALTER TABLE link_sys_info RENAME COLUMN PROTCL_CNFM_YN TO PROTCL_CFMTN_YN;
ALTER TABLE eqpmnt_cntn_acnt_info RENAME COLUMN PW_MIGR_YN TO PSWD_TRNSF_YN;
ALTER TABLE dsblty_dsply_info RENAME COLUMN DSBLTY_DSPLY_SN TO DSBLTY_EXPRS_SN,
                               RENAME COLUMN DSPLY_CLSF_NM TO EXPRS_CLSF_NM;

ALTER TABLE dsblty_excp_group_eqpmnt_rel RENAME COLUMN METRIC_CD TO PERF_IDCT_CD;
ALTER TABLE eqpmnt_perf_stts RENAME COLUMN METRIC_CD TO PERF_IDCT_CD,
                              RENAME COLUMN MSRMT_VAL TO MSRMT_VL,
                              RENAME COLUMN TEXT_VAL TO LTR_VL;
ALTER TABLE perf_day_stats RENAME COLUMN METRIC_CD TO PERF_IDCT_CD,
                            RENAME COLUMN AVG_VAL TO AVG_VL,
                            RENAME COLUMN MIN_VAL TO MIN_VL,
                            RENAME COLUMN MAX_VAL TO MAX_VL,
                            RENAME COLUMN SUM_VAL TO SUM_VL;
ALTER TABLE perf_hr_stats RENAME COLUMN METRIC_CD TO PERF_IDCT_CD,
                           RENAME COLUMN AVG_VAL TO AVG_VL,
                           RENAME COLUMN MIN_VAL TO MIN_VL,
                           RENAME COLUMN MAX_VAL TO MAX_VL,
                           RENAME COLUMN SUM_VAL TO SUM_VL;
ALTER TABLE perf_metric_info RENAME COLUMN METRIC_CD TO PERF_IDCT_CD,
                              RENAME COLUMN METRIC_NM TO PERF_IDCT_NM,
                              RENAME COLUMN METRIC_EXPLN TO PERF_IDCT_EXPLN;
ALTER TABLE perf_raw_data RENAME COLUMN METRIC_CD TO PERF_IDCT_CD,
                           RENAME COLUMN MSRMT_VAL TO MSRMT_VL,
                           RENAME COLUMN TEXT_VAL TO LTR_VL;
ALTER TABLE protcl_msg_field_info RENAME COLUMN EX_VAL TO EXM_VL;
ALTER TABLE thrshld_info RENAME COLUMN METRIC_CD TO PERF_IDCT_CD,
                          RENAME COLUMN CAUTION_VAL TO CUTN_VL,
                          RENAME COLUMN WARNING_VAL TO WARN_VL,
                          RENAME COLUMN CRITICAL_VAL TO CRITICAL_VL,
                          RENAME COLUMN RCVR_VAL TO RSTR_VL,
                          RENAME COLUMN DRTN_SEC TO CONTN_SEC;
ALTER TABLE ui_stng_info RENAME COLUMN UI_STNG_VAL TO UI_STNG_VL;
ALTER TABLE job_log RENAME COLUMN TRGT_KEY_VAL TO TRGT_KEY_VL;

RENAME TABLE
    link_sys_chg_hist TO link_sys_chg_hstry,
    eqpmnt_cfg_hist TO eqpmnt_stng_hstry,
    eqpmnt_sync_hist TO eqpmnt_sync_hstry,
    acss_evnt_hist TO enex_evnt_hstry,
    clct_excn_hist TO clct_excn_hstry,
    dsblty_actn_hist TO dsblty_actn_hstry,
    sms_trsm_hist TO sms_trsm_hstry,
    rptp_otpt_hist TO rptp_otpt_hstry,
    dsblty_dsply_info TO dsblty_exprs_info,
    perf_metric_info TO perf_idct_info;

/* 테이블명 변경 후 체크 제약 이름도 의미 일치하도록 교체 */
ALTER TABLE enex_evnt_hstry DROP CONSTRAINT CK_ACSS_EVNT_APRV_YN;
ALTER TABLE enex_evnt_hstry ADD CONSTRAINT CK_ENEX_EVNT_APRV_YN CHECK (APRV_YN IS NULL OR APRV_YN IN ('Y','N'));

DROP TEMPORARY TABLE IF EXISTS tmp_user_sn_map;
DROP TEMPORARY TABLE IF EXISTS tmp_dsblty_sn_map;

SET FOREIGN_KEY_CHECKS = 1;

/* --------------------------------------------------------------------------
 * 7. 사후 확인용 조회 (결과가 0건/정상 PK로 나와야 함)
 * -------------------------------------------------------------------------- */
SELECT 'USER_SN remnants' AS CHECK_ITEM, COUNT(*) AS CNT
  FROM information_schema.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE() AND COLUMN_NAME = 'USER_SN';

SELECT 'user_authrt_rel table remnants' AS CHECK_ITEM, COUNT(*) AS CNT
  FROM information_schema.TABLES
 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'user_authrt_rel';

SELECT 'active users without authority' AS CHECK_ITEM, COUNT(*) AS CNT
  FROM user_info
 WHERE USE_YN != 'N' AND AUTHRT_SN IS NULL;

SELECT 'APLY_SN remnants' AS CHECK_ITEM, COUNT(*) AS CNT
  FROM information_schema.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE() AND COLUMN_NAME = 'APLY_SN';

SELECT 'old HIST tables' AS CHECK_ITEM, COUNT(*) AS CNT
  FROM information_schema.TABLES
 WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME REGEXP '_hist$';

SELECT TABLE_NAME, COLUMN_NAME
  FROM information_schema.COLUMNS
 WHERE TABLE_SCHEMA = DATABASE()
   AND COLUMN_NAME IN ('RGTR_SN','MDFR_SN','CHGR_SN','IDNTY_USER_SN','ACTN_USER_SN','OTPT_USER_SN','APRV_USER_SN',
                       'REQ_YN','SUCC_NOCS','ACSS_DT','ACSS_RSLT_CD','CFG_VER_NO','CFG_FILE_NM','CFG_FILE_PATH_NM',
                       'STTS_MNTRG_CYCLE_SEC','PING_MNTRG_YN','RETRY_NOCS','DFLT_GRD_CD','RETRSM_CYCLE_MIN',
                       'PROTCL_CNFM_YN','PW_MIGR_YN','DSBLTY_DSPLY_SN','DSPLY_CLSF_NM','METRIC_CD','METRIC_NM',
                       'METRIC_EXPLN','TRGT_KEY_VAL','MSRMT_VAL','TEXT_VAL','AVG_VAL','MIN_VAL','MAX_VAL','SUM_VAL',
                       'EX_VAL','CAUTION_VAL','WARNING_VAL','CRITICAL_VAL','RCVR_VAL','UI_STNG_VAL','DRTN_SEC')
 ORDER BY TABLE_NAME, ORDINAL_POSITION;
