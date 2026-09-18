/*
 * AREX TNMS 사용자-권한 단일권한 구조 전환
 * 대상: USER_ID 자연키 전환이 완료된 현재 스키마
 * MariaDB 10.6
 *
 * 변경 전: user_info 1:N user_authrt_rel N:1 authrt_info
 * 변경 후: user_info.AUTHRT_SN -> authrt_info.AUTHRT_SN
 *
 * 전제: TNMS 애플리케이션 정책상 활성 사용자 1명은 현재 권한 1개만 가짐.
 * 주의: DDL은 자동 COMMIT되므로 실행 전 DB 백업 권장. 본 파일은 1회만 실행.
 */

USE `arex_tnms`;

DROP PROCEDURE IF EXISTS sp_tnms_user_authrt_direct_precheck;
DELIMITER //
CREATE PROCEDURE sp_tnms_user_authrt_direct_precheck()
BEGIN
    IF EXISTS (
        SELECT 1
          FROM information_schema.COLUMNS
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'user_info'
           AND COLUMN_NAME = 'AUTHRT_SN'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration aborted: user_info.AUTHRT_SN already exists.';
    END IF;

    IF NOT EXISTS (
        SELECT 1
          FROM information_schema.TABLES
         WHERE TABLE_SCHEMA = DATABASE()
           AND TABLE_NAME = 'user_authrt_rel'
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration aborted: user_authrt_rel does not exist.';
    END IF;

    /* 단일권한 정책인데 현재 활성 권한이 2개 이상인 사용자가 있으면 자동 결정하지 않음 */
    IF EXISTS (
        SELECT 1
          FROM user_authrt_rel
         WHERE AUTHRT_BGNG_DT <= NOW()
           AND (AUTHRT_END_DT IS NULL OR AUTHRT_END_DT > NOW())
         GROUP BY USER_ID
        HAVING COUNT(*) > 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration aborted: a user has multiple active authorities.';
    END IF;

    /* 사용중인 사용자는 반드시 현재 유효 권한이 1개 있어야 함 */
    IF EXISTS (
        SELECT 1
          FROM user_info U
          LEFT JOIN user_authrt_rel R
            ON R.USER_ID = U.USER_ID
           AND R.AUTHRT_BGNG_DT <= NOW()
           AND (R.AUTHRT_END_DT IS NULL OR R.AUTHRT_END_DT > NOW())
         WHERE U.USE_YN != 'N'
           AND R.AUTHRT_SN IS NULL
         LIMIT 1
    ) THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Migration aborted: an active user has no active authority.';
    END IF;
END//
DELIMITER ;

CALL sp_tnms_user_authrt_direct_precheck();
DROP PROCEDURE sp_tnms_user_authrt_direct_precheck;

/* 1. user_info에 현재 권한 FK 컬럼 추가 */
ALTER TABLE user_info
    ADD COLUMN AUTHRT_SN BIGINT(20) UNSIGNED NULL COMMENT '권한일련번호' AFTER USER_ENPSWD;

/* 2. 현재 유효한 단일 권한을 사용자 본체로 이관
 *    삭제 사용자(USE_YN='N')는 기존 서비스의 권한관계 삭제 동작과 동일하게 NULL 유지.
 */
UPDATE user_info U
LEFT JOIN user_authrt_rel R
  ON R.USER_ID = U.USER_ID
 AND R.AUTHRT_BGNG_DT <= NOW()
 AND (R.AUTHRT_END_DT IS NULL OR R.AUTHRT_END_DT > NOW())
SET U.AUTHRT_SN = CASE WHEN U.USE_YN = 'N' THEN NULL ELSE R.AUTHRT_SN END;

/* 3. FK / 무결성 제약 추가
 *    활성 사용자에는 권한이 필수이고, 삭제 사용자만 NULL 허용.
 */
ALTER TABLE user_info
    ADD KEY FK_USER_AUTHRT (AUTHRT_SN),
    ADD CONSTRAINT FK_USER_AUTHRT
        FOREIGN KEY (AUTHRT_SN) REFERENCES authrt_info (AUTHRT_SN),
    ADD CONSTRAINT CK_USER_AUTHRT
        CHECK (USE_YN = 'N' OR AUTHRT_SN IS NOT NULL);

/* 4. 더 이상 사용하지 않는 사용자-권한 관계 테이블 제거 */
DROP TABLE user_authrt_rel;

/* 5. 사후 확인 */
SELECT 'user_authrt_rel table remnants' AS CHECK_ITEM, COUNT(*) AS CNT
  FROM information_schema.TABLES
 WHERE TABLE_SCHEMA = DATABASE()
   AND TABLE_NAME = 'user_authrt_rel';

SELECT 'active users without authority' AS CHECK_ITEM, COUNT(*) AS CNT
  FROM user_info
 WHERE USE_YN != 'N'
   AND AUTHRT_SN IS NULL;

SELECT U.USER_ID, U.USER_NM, U.AUTHRT_SN, A.AUTHRT_NM, U.USE_YN
  FROM user_info U
  LEFT JOIN authrt_info A ON A.AUTHRT_SN = U.AUTHRT_SN
 ORDER BY U.USER_ID;
