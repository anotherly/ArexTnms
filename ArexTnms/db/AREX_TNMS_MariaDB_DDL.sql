/*
 * AREX TNMS MariaDB 10.6 canonical DDL
 * 기준: 2026-09-10 구조개선 반영 + 공공데이터 공통표준(2025.11)
 * 사용자 식별자는 USER_ID를 PK/FK로 사용하며 USER_SN은 사용하지 않음.
 */
/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
CREATE DATABASE IF NOT EXISTS `arex_tnms` DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE `arex_tnms`;

-- enex_evnt_hstry
CREATE TABLE IF NOT EXISTS `enex_evnt_hstry` (
  `ENEX_EVNT_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '출입이벤트일련번호',
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '출입통제장비일련번호',
  `EVNT_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '이벤트코드',
  `EVNT_NM` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '이벤트명',
  `ENEX_DT` datetime NOT NULL COMMENT '출입일시',
  `ENEX_RSLT_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '출입결과코드',
  `APRV_YN` char(1) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '승인여부',
  `CARD_NO_HASH` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '카드번호해시값',
  `EVNT_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '이벤트내용',
  `CLCT_DT` datetime NOT NULL COMMENT '수집일시',
  PRIMARY KEY (`ENEX_EVNT_SN`),
  KEY `IX_ENEX_EVNT_DT` (`ENEX_DT`,`EQPMNT_SN`),
  KEY `FK_ENEX_EVNT_EQPMNT` (`EQPMNT_SN`),
  CONSTRAINT `FK_ENEX_EVNT_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `CK_ENEX_EVNT_APRV_YN` CHECK (`APRV_YN` is null or `APRV_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SCADA시설출입보안이벤트';

-- authrt_info
CREATE TABLE IF NOT EXISTS `authrt_info` (
  `AUTHRT_CD` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '권한코드',
  `AUTHRT_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '권한명',
  `AUTHRT_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '권한설명',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`AUTHRT_CD`),
  UNIQUE KEY `UK_AUTHRT_NM` (`AUTHRT_NM`),
  CONSTRAINT `CK_AUTHRT_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='권한';

-- authrt_menu_rel
CREATE TABLE IF NOT EXISTS `authrt_menu_rel` (
  `AUTHRT_CD` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '권한코드',
  `MENU_SN` bigint(20) unsigned NOT NULL COMMENT '메뉴일련번호',
  `LIST_AUTHRT_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '목록권한여부',
  `DTL_AUTHRT_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '상세권한여부',
  `REG_AUTHRT_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '등록권한여부',
  `MDFCN_AUTHRT_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '수정권한여부',
  `DEL_AUTHRT_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '삭제권한여부',
  `CTRL_AUTHRT_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '제어권한여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`AUTHRT_CD`,`MENU_SN`),
  KEY `FK_AUTHRT_MENU_MENU` (`MENU_SN`),
  CONSTRAINT `FK_AUTHRT_MENU_AUTHRT` FOREIGN KEY (`AUTHRT_CD`) REFERENCES `authrt_info` (`AUTHRT_CD`),
  CONSTRAINT `FK_AUTHRT_MENU_MENU` FOREIGN KEY (`MENU_SN`) REFERENCES `menu_info` (`MENU_SN`),
  CONSTRAINT `CK_AUTHRT_MENU_YN` CHECK (`LIST_AUTHRT_YN` in ('Y','N') and `DTL_AUTHRT_YN` in ('Y','N') and `REG_AUTHRT_YN` in ('Y','N') and `MDFCN_AUTHRT_YN` in ('Y','N') and `DEL_AUTHRT_YN` in ('Y','N') and `CTRL_AUTHRT_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='권한별메뉴기능';

-- bzenty_info
CREATE TABLE IF NOT EXISTS `bzenty_info` (
  `BZENTY_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '업체일련번호',
  `BZENTY_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '업체명',
  `BRNO` char(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '사업자등록번호',
  `BZENTY_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '업체구분코드',
  `PIC_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '담당자명',
  `PIC_TELNO` varchar(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '담당자전화번호',
  `PIC_EML_ADDR` varchar(320) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '담당자이메일주소',
  `ADDR` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '주소',
  `DADDR` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '상세주소',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`BZENTY_SN`),
  KEY `IX_BZENTY_NM` (`BZENTY_NM`),
  CONSTRAINT `CK_BZENTY_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='납품·연동·유지보수업체';

-- cctv_info
CREATE TABLE IF NOT EXISTS `cctv_info` (
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `NEW_LBL_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '신규라벨명',
  `LBL_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '라벨명',
  `FLR_NM` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '층명',
  `RLWY_LEN` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '선로길이(원천 혼합형)',
  `RPTR_USE_YN` char(1) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '리피터사용여부',
  `COMM_LNKG_EQPMNT_LBL_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '통신연결장비라벨명',
  `COMM_LNKG_EQPMNT_PORT_NO` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '통신연결장비포트번호',
  `COMM_LNKG_EQPMNT_KND_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '통신연결장비종류명',
  `COMM_LNKG_EQPMNT_INSTL_PLC_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '통신연결장비설치장소명',
  `PWR_SPLY_EQPMNT_LBL_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '전원공급장비라벨명',
  `PWR_SPLY_EQPMNT_KND_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '전원공급장비종류명',
  `PWR_SPLY_EQPMNT_INSTL_PLC_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '전원공급장비설치장소명',
  `STRG_SRVR_LBL_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '저장서버라벨명',
  `STRG_SRVR_INSTL_PLC_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '저장서버설치장소명',
  `CMRA_QTY` int(10) unsigned DEFAULT NULL COMMENT '카메라수량',
  `RSRV_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '예비여부',
  `STRG_MTH_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '저장방식명',
  `FRMWR_VER_NO` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '펌웨어버전번호',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  PRIMARY KEY (`EQPMNT_SN`),
  CONSTRAINT `FK_CCTV_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `CK_CCTV_RSRV_YN` CHECK (`RSRV_YN` in ('Y','N') and (`RPTR_USE_YN` is null or `RPTR_USE_YN` in ('Y','N')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='CCTV선번장기반상세정보';

-- clct_cycle_info
CREATE TABLE IF NOT EXISTS `clct_cycle_info` (
  `CLCT_CYCLE_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '수집주기일련번호',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `DATA_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '데이터구분코드(F/P/C/S)',
  `CLCT_CYCLE_SEC` int(10) unsigned NOT NULL DEFAULT 300 COMMENT '수집주기초수',
  `EXCN_TM` time DEFAULT NULL COMMENT '실행시각',
  `CYCLE_CRTR_CN` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '주기근거내용',
  `STTS_MNTR_CYCLE_SEC` int(10) unsigned NOT NULL DEFAULT 30 COMMENT '상태모니터링주기초수',
  `TIMEOUT_SEC` int(10) unsigned NOT NULL DEFAULT 10 COMMENT '타임아웃초수',
  `RTRY_NOCS` int(10) unsigned NOT NULL DEFAULT 3 COMMENT '재시도건수',
  `LAST_EXCN_DT` datetime DEFAULT NULL COMMENT '최종실행일시',
  `NEXT_EXCN_DT` datetime DEFAULT NULL COMMENT '다음실행일시',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`CLCT_CYCLE_SN`),
  UNIQUE KEY `UK_CLCT_CYCLE` (`LINK_SYS_CD`,`DATA_SE_CD`),
  CONSTRAINT `FK_CLCT_CYCLE_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`),
  CONSTRAINT `CK_CLCT_CYCLE_SEC` CHECK (`CLCT_CYCLE_SEC` >= 60 and `STTS_MNTR_CYCLE_SEC` <= 30),
  CONSTRAINT `CK_CLCT_CYCLE_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB AUTO_INCREMENT=17 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='시스템별수집및상태감시주기';

-- clct_excn_hstry
CREATE TABLE IF NOT EXISTS `clct_excn_hstry` (
  `CLCT_EXCN_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '수집실행일련번호',
  `CLCT_CYCLE_SN` bigint(20) unsigned NOT NULL COMMENT '수집주기일련번호',
  `EXCN_BGNG_DT` datetime NOT NULL COMMENT '실행시작일시',
  `EXCN_END_DT` datetime DEFAULT NULL COMMENT '실행종료일시',
  `CLCT_NOCS` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT '수집건수',
  `SCS_NOCS` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT '성공건수',
  `FAIL_NOCS` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT '실패건수',
  `STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '상태코드',
  `ERR_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '오류내용',
  PRIMARY KEY (`CLCT_EXCN_SN`),
  KEY `IX_CLCT_EXCN_DT` (`CLCT_CYCLE_SN`,`EXCN_BGNG_DT`),
  CONSTRAINT `FK_CLCT_EXCN_CYCLE` FOREIGN KEY (`CLCT_CYCLE_SN`) REFERENCES `clct_cycle_info` (`CLCT_CYCLE_SN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='수집실행이력';

-- cntn_log
CREATE TABLE IF NOT EXISTS `cntn_log` (
  `CNTN_LOG_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '접속로그일련번호',
  `USER_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '사용자아이디',
  `LGN_IP_ADDR` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '로그인IP주소(IPv4)',
  `CNTN_BGNG_DT` datetime NOT NULL COMMENT '접속시작일시',
  `LGT_DT` datetime DEFAULT NULL COMMENT '로그아웃일시',
  `CNTN_BRWSR_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '접속브라우저명',
  `CNTN_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '접속여부',
  `FAIL_RSN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '실패사유',
  PRIMARY KEY (`CNTN_LOG_SN`),
  KEY `IX_CNTN_LOG_USER_DT` (`USER_ID`,`CNTN_BGNG_DT`),
  KEY `IX_CNTN_LOG_RESULT_DT` (`CNTN_YN`,`CNTN_BGNG_DT`),
  CONSTRAINT `CK_CNTN_LOG_YN` CHECK (`CNTN_YN` in ('Y','N'))
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='로그인접속이력';

-- com_cd_group_info
CREATE TABLE IF NOT EXISTS `com_cd_group_info` (
  `COM_CD_GROUP_ID` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '공통코드그룹아이디',
  `COM_CD_GROUP_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '공통코드그룹명',
  `COM_CD_GROUP_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '공통코드그룹설명',
  `COM_CD_LEN` int(10) unsigned DEFAULT NULL COMMENT '공통코드길이',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`COM_CD_GROUP_ID`),
  CONSTRAINT `CK_COM_CD_GROUP_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='공통코드그룹';

-- com_cd_info
CREATE TABLE IF NOT EXISTS `com_cd_info` (
  `COM_CD_GROUP_ID` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '공통코드그룹아이디',
  `COM_CD` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '공통코드',
  `COM_CD_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '공통코드명',
  `COM_CD_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '공통코드설명',
  `COM_CD_SEQ` int(10) unsigned NOT NULL DEFAULT 1 COMMENT '공통코드순서',
  `COM_CD_USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '공통코드사용여부',
  `EXT1_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '확장1내용',
  `EXT2_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '확장2내용',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`COM_CD_GROUP_ID`,`COM_CD`),
  CONSTRAINT `FK_COM_CD_GROUP` FOREIGN KEY (`COM_CD_GROUP_ID`) REFERENCES `com_cd_group_info` (`COM_CD_GROUP_ID`),
  CONSTRAINT `CK_COM_CD_USE_YN` CHECK (`COM_CD_USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='공통상세코드';

-- dsblty_actn_hstry
CREATE TABLE IF NOT EXISTS `dsblty_actn_hstry` (
  `ACTN_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '조치일련번호',
  `DSBLTY_NO` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장애번호',
  `ACTN_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '조치구분코드(임시/완료/이관/제어)',
  `ACTN_CN` text COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '조치내용',
  `DSBLTY_SYMPTM_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장애현상내용',
  `DSBLTY_RSN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장애원인',
  `AFTR_PLAN_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '향후대책내용',
  `ACTN_RSLT_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '조치결과내용',
  `ACTN_PIC_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '조치담당자명',
  `ACTN_USER_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '조치사용자아이디',
  `ACTN_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '조치일시',
  `CTRL_CMD_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '제어명령내용',
  `LINK_RAW_SN` bigint(20) unsigned DEFAULT NULL COMMENT '연계원본일련번호',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`ACTN_SN`),
  KEY `IX_DSBLTY_ACTN` (`DSBLTY_NO`,`ACTN_DT`),
  CONSTRAINT `FK_DSBLTY_ACTN_DSBLTY` FOREIGN KEY (`DSBLTY_NO`) REFERENCES `dsblty_info` (`DSBLTY_NO`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장애임시·완료·이관·제어조치';

-- dsblty_exprs_info
CREATE TABLE IF NOT EXISTS `dsblty_exprs_info` (
  `DSBLTY_EXPRS_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '장애표출일련번호',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `EQPM_NM` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '설비명',
  `EXPRS_CLSF_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '표출분류명',
  `EVNT_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '이벤트내용',
  `RMRK_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '비고내용',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`DSBLTY_EXPRS_SN`),
  KEY `FK_DSBLTY_EXPRS_SYS` (`LINK_SYS_CD`),
  CONSTRAINT `FK_DSBLTY_EXPRS_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장애표출정책';

-- dsblty_excp_group_eqpmnt_rel
CREATE TABLE IF NOT EXISTS `dsblty_excp_group_eqpmnt_rel` (
  `EXCP_GROUP_SN` bigint(20) unsigned NOT NULL COMMENT '예외그룹일련번호',
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `ALL_IDCT_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '전체지표여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`EXCP_GROUP_SN`,`EQPMNT_SN`),
  KEY `FK_EXCP_EQPMNT_EQPMNT` (`EQPMNT_SN`),
  CONSTRAINT `FK_EXCP_EQPMNT_GROUP` FOREIGN KEY (`EXCP_GROUP_SN`) REFERENCES `dsblty_excp_group_info` (`EXCP_GROUP_SN`),
  CONSTRAINT `FK_EXCP_EQPMNT_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `CK_EXCP_EQPMNT_ALL_IDCT_YN` CHECK (`ALL_IDCT_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장애예외그룹장비';

-- dsblty_excp_group_eqpmnt_idct_rel
CREATE TABLE IF NOT EXISTS `dsblty_excp_group_eqpmnt_idct_rel` (
  `EXCP_GROUP_SN` bigint(20) unsigned NOT NULL COMMENT '예외그룹일련번호',
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `PERF_IDCT_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '성능지표코드',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`EXCP_GROUP_SN`,`EQPMNT_SN`,`PERF_IDCT_CD`),
  KEY `FK_EXCP_EQPMNT_IDCT_IDCT` (`PERF_IDCT_CD`),
  CONSTRAINT `FK_EXCP_EQPMNT_IDCT_PARENT` FOREIGN KEY (`EXCP_GROUP_SN`,`EQPMNT_SN`) REFERENCES `dsblty_excp_group_eqpmnt_rel` (`EXCP_GROUP_SN`,`EQPMNT_SN`),
  CONSTRAINT `FK_EXCP_EQPMNT_IDCT_IDCT` FOREIGN KEY (`PERF_IDCT_CD`) REFERENCES `perf_idct_info` (`PERF_IDCT_CD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장애예외그룹장비성능지표';

-- dsblty_excp_group_info
CREATE TABLE IF NOT EXISTS `dsblty_excp_group_info` (
  `EXCP_GROUP_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '예외그룹일련번호',
  `EXCP_GROUP_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '예외그룹명',
  `EXCP_GROUP_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '예외그룹설명',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`EXCP_GROUP_SN`),
  UNIQUE KEY `UK_EXCP_GROUP_NM` (`EXCP_GROUP_NM`),
  CONSTRAINT `CK_EXCP_GROUP_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장애예외장비그룹';

-- dsblty_excp_schdl_info
CREATE TABLE IF NOT EXISTS `dsblty_excp_schdl_info` (
  `EXCP_SCHDL_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '예외일정일련번호',
  `EXCP_GROUP_SN` bigint(20) unsigned NOT NULL COMMENT '예외그룹일련번호',
  `EXCP_SCHDL_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '예외일정명',
  `BGNG_DT` datetime NOT NULL COMMENT '시작일시',
  `END_DT` datetime NOT NULL COMMENT '종료일시',
  `REPT_CYCLE_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '반복주기내용',
  `EXCP_RSN` varchar(4000) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '예외사유',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`EXCP_SCHDL_SN`),
  KEY `IX_EXCP_SCHDL_TIME` (`BGNG_DT`,`END_DT`,`USE_YN`),
  KEY `FK_EXCP_SCHDL_GROUP` (`EXCP_GROUP_SN`),
  CONSTRAINT `FK_EXCP_SCHDL_GROUP` FOREIGN KEY (`EXCP_GROUP_SN`) REFERENCES `dsblty_excp_group_info` (`EXCP_GROUP_SN`),
  CONSTRAINT `CK_EXCP_SCHDL_DT` CHECK (`END_DT` > `BGNG_DT`),
  CONSTRAINT `CK_EXCP_SCHDL_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장애예외시간설정';

-- dsblty_excp_schdl_grd_rel
CREATE TABLE IF NOT EXISTS `dsblty_excp_schdl_grd_rel` (
  `EXCP_SCHDL_SN` bigint(20) unsigned NOT NULL COMMENT '예외일정일련번호',
  `DSBLTY_GRD_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장애등급코드',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`EXCP_SCHDL_SN`,`DSBLTY_GRD_CD`),
  CONSTRAINT `FK_EXCP_SCHDL_GRD_SCHDL` FOREIGN KEY (`EXCP_SCHDL_SN`) REFERENCES `dsblty_excp_schdl_info` (`EXCP_SCHDL_SN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장애예외일정등급';

-- dsblty_info
CREATE TABLE IF NOT EXISTS `dsblty_info` (
  `DSBLTY_NO` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장애번호',
  `EMS_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'EMS아이디',
  `SOU_EQPMNT_ID` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '원천장비아이디',
  `EQPMNT_SN` bigint(20) unsigned DEFAULT NULL COMMENT '장비일련번호',
  `DSBLTY_TYPE_SN` bigint(20) unsigned DEFAULT NULL COMMENT '장애유형일련번호',
  `DSBLTY_OCRN_PLC_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장애발생장소명',
  `DSBLTY_GRD_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장애등급코드',
  `OCRN_RCVR_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '발생복구구분코드(발생=1, 복구=0)',
  `DSBLTY_OCRN_DT` datetime NOT NULL COMMENT '장애발생일시',
  `DSBLTY_END_DT` datetime DEFAULT NULL COMMENT '장애종료일시',
  `DSBLTY_OCRN_CN` varchar(4000) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장애발생내용',
  `DSBLTY_RSN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장애사유',
  `DSBLTY_JGMT_CD` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장애판단코드(서비스/상태)',
  `PRCS_STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'UNCONFIRMED' COMMENT '처리상태코드',
  `IDNTY_USER_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '확인사용자아이디',
  `IDNTY_DT` datetime DEFAULT NULL COMMENT '확인일시',
  `EXCP_APLY_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '예외적용여부',
  `SRC_EVNT_NO` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '원천이벤트번호',
  `LINK_RAW_SN` bigint(20) unsigned DEFAULT NULL COMMENT '연계원본일련번호',
  `LAST_MDFCN_DT` datetime DEFAULT NULL COMMENT '최종수정일시',
  PRIMARY KEY (`DSBLTY_NO`),
  KEY `IX_DSBLTY_ACTIVE` (`DSBLTY_END_DT`,`DSBLTY_GRD_CD`,`PRCS_STTS_CD`),
  KEY `IX_DSBLTY_EQPMNT_DT` (`EQPMNT_SN`,`DSBLTY_OCRN_DT`),
  KEY `FK_DSBLTY_TYPE` (`DSBLTY_TYPE_SN`),
  CONSTRAINT `FK_DSBLTY_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `FK_DSBLTY_TYPE` FOREIGN KEY (`DSBLTY_TYPE_SN`) REFERENCES `dsblty_type_info` (`DSBLTY_TYPE_SN`),
  CONSTRAINT `CK_DSBLTY_EXCP_YN` CHECK (`EXCP_APLY_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='실시간및이력장애';

-- dsblty_type_info
CREATE TABLE IF NOT EXISTS `dsblty_type_info` (
  `DSBLTY_TYPE_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '장애유형일련번호',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '연계시스템코드(NULL=공통)',
  `EVNT_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '이벤트코드',
  `DSBLTY_TYPE_NM` varchar(300) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장애유형명',
  `DSBLTY_OCRN_PLC_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장애발생장소명',
  `DSBLTY_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장애명',
  `BSC_GRD_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '기본등급코드',
  `JGMT_CRTR_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '판단기준내용',
  `AUTO_END_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '자동종료여부',
  `SMS_USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT 'SMS사용여부',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `AUTO_REG_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '자동등록여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`DSBLTY_TYPE_SN`),
  UNIQUE KEY `UK_DSBLTY_TYPE_EVNT` (`LINK_SYS_CD`,`EVNT_CD`),
  CONSTRAINT `FK_DSBLTY_TYPE_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`),
  CONSTRAINT `CK_DSBLTY_TYPE_YN` CHECK (`AUTO_END_YN` in ('Y','N') and `SMS_USE_YN` in ('Y','N') and `USE_YN` in ('Y','N') and `AUTO_REG_YN` in ('Y','N'))
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장애유형';

-- ems_info
CREATE TABLE IF NOT EXISTS `ems_info` (
  `EMS_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'EMS일련번호',
  `EMS_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'EMS아이디',
  `EQPM_NM` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '설비명',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '연계시스템코드',
  `EMS_IP_ADDR` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'EMS IP주소',
  `EQPMNT_CTRL_USE_YN` char(1) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비제어사용여부',
  `RMRK_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '비고내용',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`EMS_SN`),
  UNIQUE KEY `UK_EMS_ID_EQPM` (`EMS_ID`,`EQPM_NM`),
  KEY `FK_EMS_LINK_SYS` (`LINK_SYS_CD`),
  CONSTRAINT `FK_EMS_LINK_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`),
  CONSTRAINT `CK_EMS_CTRL_YN` CHECK (`EQPMNT_CTRL_USE_YN` is null or `EQPMNT_CTRL_USE_YN` in ('Y','N'))
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='EMS식별정보';

-- eqpmnt_stng_hstry
CREATE TABLE IF NOT EXISTS `eqpmnt_stng_hstry` (
  `EQPMNT_STNG_HSTRY_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '장비설정이력일련번호',
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `STNG_VER_NO` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '설정버전번호',
  `STNG_FILE_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '설정파일명',
  `STNG_FILE_PATH_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '설정파일경로명',
  `CHG_ARTCL_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '변경항목명',
  `CHG_BFR_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '변경이전내용',
  `CHG_AFTR_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '변경이후내용',
  `CHG_RSN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '변경사유',
  `BKUP_DT` datetime DEFAULT NULL COMMENT '백업일시',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  PRIMARY KEY (`EQPMNT_STNG_HSTRY_SN`),
  KEY `IX_EQPMNT_STNG_HSTRY` (`EQPMNT_SN`,`REG_DT`),
  CONSTRAINT `FK_EQPMNT_STNG_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장비설정및백업이력';

-- eqpmnt_clsf_info
CREATE TABLE IF NOT EXISTS `eqpmnt_clsf_info` (
  `EQPMNT_CLSF_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장비분류코드',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `EQPM_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '설비명',
  `EQPMNT_CLSF_NM` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장비분류명',
  `RMRK_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '비고내용',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`EQPMNT_CLSF_CD`),
  UNIQUE KEY `UK_EQPMNT_CLSF` (`LINK_SYS_CD`,`EQPM_NM`,`EQPMNT_CLSF_NM`),
  CONSTRAINT `FK_EQPMNT_CLSF_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='연계시스템별장비분류';

-- eqpmnt_cntn_acnt_info
CREATE TABLE IF NOT EXISTS `eqpmnt_cntn_acnt_info` (
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `USER_ID` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '사용자아이디',
  `ENPSWD` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '암호화비밀번호',
  `PSWD_TRNSF_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '비밀번호이관여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  PRIMARY KEY (`EQPMNT_SN`),
  CONSTRAINT `FK_EQPMNT_CNTN_ACNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장비접속계정_평문PW제외';

-- eqpmnt_info
CREATE TABLE IF NOT EXISTS `eqpmnt_info` (
  `EQPMNT_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '장비일련번호',
  `EQPMNT_MNG_NO` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장비관리번호',
  `EQPMNT_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장비명',
  `EQPMNT_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장비구분코드',
  `EQPMNT_CLSF_CD` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비분류코드',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `EMS_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'EMS아이디(통신규격 v1.9)',
  `SOU_EQPMNT_ID` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '원천장비아이디',
  `STN_CD` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '역사코드',
  `INSTL_PLC_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '설치장소명',
  `EQPMNT_IP_ADDR` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비IP주소(IPv4)',
  `SOU_EQPMNT_IP_ADDR` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '원천장비IP주소',
  `MAC_ADDR` varchar(17) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'MAC주소',
  `SRVR_PORT_NO` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '서버포트번호',
  `EQPMNT_MDL_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비모델명',
  `SW_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '소프트웨어명',
  `VER_NO` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '버전번호',
  `MNFTR_NO` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '제조번호',
  `MKR_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '제조사명',
  `INSTL_YMD` date DEFAULT NULL COMMENT '설치일자',
  `EXPT_END_YMD` date DEFAULT NULL COMMENT '예상종료일자',
  `BZENTY_SN` bigint(20) unsigned DEFAULT NULL COMMENT '납품·유지보수업체일련번호',
  `PING_MNTR_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT 'PING모니터링여부',
  `PING_CYCLE_SEC` int(10) unsigned NOT NULL DEFAULT 30 COMMENT 'PING주기초수',
  `EQPMNT_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비설명',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`EQPMNT_SN`),
  UNIQUE KEY `UK_EQPMNT_MNG_NO` (`EQPMNT_MNG_NO`),
  KEY `IX_EQPMNT_SYS_STN` (`LINK_SYS_CD`,`STN_CD`,`EQPMNT_SE_CD`),
  KEY `FK_EQPMNT_CLSF` (`EQPMNT_CLSF_CD`),
  KEY `IX_EQPMNT_IP` (`EQPMNT_IP_ADDR`),
  KEY `FK_EQPMNT_STN` (`STN_CD`),
  KEY `FK_EQPMNT_BZENTY` (`BZENTY_SN`),
  CONSTRAINT `FK_EQPMNT_BZENTY` FOREIGN KEY (`BZENTY_SN`) REFERENCES `bzenty_info` (`BZENTY_SN`),
  CONSTRAINT `FK_EQPMNT_LINK_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`),
  CONSTRAINT `FK_EQPMNT_CLSF` FOREIGN KEY (`EQPMNT_CLSF_CD`) REFERENCES `eqpmnt_clsf_info` (`EQPMNT_CLSF_CD`),
  CONSTRAINT `FK_EQPMNT_STN` FOREIGN KEY (`STN_CD`) REFERENCES `stn_info` (`STN_CD`),
  CONSTRAINT `CK_EQPMNT_YN` CHECK (`PING_MNTR_YN` in ('Y','N') and `USE_YN` in ('Y','N'))
) ENGINE=InnoDB AUTO_INCREMENT=2305 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='통합관리장비';

-- eqpmnt_mtbf_info
CREATE TABLE IF NOT EXISTS `eqpmnt_mtbf_info` (
  `EQPMNT_MTBF_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '장비MTBF일련번호',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `EQPM_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '설비명',
  `EQPMNT_CLSF_CD` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비분류코드',
  `EQPMNT_MDL_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비모델명',
  `PRTS_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '부품명',
  `SVLF` decimal(10,2) DEFAULT NULL COMMENT '내용연수',
  `MTBF_HR` bigint(20) unsigned DEFAULT NULL COMMENT '평균고장간격시간',
  `DSBLTY_OCRN_FREQ_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장애발생빈도내용',
  `RMRK_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '비고내용',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`EQPMNT_MTBF_SN`),
  KEY `IX_EQPMNT_MTBF` (`LINK_SYS_CD`,`EQPMNT_CLSF_CD`,`EQPMNT_MDL_NM`),
  CONSTRAINT `FK_EQPMNT_MTBF_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`),
  CONSTRAINT `FK_EQPMNT_MTBF_CLSF` FOREIGN KEY (`EQPMNT_CLSF_CD`) REFERENCES `eqpmnt_clsf_info` (`EQPMNT_CLSF_CD`)
) ENGINE=InnoDB AUTO_INCREMENT=57 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장비·부품내용연수및MTBF';

-- eqpmnt_perf_stts
CREATE TABLE IF NOT EXISTS `eqpmnt_perf_stts` (
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `PERF_IDCT_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '성능지표코드',
  `MSRMT_VL` decimal(20,6) DEFAULT NULL COMMENT '측정값',
  `LTR_VL` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '문자값',
  `UNIT_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '단위명',
  `STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NORMAL' COMMENT '상태코드',
  `CLCT_DT` datetime NOT NULL COMMENT '수집일시',
  PRIMARY KEY (`EQPMNT_SN`,`PERF_IDCT_CD`),
  KEY `IX_PERF_CURR_STTS` (`STTS_CD`,`CLCT_DT`),
  KEY `FK_PERF_CURR_IDCT` (`PERF_IDCT_CD`),
  CONSTRAINT `FK_PERF_CURR_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `FK_PERF_CURR_IDCT` FOREIGN KEY (`PERF_IDCT_CD`) REFERENCES `perf_idct_info` (`PERF_IDCT_CD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장비성능현재값_대시보드용';

-- eqpmnt_qty_stts
CREATE TABLE IF NOT EXISTS `eqpmnt_qty_stts` (
  `EQPMNT_QTY_STTS_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '장비수량현황일련번호',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `INSTL_PLC_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '설치장소명',
  `EQPMNT_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비명',
  `BFR_EQPMNT_QTY` int(10) unsigned DEFAULT NULL COMMENT '변경전장비수량',
  `AFTR_EQPMNT_QTY` int(10) unsigned DEFAULT NULL COMMENT '변경후장비수량',
  `EQPMNT_QTY` int(10) unsigned DEFAULT NULL COMMENT '장비수량',
  `RMRK_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '비고내용',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`EQPMNT_QTY_STTS_SN`),
  KEY `IX_EQPMNT_QTY` (`LINK_SYS_CD`,`INSTL_PLC_NM`,`EQPMNT_NM`),
  CONSTRAINT `FK_EQPMNT_QTY_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`)
) ENGINE=InnoDB AUTO_INCREMENT=175 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='원천자료장비수량현황';

-- eqpmnt_stts
CREATE TABLE IF NOT EXISTS `eqpmnt_stts` (
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `CNTN_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '접속여부',
  `PING_RSPNS_MS` int(10) unsigned DEFAULT NULL COMMENT 'PING응답밀리초수',
  `STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'UNKNOWN' COMMENT '상태코드',
  `STTS_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '상태설명',
  `LAST_RSPNS_DT` datetime DEFAULT NULL COMMENT '최종응답일시',
  `CLCT_DT` datetime NOT NULL COMMENT '수집일시',
  PRIMARY KEY (`EQPMNT_SN`),
  KEY `IX_EQPMNT_STTS` (`STTS_CD`,`CLCT_DT`),
  CONSTRAINT `FK_EQPMNT_STTS_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `CK_EQPMNT_STTS_CNTN_YN` CHECK (`CNTN_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장비현재상태';

-- eqpmnt_sync_hstry
CREATE TABLE IF NOT EXISTS `eqpmnt_sync_hstry` (
  `SYNC_HSTRY_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '동기화이력일련번호',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `SYNC_BGNG_DT` datetime NOT NULL COMMENT '동기화시작일시',
  `SYNC_END_DT` datetime DEFAULT NULL COMMENT '동기화종료일시',
  `ADD_NOCS` int(10) unsigned NOT NULL DEFAULT 0 COMMENT '추가건수',
  `MDFCN_NOCS` int(10) unsigned NOT NULL DEFAULT 0 COMMENT '수정건수',
  `DEL_NOCS` int(10) unsigned NOT NULL DEFAULT 0 COMMENT '삭제건수',
  `FAIL_NOCS` int(10) unsigned NOT NULL DEFAULT 0 COMMENT '실패건수',
  `STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '상태코드',
  `ERR_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '오류내용',
  PRIMARY KEY (`SYNC_HSTRY_SN`),
  KEY `IX_SYNC_HSTRY_SYS_DT` (`LINK_SYS_CD`,`SYNC_BGNG_DT`),
  CONSTRAINT `FK_SYNC_HSTRY_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장비구성동기화현황';

-- job_log
CREATE TABLE IF NOT EXISTS `job_log` (
  `JOB_LOG_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '작업로그일련번호',
  `USER_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '사용자아이디',
  `USER_IP_ADDR` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '사용자IP주소(IPv4)',
  `CNTN_MENU_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '접속메뉴명',
  `JOB_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '작업구분코드',
  `TRGT_KEY_VL` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '대상키값',
  `LOG_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '로그내용',
  `CHG_BFR_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '변경이전내용',
  `CHG_AFTR_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '변경이후내용',
  `JOB_RSLT_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '작업결과코드',
  `LOG_CRT_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '로그생성일시',
  PRIMARY KEY (`JOB_LOG_SN`),
  KEY `IX_JOB_LOG_USER_DT` (`USER_ID`,`LOG_CRT_DT`),
  KEY `IX_JOB_LOG_MENU_DT` (`CNTN_MENU_NM`,`LOG_CRT_DT`),
  KEY `IX_JOB_LOG_RESULT_DT` (`JOB_RSLT_CD`,`LOG_CRT_DT`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='사용자웹작업로그';

-- link_raw_data
CREATE TABLE IF NOT EXISTS `link_raw_data` (
  `LINK_RAW_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '연계원본일련번호',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `PROTCL_PROFILE_CD` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '프로토콜프로파일코드',
  `MSG_TYPE_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '메시지유형명',
  `TRSM_DRCT_NM` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '전송방향명',
  `HDR_LEN` int(10) unsigned DEFAULT NULL COMMENT '헤더길이',
  `MSG_BODY_CN` longtext COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '메시지본문내용',
  `SOU_IP_ADDR` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '원천IP주소',
  `SOU_PORT_NO` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '원천포트번호',
  `CLCT_DT` datetime NOT NULL COMMENT '수집일시',
  `SRC_EVNT_NO` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '원천이벤트번호',
  `DATA_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '데이터구분코드',
  `RAW_DATA` longtext COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '수신원본데이터',
  `CLCT_STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SCSESS' COMMENT '수집상태코드',
  `ERR_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '오류내용',
  PRIMARY KEY (`LINK_RAW_SN`),
  KEY `IX_LINK_RAW_SYS_DT` (`LINK_SYS_CD`,`CLCT_DT`),
  KEY `FK_LINK_RAW_PROFILE` (`PROTCL_PROFILE_CD`),
  KEY `IX_LINK_RAW_STTS_DT` (`CLCT_STTS_CD`,`CLCT_DT`),
  CONSTRAINT `FK_LINK_RAW_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`),
  CONSTRAINT `FK_LINK_RAW_PROFILE` FOREIGN KEY (`PROTCL_PROFILE_CD`) REFERENCES `protcl_profile_info` (`PROTCL_PROFILE_CD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='연계수신Raw데이터';

-- link_sys_chg_hstry
CREATE TABLE IF NOT EXISTS `link_sys_chg_hstry` (
  `LINK_SYS_CHG_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '연계시스템변경일련번호',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `CHG_ARTCL_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '변경항목명',
  `CHG_BFR_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '변경이전내용',
  `CHG_AFTR_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '변경이후내용',
  `CHG_RSN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '변경사유',
  `CHG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '변경일시',
  `CHNRG_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '변경자아이디',
  PRIMARY KEY (`LINK_SYS_CHG_SN`),
  KEY `IX_LINK_SYS_CHG` (`LINK_SYS_CD`,`CHG_DT`),
  CONSTRAINT `FK_LINK_SYS_CHG_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='연계시스템설정변경이력';

-- link_sys_info
CREATE TABLE IF NOT EXISTS `link_sys_info` (
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `LINK_SYS_NM` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템명',
  `SYS_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '시스템설명',
  `SRVR_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '서버명',
  `IP_ADDR` varchar(15) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'IP주소(IPv4)',
  `SRVR_PORT_NO` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '서버포트번호',
  `CNTN_MTH_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '접속방식명',
  `PROTCL_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '프로토콜코드',
  `PROTCL_PROFILE_CD` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '프로토콜프로파일코드',
  `PROTCL_CFMTN_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '프로토콜확정여부',
  `SW_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '소프트웨어명',
  `VER_NO` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '버전번호',
  `MDL_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '모델명',
  `MNFTR_NO` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '제조번호',
  `INSTL_YMD` date DEFAULT NULL COMMENT '설치일자',
  `BZENTY_SN` bigint(20) unsigned DEFAULT NULL COMMENT '연동업체일련번호',
  `STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NORMAL' COMMENT '상태코드',
  `LAST_LINK_RCPTN_DT` datetime DEFAULT NULL COMMENT '최종연계수신일시',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`LINK_SYS_CD`),
  KEY `IX_LINK_SYS_STTS` (`STTS_CD`,`USE_YN`),
  KEY `FK_LINK_SYS_BZENTY` (`BZENTY_SN`),
  KEY `FK_LINK_SYS_PROFILE` (`PROTCL_PROFILE_CD`),
  CONSTRAINT `FK_LINK_SYS_BZENTY` FOREIGN KEY (`BZENTY_SN`) REFERENCES `bzenty_info` (`BZENTY_SN`),
  CONSTRAINT `FK_LINK_SYS_PROFILE` FOREIGN KEY (`PROTCL_PROFILE_CD`) REFERENCES `protcl_profile_info` (`PROTCL_PROFILE_CD`),
  CONSTRAINT `CK_LINK_SYS_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='5종기운영연계시스템';

-- menu_info
CREATE TABLE IF NOT EXISTS `menu_info` (
  `MENU_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '메뉴일련번호',
  `UP_MENU_SN` bigint(20) unsigned DEFAULT NULL COMMENT '상위메뉴일련번호',
  `MENU_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '메뉴명',
  `MENU_URL_ADDR` varchar(2000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '메뉴URL주소',
  `MENU_ICON_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '메뉴아이콘명',
  `MENU_SEQ` int(10) unsigned NOT NULL DEFAULT 1 COMMENT '메뉴순서',
  `MENU_LV` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '1' COMMENT '메뉴레벨',
  `MENU_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '메뉴설명',
  `MENU_USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '메뉴사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`MENU_SN`),
  KEY `IX_MENU_UP` (`UP_MENU_SN`,`MENU_SEQ`),
  CONSTRAINT `FK_MENU_UP` FOREIGN KEY (`UP_MENU_SN`) REFERENCES `menu_info` (`MENU_SN`),
  CONSTRAINT `CK_MENU_USE_YN` CHECK (`MENU_USE_YN` in ('Y','N'))
) ENGINE=InnoDB AUTO_INCREMENT=24 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='메뉴';

-- pbx_info
CREATE TABLE IF NOT EXISTS `pbx_info` (
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `EQPM_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '설비명',
  `CMPNT_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '구성품명(원천항목)',
  `MTBF_HR` bigint(20) unsigned DEFAULT NULL COMMENT '평균고장간격시간(원천 MTBF)',
  `PIC_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '담당자명',
  `PIC_TELNO` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '담당자전화번호',
  `RMRK_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '비고내용',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  PRIMARY KEY (`EQPMNT_SN`),
  CONSTRAINT `FK_PBX_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='교환·직통·관제전화장비상세정보';

-- perf_day_stats
CREATE TABLE IF NOT EXISTS `perf_day_stats` (
  `STATS_YMD` date NOT NULL COMMENT '통계일자',
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `PERF_IDCT_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '성능지표코드',
  `AVG_VL` decimal(20,6) DEFAULT NULL COMMENT '평균값',
  `MIN_VL` decimal(20,6) DEFAULT NULL COMMENT '최솟값',
  `MAX_VL` decimal(20,6) DEFAULT NULL COMMENT '최댓값',
  `SUM_VL` decimal(30,6) DEFAULT NULL COMMENT '합계값',
  `CLCT_NOCS` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT '수집건수',
  `FAIL_NOCS` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT '실패건수',
  PRIMARY KEY (`STATS_YMD`,`EQPMNT_SN`,`PERF_IDCT_CD`),
  KEY `IX_PERF_DAY_EQPMNT` (`EQPMNT_SN`,`PERF_IDCT_CD`,`STATS_YMD`),
  CONSTRAINT `FK_PERF_DAY_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `FK_PERF_DAY_IDCT` FOREIGN KEY (`PERF_IDCT_CD`) REFERENCES `perf_idct_info` (`PERF_IDCT_CD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='성능일통계_3년보존';

-- perf_hr_stats
CREATE TABLE IF NOT EXISTS `perf_hr_stats` (
  `STATS_HR_DT` datetime NOT NULL COMMENT '통계시간일시',
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `PERF_IDCT_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '성능지표코드',
  `AVG_VL` decimal(20,6) DEFAULT NULL COMMENT '평균값',
  `MIN_VL` decimal(20,6) DEFAULT NULL COMMENT '최솟값',
  `MAX_VL` decimal(20,6) DEFAULT NULL COMMENT '최댓값',
  `SUM_VL` decimal(30,6) DEFAULT NULL COMMENT '합계값',
  `CLCT_NOCS` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT '수집건수',
  `FAIL_NOCS` bigint(20) unsigned NOT NULL DEFAULT 0 COMMENT '실패건수',
  PRIMARY KEY (`STATS_HR_DT`,`EQPMNT_SN`,`PERF_IDCT_CD`),
  KEY `IX_PERF_HR_EQPMNT` (`EQPMNT_SN`,`PERF_IDCT_CD`,`STATS_HR_DT`),
  CONSTRAINT `FK_PERF_HR_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `FK_PERF_HR_IDCT` FOREIGN KEY (`PERF_IDCT_CD`) REFERENCES `perf_idct_info` (`PERF_IDCT_CD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='성능1시간통계_1년보존';

-- perf_idct_info
CREATE TABLE IF NOT EXISTS `perf_idct_info` (
  `PERF_IDCT_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '성능지표코드',
  `PERF_IDCT_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '성능지표명',
  `DATA_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '데이터구분코드',
  `UNIT_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '단위명',
  `DATA_TYPE_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DECIMAL' COMMENT '데이터타입명',
  `PERF_IDCT_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '성능지표설명',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`PERF_IDCT_CD`),
  CONSTRAINT `CK_IDCT_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='성능지표정의';

-- perf_raw_data
CREATE TABLE IF NOT EXISTS `perf_raw_data` (
  `PERF_RAW_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '성능원본일련번호',
  `CLCT_DT` datetime NOT NULL COMMENT '수집일시',
  `EQPMNT_SN` bigint(20) unsigned NOT NULL COMMENT '장비일련번호',
  `EMS_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'EMS아이디',
  `SOU_EQPMNT_ID` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '원천장비아이디',
  `PERF_IDCT_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '성능지표코드',
  `MSRMT_VL` decimal(20,6) DEFAULT NULL COMMENT '측정값',
  `LTR_VL` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '문자값',
  `UNIT_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '단위명',
  `CLCT_STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SCSESS' COMMENT '수집상태코드',
  `SRC_EVNT_NO` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '원천이벤트번호',
  `LINK_RAW_SN` bigint(20) unsigned DEFAULT NULL COMMENT '연계원본일련번호',
  PRIMARY KEY (`CLCT_DT`,`PERF_RAW_SN`),
  KEY `IX_PERF_RAW_SN` (`PERF_RAW_SN`),
  KEY `IX_PERF_RAW_EQPMNT` (`EQPMNT_SN`,`PERF_IDCT_CD`,`CLCT_DT`),
  KEY `IX_PERF_RAW_STTS` (`CLCT_STTS_CD`,`CLCT_DT`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='성능Raw데이터_3개월보존';

-- protcl_msg_field_info
CREATE TABLE IF NOT EXISTS `protcl_msg_field_info` (
  `PROTCL_MSG_TYPE_SN` bigint(20) unsigned NOT NULL COMMENT '프로토콜메시지유형일련번호',
  `FIELD_SEQ` int(10) unsigned NOT NULL COMMENT '필드순서',
  `FIELD_NM` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '필드명',
  `DATA_TYPE_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '데이터타입명',
  `ESNTL_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '필수여부',
  `EXM_VL` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '예시값',
  `FIELD_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '필드설명',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`PROTCL_MSG_TYPE_SN`,`FIELD_SEQ`),
  CONSTRAINT `FK_PROTCL_FIELD_MSG` FOREIGN KEY (`PROTCL_MSG_TYPE_SN`) REFERENCES `protcl_msg_type_info` (`PROTCL_MSG_TYPE_SN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='프로토콜메시지Body항목';

-- protcl_msg_type_info
CREATE TABLE IF NOT EXISTS `protcl_msg_type_info` (
  `PROTCL_MSG_TYPE_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '프로토콜메시지유형일련번호',
  `PROTCL_PROFILE_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '프로토콜프로파일코드',
  `MSG_TYPE_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '메시지유형명',
  `TRSM_DRCT_NM` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '전송방향명',
  `TRSM_CYCLE_CN` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '전송주기내용',
  `MSG_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '메시지설명',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`PROTCL_MSG_TYPE_SN`),
  UNIQUE KEY `UK_PROTCL_MSG_TYPE` (`PROTCL_PROFILE_CD`,`MSG_TYPE_NM`),
  CONSTRAINT `FK_PROTCL_MSG_PROFILE` FOREIGN KEY (`PROTCL_PROFILE_CD`) REFERENCES `protcl_profile_info` (`PROTCL_PROFILE_CD`)
) ENGINE=InnoDB AUTO_INCREMENT=33 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='프로토콜메시지종류';

-- protcl_profile_info
CREATE TABLE IF NOT EXISTS `protcl_profile_info` (
  `PROTCL_PROFILE_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '프로토콜프로파일코드',
  `PROTCL_PROFILE_NM` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '프로토콜프로파일명',
  `PROTCL_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '프로토콜코드',
  `VER_NO` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '버전번호',
  `ENCODING_NM` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '인코딩명',
  `HDR_LEN` int(10) unsigned DEFAULT NULL COMMENT '헤더길이',
  `HDR_EXPLN` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '헤더설명',
  `ITEM_SE_NM` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '항목구분자명',
  `PORT_CN` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '포트내용',
  `RMRK_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '비고내용',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`PROTCL_PROFILE_CD`),
  CONSTRAINT `CK_PROTCL_PROFILE_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='프로토콜프로파일';

-- rptp_otpt_hstry
CREATE TABLE IF NOT EXISTS `rptp_otpt_hstry` (
  `RPTP_NO` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '보고서번호',
  `RPTP_NM` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '보고서명',
  `RPTP_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '보고서구분코드',
  `SRCH_CND_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '검색조건내용',
  `RPTP_FILE_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '보고서파일명',
  `RPTP_URL_ADDR` varchar(2000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '보고서URL주소',
  `RPTP_OTPT_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '보고서출력여부',
  `RPTP_WRT_YMD` date NOT NULL COMMENT '보고서작성일자',
  `OTPT_USER_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '출력사용자아이디',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`RPTP_NO`),
  KEY `IX_RPTP_WRT_YMD` (`RPTP_WRT_YMD`,`RPTP_SE_CD`),
  CONSTRAINT `CK_RPTP_OTPT_YN` CHECK (`RPTP_OTPT_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='보고서출력이력';

-- sms_group_info
CREATE TABLE IF NOT EXISTS `sms_group_info` (
  `SMS_GROUP_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'SMS그룹일련번호',
  `SMS_GROUP_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SMS그룹명',
  `DSBLTY_GRD_CD` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '전송대상장애등급코드',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '전송대상연계시스템코드',
  `TRSM_BGNG_TM` time DEFAULT NULL COMMENT '전송시작시각',
  `TRSM_END_TM` time DEFAULT NULL COMMENT '전송종료시각',
  `RTRSM_CYCLE_MIN` int(10) unsigned NOT NULL DEFAULT 0 COMMENT '재전송주기분수',
  `MAX_TRSM_NOCS` int(10) unsigned NOT NULL DEFAULT 1 COMMENT '최대전송건수',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`SMS_GROUP_SN`),
  UNIQUE KEY `UK_SMS_GROUP_NM` (`SMS_GROUP_NM`),
  KEY `FK_SMS_GROUP_SYS` (`LINK_SYS_CD`),
  CONSTRAINT `FK_SMS_GROUP_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`),
  CONSTRAINT `CK_SMS_GROUP_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SMS전송그룹';

-- sms_group_user_rel
CREATE TABLE IF NOT EXISTS `sms_group_user_rel` (
  `SMS_GROUP_SN` bigint(20) unsigned NOT NULL COMMENT 'SMS그룹일련번호',
  `USER_ID` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '사용자아이디',
  `SMS_RCPTN_TELNO` varchar(11) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SMS수신전화번호',
  `RCPTN_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '수신여부',
  PRIMARY KEY (`SMS_GROUP_SN`,`USER_ID`),
  KEY `FK_SMS_GROUP_USER_USER` (`USER_ID`),
  CONSTRAINT `FK_SMS_GROUP_USER_GROUP` FOREIGN KEY (`SMS_GROUP_SN`) REFERENCES `sms_group_info` (`SMS_GROUP_SN`),
  CONSTRAINT `FK_SMS_GROUP_USER_USER` FOREIGN KEY (`USER_ID`) REFERENCES `user_info` (`USER_ID`),
  CONSTRAINT `CK_SMS_GROUP_USER_YN` CHECK (`RCPTN_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SMS전송그룹사용자';

-- sms_trsm_hstry
CREATE TABLE IF NOT EXISTS `sms_trsm_hstry` (
  `SMS_TRSM_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT 'SMS전송일련번호',
  `SMS_GROUP_SN` bigint(20) unsigned DEFAULT NULL COMMENT 'SMS그룹일련번호',
  `DSBLTY_NO` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장애번호',
  `SMS_RCPTN_TELNO` varchar(11) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SMS수신전화번호',
  `SMS_CN` varchar(4000) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'SMS내용',
  `TRSM_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '전송일시',
  `TRSM_RSLT_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '전송결과코드',
  `FAIL_RSN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '실패사유',
  PRIMARY KEY (`SMS_TRSM_SN`),
  KEY `IX_SMS_TRSM_DT` (`TRSM_DT`,`TRSM_RSLT_CD`),
  KEY `FK_SMS_TRSM_GROUP` (`SMS_GROUP_SN`),
  KEY `FK_SMS_TRSM_DSBLTY` (`DSBLTY_NO`),
  CONSTRAINT `FK_SMS_TRSM_DSBLTY` FOREIGN KEY (`DSBLTY_NO`) REFERENCES `dsblty_info` (`DSBLTY_NO`),
  CONSTRAINT `FK_SMS_TRSM_GROUP` FOREIGN KEY (`SMS_GROUP_SN`) REFERENCES `sms_group_info` (`SMS_GROUP_SN`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='SMS전송이력';

-- srvr_log_link_info
CREATE TABLE IF NOT EXISTS `srvr_log_link_info` (
  `SRVR_LOG_LINK_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '서버로그연동일련번호',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `EQPMNT_SN` bigint(20) unsigned DEFAULT NULL COMMENT '장비일련번호',
  `EQPMNT_CLSF_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비분류명',
  `MKR_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '제조사명',
  `EQPMNT_MDL_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비모델명',
  `EQPMNT_QTY` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비수량',
  `OS_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '운영체제명',
  `EQPMNT_NM` varchar(300) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '장비명',
  `EQPMNT_GROUP_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비그룹명',
  `EQPMNT_IP_ADDR` varchar(45) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비IP주소',
  `LOG_LNKG_MTH_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '로그연동방식명',
  `LOG_FILE_PATH_NM` varchar(1000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '로그파일경로명',
  `LOG_FILE_NM` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '로그파일명',
  `RMRK_CN` text COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '비고내용',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`SRVR_LOG_LINK_SN`),
  KEY `IX_SRVR_LOG_LINK` (`LINK_SYS_CD`,`EQPMNT_NM`),
  KEY `FK_SRVR_LOG_EQPMNT` (`EQPMNT_SN`),
  CONSTRAINT `FK_SRVR_LOG_EQPMNT` FOREIGN KEY (`EQPMNT_SN`) REFERENCES `eqpmnt_info` (`EQPMNT_SN`),
  CONSTRAINT `FK_SRVR_LOG_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='서버로그연동정보';

-- stn_info
CREATE TABLE IF NOT EXISTS `stn_info` (
  `STN_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '역사코드',
  `STN_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '역사명',
  `RTE_NO` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AREX' COMMENT '노선번호',
  `RTE_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '공항철도' COMMENT '노선명',
  `RLWY_NO` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '선로번호',
  `STN_SEQ` int(10) unsigned NOT NULL COMMENT '역사순서',
  `MNLS_STN_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT '무인역사여부',
  `LAT` decimal(12,10) DEFAULT NULL COMMENT '위도',
  `LOT` decimal(13,10) DEFAULT NULL COMMENT '경도',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`STN_CD`),
  UNIQUE KEY `UK_STN_SEQ` (`RTE_NO`,`STN_SEQ`),
  CONSTRAINT `CK_STN_YN` CHECK (`MNLS_STN_YN` in ('Y','N') and `USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='공항철도역사';

-- sync_schdl_info
CREATE TABLE IF NOT EXISTS `sync_schdl_info` (
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `SYNC_DRCT_NM` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '동기화방향명',
  `SYNC_CYCLE_SEC` int(10) unsigned NOT NULL DEFAULT 86400 COMMENT '동기화주기초수',
  `EXCN_TM` time DEFAULT NULL COMMENT '실행시각',
  `STNG_FILE_APLY_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '설정파일적용여부',
  `RMRK_CN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '비고내용',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  PRIMARY KEY (`LINK_SYS_CD`,`SYNC_DRCT_NM`),
  CONSTRAINT `FK_SYNC_SCHDL_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='장애이력·조치이력동기화일정';

-- sys_health_stts
CREATE TABLE IF NOT EXISTS `sys_health_stts` (
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '연계시스템코드',
  `SRVR_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '서버명',
  `CPU_USGRT` decimal(5,2) DEFAULT NULL COMMENT 'CPU사용률',
  `MMRY_USGRT` decimal(5,2) DEFAULT NULL COMMENT '메모리사용률',
  `HDD_USGRT` decimal(5,2) DEFAULT NULL COMMENT '하드디스크사용률',
  `NETWK_IN_BPS` bigint(20) unsigned DEFAULT NULL COMMENT '네트워크수신초당비트수',
  `NETWK_OUT_BPS` bigint(20) unsigned DEFAULT NULL COMMENT '네트워크송신초당비트수',
  `STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NORMAL' COMMENT '상태코드',
  `CLCT_DT` datetime NOT NULL COMMENT '수집일시',
  PRIMARY KEY (`LINK_SYS_CD`,`SRVR_NM`),
  KEY `IX_SYS_HEALTH_STTS` (`STTS_CD`,`CLCT_DT`),
  CONSTRAINT `FK_SYS_HEALTH_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`),
  CONSTRAINT `CK_SYS_HEALTH_RATE` CHECK ((`CPU_USGRT` is null or `CPU_USGRT` between 0 and 100) and (`MMRY_USGRT` is null or `MMRY_USGRT` between 0 and 100) and (`HDD_USGRT` is null or `HDD_USGRT` between 0 and 100))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='연계시스템서버현재상태';

-- thrshld_info
CREATE TABLE IF NOT EXISTS `thrshld_info` (
  `THRSHLD_SN` bigint(20) unsigned NOT NULL AUTO_INCREMENT COMMENT '임계치일련번호',
  `LINK_SYS_CD` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '연계시스템코드(NULL=공통)',
  `EQPMNT_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '장비구분코드',
  `PERF_IDCT_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '성능지표코드',
  `CUTN_VL` decimal(20,6) DEFAULT NULL COMMENT '주의값',
  `WARN_VL` decimal(20,6) DEFAULT NULL COMMENT '경고값',
  `CRITICAL_VL` decimal(20,6) DEFAULT NULL COMMENT '심각값',
  `CMPR_OPRTR_CD` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'GE' COMMENT '비교연산자코드',
  `CONTN_SEC` int(10) unsigned NOT NULL DEFAULT 0 COMMENT '지속초수',
  `RSTR_VL` decimal(20,6) DEFAULT NULL COMMENT '복구값',
  `ALRM_USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '알람사용여부',
  `SMS_USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'N' COMMENT 'SMS사용여부',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`THRSHLD_SN`),
  UNIQUE KEY `UK_THRSHLD` (`LINK_SYS_CD`,`EQPMNT_SE_CD`,`PERF_IDCT_CD`),
  KEY `FK_THRSHLD_IDCT` (`PERF_IDCT_CD`),
  CONSTRAINT `FK_THRSHLD_IDCT` FOREIGN KEY (`PERF_IDCT_CD`) REFERENCES `perf_idct_info` (`PERF_IDCT_CD`),
  CONSTRAINT `FK_THRSHLD_SYS` FOREIGN KEY (`LINK_SYS_CD`) REFERENCES `link_sys_info` (`LINK_SYS_CD`),
  CONSTRAINT `CK_THRSHLD_YN` CHECK (`ALRM_USE_YN` in ('Y','N') and `SMS_USE_YN` in ('Y','N') and `USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='다단계임계치';

-- ui_stng_info
CREATE TABLE IF NOT EXISTS `ui_stng_info` (
  `UI_STNG_CD` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'UI설정코드',
  `UI_STNG_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'UI설정명',
  `UI_STNG_VL` varchar(4000) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'UI설정값',
  `UI_STNG_EXPLN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'UI설정설명',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`UI_STNG_CD`),
  CONSTRAINT `CK_UI_STNG_USE_YN` CHECK (`USE_YN` in ('Y','N'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='UI설정';

-- user_acnt_aply_info
CREATE TABLE IF NOT EXISTS `user_acnt_aply_info` (
  `APLY_NO` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '신청번호',
  `USER_ID` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '사용자아이디',
  `USER_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '사용자명',
  `USER_ENPSWD` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '사용자암호화비밀번호',
  `USER_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '사용자구분코드',
  `OGDP_BZENTY_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '소속업체명',
  `DEPT_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '부서명',
  `MBL_TELNO` varchar(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '휴대전화번호',
  `TELNO` varchar(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '전화번호',
  `EML_ADDR` varchar(320) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '이메일주소',
  `DMND_AUTHRT_CD` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '요청권한코드',
  `APLY_RSN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '신청사유',
  `APLY_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '신청일시',
  `APLY_STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'WAITING' COMMENT '신청상태코드',
  `APRV_USER_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '승인사용자아이디',
  `APRV_DT` datetime DEFAULT NULL COMMENT '승인일시',
  `RFSL_RSN` varchar(4000) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '거절사유',
  PRIMARY KEY (`APLY_NO`),
  KEY `IX_USER_APLY_STTS_DT` (`APLY_STTS_CD`,`APLY_DT`),
  KEY `IX_USER_APLY_AUTHRT` (`DMND_AUTHRT_CD`),
  KEY `IX_USER_APLY_APRV_USER` (`APRV_USER_ID`),
  CONSTRAINT `FK_USER_APLY_AUTHRT` FOREIGN KEY (`DMND_AUTHRT_CD`) REFERENCES `authrt_info` (`AUTHRT_CD`),
  CONSTRAINT `FK_USER_APLY_APRV_USER` FOREIGN KEY (`APRV_USER_ID`) REFERENCES `user_info` (`USER_ID`),
  CONSTRAINT `CK_USER_APLY_SE_CD` CHECK (`USER_SE_CD` in ('INTERNAL','EXTERNAL')),
  CONSTRAINT `CK_USER_APLY_STTS_CD` CHECK (`APLY_STTS_CD` in ('WAITING','APPROVED','REJECTED'))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='사용자계정신청';

-- user_info
CREATE TABLE IF NOT EXISTS `user_info` (
  `USER_ID` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '사용자아이디',
  `USER_NM` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '사용자명',
  `USER_ENPSWD` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT '사용자암호화비밀번호',
  `AUTHRT_CD` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '권한코드',
  `USER_SE_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INTERNAL' COMMENT '사용자구분코드',
  `OGDP_BZENTY_NM` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '소속업체명',
  `DEPT_NM` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '부서명',
  `MBL_TELNO` varchar(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '휴대전화번호',
  `TELNO` varchar(11) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '전화번호',
  `EML_ADDR` varchar(320) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '이메일주소',
  `USER_STTS_CD` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'NORMAL' COMMENT '사용자상태코드',
  `PSWD_EXPRY_YMD` date DEFAULT NULL COMMENT '비밀번호만료일자',
  `LAST_LGN_DT` datetime DEFAULT NULL COMMENT '최종로그인일시',
  `LGN_FAIL_NOCS` int(10) unsigned NOT NULL DEFAULT 0 COMMENT '로그인실패건수',
  `USE_YN` char(1) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'Y' COMMENT '사용여부',
  `REG_DT` datetime NOT NULL DEFAULT current_timestamp() COMMENT '등록일시',
  `RGTR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '등록자아이디',
  `MDFCN_DT` datetime DEFAULT NULL COMMENT '수정일시',
  `MDFR_ID` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT '수정자아이디',
  PRIMARY KEY (`USER_ID`),
  KEY `IX_USER_NM` (`USER_NM`),
  KEY `IX_USER_AUTHRT` (`AUTHRT_CD`),
  CONSTRAINT `FK_USER_AUTHRT` FOREIGN KEY (`AUTHRT_CD`) REFERENCES `authrt_info` (`AUTHRT_CD`),
  CONSTRAINT `CK_USER_USE_YN` CHECK (`USE_YN` in ('Y','N')),
  CONSTRAINT `CK_USER_SE_CD` CHECK (`USER_SE_CD` in ('INTERNAL','EXTERNAL')),
  CONSTRAINT `CK_USER_STTS_CD` CHECK (`USER_STTS_CD` in ('NORMAL','LOCKED','SUSPENDED','DELETED')),
  CONSTRAINT `CK_USER_AUTHRT` CHECK (`USE_YN` = 'N' OR `AUTHRT_CD` IS NOT NULL)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='TNMS사용자';

DROP VIEW IF EXISTS `vw_dashboard_dsblty_summary`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vw_dashboard_dsblty_summary` AS SELECT
    DSBLTY_GRD_CD,
    COUNT(*) AS DSBLTY_NOCS,
    SUM(CASE WHEN PRCS_STTS_CD = 'UNCONFIRMED' THEN 1 ELSE 0 END) AS UNCONFIRMED_NOCS
FROM dsblty_info
WHERE DSBLTY_END_DT IS NULL
  AND EXCP_APLY_YN = 'N'
GROUP BY DSBLTY_GRD_CD ;

DROP VIEW IF EXISTS `vw_dashboard_sys_stts`;
CREATE ALGORITHM=UNDEFINED SQL SECURITY DEFINER VIEW `vw_dashboard_sys_stts` AS SELECT
    S.LINK_SYS_CD,
    S.LINK_SYS_NM,
    S.STTS_CD,
    S.LAST_LINK_RCPTN_DT,
    COUNT(E.EQPMNT_SN) AS EQPMNT_NOCS,
    SUM(CASE WHEN C.STTS_CD = 'NORMAL' THEN 1 ELSE 0 END) AS NORMAL_NOCS,
    SUM(CASE WHEN C.STTS_CD IN ('CAUTION','WARNING') THEN 1 ELSE 0 END) AS WARNING_NOCS,
    SUM(CASE WHEN C.STTS_CD = 'CRITICAL' THEN 1 ELSE 0 END) AS CRITICAL_NOCS
FROM link_sys_info S
LEFT JOIN eqpmnt_info E ON E.LINK_SYS_CD = S.LINK_SYS_CD AND E.USE_YN = 'Y'
LEFT JOIN eqpmnt_stts C ON C.EQPMNT_SN = E.EQPMNT_SN
WHERE S.USE_YN = 'Y'
GROUP BY S.LINK_SYS_CD, S.LINK_SYS_NM, S.STTS_CD, S.LAST_LINK_RCPTN_DT ;

/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
