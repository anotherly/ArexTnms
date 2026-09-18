/*
 * AREX TNMS UI/UX 화면기획 반영 - DB 구조 보강
 * 대상: MariaDB 10.6 / tnms 260917.sql 기준
 * 실행순서: 이 파일(필수) -> 260917_UIUX_DB_02_SAMPLE_DATA.sql(선택)
 *
 * 운영 UI 설정(commonUi)은 변경하지 않습니다.
 */

/* 1. 사용자별 알림 읽음 상태
 * 기존 알림 원천(dsblty_info / user_acnt_aply_info / job_log)은 그대로 두고
 * 사용자별 읽음 여부만 별도 저장합니다.
 */
CREATE TABLE IF NOT EXISTS `user_ntcn_read_info` (
  `USER_ID` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '사용자아이디',
  `NTCN_ID` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '가상알림아이디(FAULT:/ACCOUNT:/OP:)',
  `READ_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '읽음일시',
  PRIMARY KEY (`USER_ID`,`NTCN_ID`),
  KEY `IX_USER_NTCN_READ_DT` (`READ_DT`),
  CONSTRAINT `FK_USER_NTCN_READ_USER` FOREIGN KEY (`USER_ID`) REFERENCES `user_info` (`USER_ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='사용자별알림읽음상태';

/* 2. 행선안내 표시장치 ↔ LSE 복수 연결관계 */
CREATE TABLE IF NOT EXISTS `pids_eqpmnt_lse_rel` (
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '행선안내장비일련번호',
  `LSE_EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT 'LSE장비일련번호',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`EQPMNT_SN`,`LSE_EQPMNT_SN`),
  KEY `IX_PIDS_LSE_REL_LSE` (`LSE_EQPMNT_SN`),
  CONSTRAINT `FK_PIDS_LSE_REL_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `FK_PIDS_LSE_REL_LSE` FOREIGN KEY (`LSE_EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `CK_PIDS_LSE_REL_SELF` CHECK (`EQPMNT_SN` <> `LSE_EQPMNT_SN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='행선안내장비LSE연결관계';

/* 3. 설비 논리 구성도용 장비간 연결관계
 * 현재는 전송설비 구성도에서 사용. 향후 다른 시스템에도 공통 사용 가능하도록 범용 테이블로 구성합니다.
 */
CREATE TABLE IF NOT EXISTS `eqpmnt_lnk_rel` (
  `FROM_EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '출발장비일련번호',
  `TO_EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '도착장비일련번호',
  `LINK_TYPE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LOGICAL' COMMENT '연결유형코드',
  `LINK_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '연결명',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  PRIMARY KEY (`FROM_EQPMNT_SN`,`TO_EQPMNT_SN`,`LINK_TYPE_CD`),
  KEY `IX_EQPMNT_LNK_REL_TO` (`TO_EQPMNT_SN`),
  CONSTRAINT `FK_EQPMNT_LNK_REL_FROM` FOREIGN KEY (`FROM_EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `FK_EQPMNT_LNK_REL_TO` FOREIGN KEY (`TO_EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `CK_EQPMNT_LNK_REL_USE_YN` CHECK (`USE_YN` in ('Y','N')),
  CONSTRAINT `CK_EQPMNT_LNK_REL_SELF` CHECK (`FROM_EQPMNT_SN` <> `TO_EQPMNT_SN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장비간논리연결관계';

/* 4. 전송설비 화면의 Interface 사용/전체 수는 기존 성능현재값 구조를 재사용합니다. */
INSERT INTO `perf_idct_info`
(`PERF_IDCT_CD`,`PERF_IDCT_NM`,`DATA_SE_CD`,`UNIT_NM`,`DATA_TYPE_NM`,`PERF_IDCT_EXPLN`,`USE_YN`,`REG_DT`)
VALUES
('IF_USE_NOCS','사용 인터페이스 수','P','port','DECIMAL','현재 사용 중인 인터페이스(포트) 수','Y',NOW()),
('IF_TOTAL_NOCS','전체 인터페이스 수','P','port','DECIMAL','장비의 전체 인터페이스(포트) 수','Y',NOW())
ON DUPLICATE KEY UPDATE
  `PERF_IDCT_NM` = VALUES(`PERF_IDCT_NM`),
  `DATA_SE_CD` = VALUES(`DATA_SE_CD`),
  `UNIT_NM` = VALUES(`UNIT_NM`),
  `DATA_TYPE_NM` = VALUES(`DATA_TYPE_NM`),
  `PERF_IDCT_EXPLN` = VALUES(`PERF_IDCT_EXPLN`),
  `USE_YN` = 'Y';
