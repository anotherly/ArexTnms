/*
 * AREX TNMS 운영관리시스템 MariaDB DDL v0.2
 * 대상 DBMS : MariaDB 10.6 이상 권장
 * 데이터베이스명 : AREX_TNMS
 * 문자셋 : utf8mb4
 *
 * 설계 근거
 *  - TNMS_과업내역_v1.0.xlsx 중 4. 운영관리 시스템(4-1~4-10)
 *  - 02.시스템 메뉴얼_TNMS SW 매뉴얼_발췌_v1.0.pdf 5~17쪽
 *  - 2026-07-22 내부회의, 2026-07-30 공항철도 회의 메모
 *  - 공공데이터 공통표준(2025.11월).xlsx
 *
 * 화면별 주요 테이블
 *  01 통합 대시보드       : link_sys_info, sys_health_stts, eqpmnt_stts,
 *                           eqpmnt_perf_stts, dsblty_info, stn_info
 *  02 역사·선로 현황      : stn_info, eqpmnt_info, eqpmnt_stts, dsblty_info
 *  03 연동시스템 관리      : link_sys_info, bzenty_info, link_sys_chg_hist
 *  04 장비 관리            : eqpmnt_info, eqpmnt_cfg_hist, eqpmnt_sync_hist
 *  05 교환기 관리          : eqpmnt_info, sys_health_stts, eqpmnt_perf_stts,
 *                           perf_raw_data, dsblty_info
 *  06 CCTV 상태관리        : cctv_info, eqpmnt_info, eqpmnt_stts, dsblty_info
 *  07 CCTV 영상관리        : cctv_info, cctv_chnl_info
 *  08 SCADA 출입보안       : acss_evnt_hist, eqpmnt_info, eqpmnt_stts
 *  09 연동주기 관리        : clct_cycle_info, clct_excn_hist
 *  10 임계치 관리          : perf_metric_info, thrshld_info
 *  11 성능관리             : eqpmnt_perf_stts, perf_raw_data, perf_hr_stats,
 *                           perf_day_stats
 *  12 Raw 데이터 관리      : link_raw_data, perf_raw_data, perf_hr_stats,
 *                           perf_day_stats
 *  13 실시간 장애          : dsblty_info, dsblty_actn_hist, dsblty_type_info
 *  14 장애이력·조치        : dsblty_info, dsblty_actn_hist
 *  15 장애 예외설정        : dsblty_excp_group_info, dsblty_excp_group_eqpmnt_rel,
 *                           dsblty_excp_schdl_info
 *  16 장애유형 관리        : dsblty_type_info
 *  17 장애·성능 보고서     : dsblty_info, perf_hr_stats, perf_day_stats,
 *                           rptp_otpt_hist
 *  18 사용자 계정 설정     : user_info, user_authrt_rel
 *  19 권한 관리            : authrt_info, menu_info, authrt_menu_rel
 *  20 계정 신청 현황       : user_acnt_aply_info
 *  21 알림·SMS 설정        : sms_group_info, sms_group_user_rel, sms_trsm_hist
 *  22 공통코드·UI 설정     : com_cd_group_info, com_cd_info, ui_stng_info
 *  23 작업로그 조회        : job_log, cntn_log
 *
 * 공통표준 적용 원칙
 *  - DB명으로 시스템 영역을 식별하므로 테이블명에는 TNMS 접두어를 사용하지 않는다.
 *  - 기준정보·마스터는 _INFO, 변경·처리 기록은 _HIST, 다대다 연결은 _REL,
 *    현재 상태는 _STTS, 집계는 _STATS, 원천 전문은 _RAW_DATA, 로그는 _LOG를 사용한다.
 *  - 공통표준용어에 정확히 존재하는 컬럼은 영문약어·길이를 그대로 적용하였다.
 *    예: USER_ID V20, USER_NM V100, CCTV_UNQ_NO V50, CPU_USGRT N5,2,
 *        MMRY_USGRT N5,2, CLCT_DT DATETIME, REG_DT DATETIME, MDFCN_DT DATETIME.
 *  - TNMS 고유 용어(역사, 장비상태코드, 수집주기초수, 지표코드 등)는
 *    공통표준단어의 영문약어를 조합한 기관 표준용어 후보이다.
 */

CREATE DATABASE IF NOT EXISTS `AREX_TNMS`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `AREX_TNMS`;

/* =========================================================
 * 1. 공통코드·메뉴·권한·사용자
 * ========================================================= */

CREATE TABLE IF NOT EXISTS com_cd_group_info (
    COM_CD_GROUP_ID        VARCHAR(20)  NOT NULL COMMENT '공통코드그룹아이디',
    COM_CD_GROUP_NM        VARCHAR(100) NOT NULL COMMENT '공통코드그룹명(공통표준)',
    COM_CD_GROUP_EXPLN     VARCHAR(4000) NULL COMMENT '공통코드그룹설명(공통표준)',
    COM_CD_LEN             INT UNSIGNED NULL COMMENT '공통코드길이(공통표준)',
    USE_YN                 CHAR(1)      NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME     NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (COM_CD_GROUP_ID),
    CONSTRAINT CK_COM_CD_GROUP_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='공통코드그룹';

CREATE TABLE IF NOT EXISTS com_cd_info (
    COM_CD_GROUP_ID        VARCHAR(20)  NOT NULL COMMENT '공통코드그룹아이디',
    COM_CD                 VARCHAR(30)  NOT NULL COMMENT '공통코드',
    COM_CD_NM              VARCHAR(100) NOT NULL COMMENT '공통코드명(공통표준)',
    COM_CD_EXPLN           VARCHAR(4000) NULL COMMENT '공통코드설명(공통표준)',
    COM_CD_SEQ             INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '공통코드순서',
    COM_CD_USE_YN          CHAR(1)      NOT NULL DEFAULT 'Y' COMMENT '공통코드사용여부(공통표준)',
    EXT1_CN                VARCHAR(4000) NULL COMMENT '확장1내용',
    EXT2_CN                VARCHAR(4000) NULL COMMENT '확장2내용',
    REG_DT                 DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME     NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (COM_CD_GROUP_ID, COM_CD),
    CONSTRAINT FK_COM_CD_GROUP FOREIGN KEY (COM_CD_GROUP_ID)
        REFERENCES com_cd_group_info (COM_CD_GROUP_ID),
    CONSTRAINT CK_COM_CD_USE_YN CHECK (COM_CD_USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='공통상세코드';

CREATE TABLE IF NOT EXISTS menu_info (
    MENU_SN                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '메뉴일련번호',
    UP_MENU_SN             BIGINT UNSIGNED NULL COMMENT '상위메뉴일련번호',
    MENU_NM                VARCHAR(100) NOT NULL COMMENT '메뉴명(공통표준)',
    MENU_URL_ADDR          VARCHAR(2000) NULL COMMENT '메뉴URL주소(공통표준)',
    MENU_ICON_NM           VARCHAR(300) NULL COMMENT '메뉴아이콘명(공통표준)',
    MENU_SEQ               INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '메뉴순서(공통표준)',
    MENU_LV                VARCHAR(10) NOT NULL DEFAULT '1' COMMENT '메뉴레벨(공통표준)',
    MENU_EXPLN             VARCHAR(4000) NULL COMMENT '메뉴설명(공통표준)',
    MENU_USE_YN            CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '메뉴사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (MENU_SN),
    KEY IX_MENU_UP (UP_MENU_SN, MENU_SEQ),
    CONSTRAINT FK_MENU_UP FOREIGN KEY (UP_MENU_SN) REFERENCES menu_info (MENU_SN),
    CONSTRAINT CK_MENU_USE_YN CHECK (MENU_USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='메뉴';

CREATE TABLE IF NOT EXISTS authrt_info (
    AUTHRT_SN              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '권한일련번호',
    AUTHRT_NM              VARCHAR(100) NOT NULL COMMENT '권한명(공통표준)',
    AUTHRT_EXPLN           VARCHAR(4000) NULL COMMENT '권한설명',
    AUTHRT_STTS_NM         VARCHAR(300) NOT NULL DEFAULT '사용' COMMENT '권한상태명(공통표준)',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (AUTHRT_SN),
    UNIQUE KEY UK_AUTHRT_NM (AUTHRT_NM),
    CONSTRAINT CK_AUTHRT_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='권한';

CREATE TABLE IF NOT EXISTS authrt_menu_rel (
    AUTHRT_SN              BIGINT UNSIGNED NOT NULL COMMENT '권한일련번호',
    MENU_SN                BIGINT UNSIGNED NOT NULL COMMENT '메뉴일련번호',
    LIST_AUTHRT_YN         CHAR(1) NOT NULL DEFAULT 'N' COMMENT '목록권한여부',
    DTL_AUTHRT_YN          CHAR(1) NOT NULL DEFAULT 'N' COMMENT '상세권한여부',
    REG_AUTHRT_YN          CHAR(1) NOT NULL DEFAULT 'N' COMMENT '등록권한여부',
    MDFCN_AUTHRT_YN        CHAR(1) NOT NULL DEFAULT 'N' COMMENT '수정권한여부',
    DEL_AUTHRT_YN          CHAR(1) NOT NULL DEFAULT 'N' COMMENT '삭제권한여부(공통표준 조합)',
    CTRL_AUTHRT_YN         CHAR(1) NOT NULL DEFAULT 'N' COMMENT '제어권한여부',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    PRIMARY KEY (AUTHRT_SN, MENU_SN),
    CONSTRAINT FK_AUTHRT_MENU_AUTHRT FOREIGN KEY (AUTHRT_SN) REFERENCES authrt_info (AUTHRT_SN),
    CONSTRAINT FK_AUTHRT_MENU_MENU FOREIGN KEY (MENU_SN) REFERENCES menu_info (MENU_SN),
    CONSTRAINT CK_AUTHRT_MENU_YN CHECK (
      LIST_AUTHRT_YN IN ('Y','N') AND DTL_AUTHRT_YN IN ('Y','N') AND
      REG_AUTHRT_YN IN ('Y','N') AND MDFCN_AUTHRT_YN IN ('Y','N') AND
      DEL_AUTHRT_YN IN ('Y','N') AND CTRL_AUTHRT_YN IN ('Y','N')
    )
) ENGINE=InnoDB COMMENT='권한별메뉴기능';

CREATE TABLE IF NOT EXISTS user_info (
    USER_SN                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '사용자일련번호',
    USER_ID                VARCHAR(20) NOT NULL COMMENT '사용자아이디(공통표준)',
    USER_NM                VARCHAR(100) NOT NULL COMMENT '사용자명(공통표준)',
    USER_ENPSWD            VARCHAR(256) NOT NULL COMMENT '사용자암호화비밀번호',
    OGDP_BZENTY_NM         VARCHAR(100) NULL COMMENT '소속업체명(공통표준)',
    DEPT_NM                VARCHAR(200) NULL COMMENT '부서명(공통표준)',
    TELNO                  VARCHAR(11) NULL COMMENT '전화번호(공통표준)',
    EML_ADDR               VARCHAR(320) NULL COMMENT '이메일주소',
    USER_STTS_NM           VARCHAR(300) NOT NULL DEFAULT '정상' COMMENT '사용자상태명(공통표준)',
    PSWD_EXPRY_YMD         DATE NULL COMMENT '비밀번호만료일자(공통표준)',
    LAST_LGN_DT            DATETIME NULL COMMENT '최종로그인일시',
    LGN_FAIL_NOCS          INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '로그인실패건수',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (USER_SN),
    UNIQUE KEY UK_USER_ID (USER_ID),
    KEY IX_USER_NM (USER_NM),
    CONSTRAINT CK_USER_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='TNMS사용자';

CREATE TABLE IF NOT EXISTS user_authrt_rel (
    USER_SN                BIGINT UNSIGNED NOT NULL COMMENT '사용자일련번호',
    AUTHRT_SN              BIGINT UNSIGNED NOT NULL COMMENT '권한일련번호',
    AUTHRT_BGNG_DT         DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '권한시작일시',
    AUTHRT_END_DT          DATETIME NULL COMMENT '권한종료일시',
    PRIMARY KEY (USER_SN, AUTHRT_SN),
    CONSTRAINT FK_USER_AUTHRT_USER FOREIGN KEY (USER_SN) REFERENCES user_info (USER_SN),
    CONSTRAINT FK_USER_AUTHRT_AUTHRT FOREIGN KEY (AUTHRT_SN) REFERENCES authrt_info (AUTHRT_SN)
) ENGINE=InnoDB COMMENT='사용자권한';

CREATE TABLE IF NOT EXISTS user_acnt_aply_info (
    APLY_SN                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '신청일련번호',
    APLY_NO                VARCHAR(50) NOT NULL COMMENT '신청번호',
    USER_ID                VARCHAR(20) NOT NULL COMMENT '사용자아이디(공통표준)',
    USER_NM                VARCHAR(100) NOT NULL COMMENT '사용자명(공통표준)',
    OGDP_BZENTY_NM         VARCHAR(100) NULL COMMENT '소속업체명(공통표준)',
    DEPT_NM                VARCHAR(200) NULL COMMENT '부서명(공통표준)',
    TELNO                  VARCHAR(11) NULL COMMENT '전화번호(공통표준)',
    EML_ADDR               VARCHAR(320) NULL COMMENT '이메일주소',
    DMND_AUTHRT_NM         VARCHAR(100) NOT NULL COMMENT '요청권한명',
    APLY_RSN               VARCHAR(4000) NULL COMMENT '신청사유',
    APLY_DT                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '신청일시',
    APLY_STTS_NM           VARCHAR(300) NOT NULL DEFAULT '승인대기' COMMENT '신청상태명(공통표준)',
    APRV_USER_SN           BIGINT UNSIGNED NULL COMMENT '승인사용자일련번호',
    APRV_DT                DATETIME NULL COMMENT '승인일시',
    RFSL_RSN               VARCHAR(4000) NULL COMMENT '거절사유(공통표준)',
    PRIMARY KEY (APLY_SN),
    UNIQUE KEY UK_USER_APLY_NO (APLY_NO),
    KEY IX_USER_APLY_STTS_DT (APLY_STTS_NM, APLY_DT)
) ENGINE=InnoDB COMMENT='사용자계정신청';

/* =========================================================
 * 2. 역사·연동시스템·업체·장비
 * ========================================================= */

CREATE TABLE IF NOT EXISTS stn_info (
    STN_SN                 BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '역사일련번호',
    STN_CD                 VARCHAR(20) NOT NULL COMMENT '역사코드',
    STN_NM                 VARCHAR(100) NOT NULL COMMENT '역사명',
    RTE_NO                 VARCHAR(50) NOT NULL DEFAULT 'AREX' COMMENT '노선번호(공통표준)',
    RTE_NM                 VARCHAR(100) NOT NULL DEFAULT '공항철도' COMMENT '노선명(공통표준)',
    RLWY_NO                VARCHAR(50) NULL COMMENT '선로번호(공통표준)',
    STN_SEQ                INT UNSIGNED NOT NULL COMMENT '역사순서',
    MNLS_STN_YN            CHAR(1) NOT NULL DEFAULT 'N' COMMENT '무인역사여부',
    LAT                    DECIMAL(12,10) NULL COMMENT '위도(공통표준)',
    LOT                    DECIMAL(13,10) NULL COMMENT '경도(공통표준)',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (STN_SN),
    UNIQUE KEY UK_STN_CD (STN_CD),
    UNIQUE KEY UK_STN_SEQ (RTE_NO, STN_SEQ),
    CONSTRAINT CK_STN_YN CHECK (MNLS_STN_YN IN ('Y','N') AND USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='공항철도역사';

CREATE TABLE IF NOT EXISTS bzenty_info (
    BZENTY_SN              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '업체일련번호',
    BZENTY_NM              VARCHAR(100) NOT NULL COMMENT '사업체명(공통표준)',
    BRNO                   CHAR(10) NULL COMMENT '사업자등록번호(공통표준)',
    BZENTY_SE_CD           VARCHAR(20) NOT NULL COMMENT '업체구분코드',
    PIC_NM                 VARCHAR(100) NULL COMMENT '담당자명(공통표준)',
    PIC_TELNO              VARCHAR(11) NULL COMMENT '담당자전화번호(공통표준)',
    PIC_EML_ADDR           VARCHAR(320) NULL COMMENT '담당자이메일주소',
    ADDR                   VARCHAR(200) NULL COMMENT '주소(공통표준)',
    DADDR                  VARCHAR(200) NULL COMMENT '상세주소(공통표준)',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (BZENTY_SN),
    KEY IX_BZENTY_NM (BZENTY_NM),
    CONSTRAINT CK_BZENTY_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='납품·연동·유지보수업체';

CREATE TABLE IF NOT EXISTS link_sys_info (
    LINK_SYS_SN            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '연계시스템일련번호',
    LINK_SYS_CD            VARCHAR(20) NOT NULL COMMENT '연계시스템코드',
    LINK_SYS_NM            VARCHAR(200) NOT NULL COMMENT '연계시스템명(공통표준)',
    SYS_EXPLN              VARCHAR(4000) NULL COMMENT '시스템설명',
    SRVR_NM                VARCHAR(100) NULL COMMENT '서버명(공통표준)',
    IP_ADDR                VARCHAR(15) NULL COMMENT 'IP주소(공통표준, IPv4)',
    SRVR_PORT_NO           VARCHAR(10) NULL COMMENT '서버포트번호(공통표준)',
    CNTN_MTH_NM            VARCHAR(200) NULL COMMENT '접속방식명(공통표준)',
    PROTCL_CD              VARCHAR(20) NOT NULL COMMENT '프로토콜코드',
    SW_NM                  VARCHAR(300) NULL COMMENT '소프트웨어명(공통표준)',
    VER_NO                 VARCHAR(50) NULL COMMENT '버전번호(공통표준)',
    MDL_NM                 VARCHAR(100) NULL COMMENT '모델명(공통표준)',
    MNFTR_NO               VARCHAR(50) NULL COMMENT '제조번호(공통표준)',
    INSTL_YMD              DATE NULL COMMENT '설치일자(공통표준)',
    BZENTY_SN              BIGINT UNSIGNED NULL COMMENT '연동업체일련번호',
    STTS_CD                VARCHAR(20) NOT NULL DEFAULT 'NORMAL' COMMENT '상태코드',
    LAST_LINK_RCPTN_DT     DATETIME NULL COMMENT '최종연계수신일시',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (LINK_SYS_SN),
    UNIQUE KEY UK_LINK_SYS_CD (LINK_SYS_CD),
    KEY IX_LINK_SYS_STTS (STTS_CD, USE_YN),
    CONSTRAINT FK_LINK_SYS_BZENTY FOREIGN KEY (BZENTY_SN) REFERENCES bzenty_info (BZENTY_SN),
    CONSTRAINT CK_LINK_SYS_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='5종기운영연계시스템';

CREATE TABLE IF NOT EXISTS link_sys_chg_hist (
    LINK_SYS_CHG_SN        BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '연계시스템변경일련번호',
    LINK_SYS_SN            BIGINT UNSIGNED NOT NULL COMMENT '연계시스템일련번호',
    CHG_ARTCL_NM           VARCHAR(100) NOT NULL COMMENT '변경항목명',
    CHG_BFR_CN             VARCHAR(4000) NULL COMMENT '변경이전내용',
    CHG_AFTR_CN            VARCHAR(4000) NULL COMMENT '변경이후내용',
    CHG_RSN                VARCHAR(4000) NULL COMMENT '변경사유(공통표준)',
    CHG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '변경일시',
    CHGR_SN                BIGINT UNSIGNED NULL COMMENT '변경자일련번호',
    PRIMARY KEY (LINK_SYS_CHG_SN),
    KEY IX_LINK_SYS_CHG (LINK_SYS_SN, CHG_DT),
    CONSTRAINT FK_LINK_SYS_CHG_SYS FOREIGN KEY (LINK_SYS_SN) REFERENCES link_sys_info (LINK_SYS_SN)
) ENGINE=InnoDB COMMENT='연계시스템설정변경이력';

CREATE TABLE IF NOT EXISTS eqpmnt_info (
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '장비일련번호(공통표준)',
    EQPMNT_MNG_NO          VARCHAR(50) NOT NULL COMMENT '장비관리번호(공통표준)',
    EQPMNT_NM              VARCHAR(100) NOT NULL COMMENT '장비명(공통표준)',
    EQPMNT_SE_CD           VARCHAR(20) NOT NULL COMMENT '장비구분코드',
    EQPMNT_CLSF_NM         VARCHAR(100) NULL COMMENT '장비분류명(공통표준)',
    LINK_SYS_SN            BIGINT UNSIGNED NOT NULL COMMENT '연계시스템일련번호',
    STN_SN                 BIGINT UNSIGNED NULL COMMENT '역사일련번호',
    INSTL_PLC_NM           VARCHAR(300) NULL COMMENT '설치장소명',
    EQPMNT_IP_ADDR         VARCHAR(15) NULL COMMENT '장비IP주소(공통표준, IPv4)',
    MAC_ADDR               VARCHAR(17) NULL COMMENT 'MAC주소(공통표준)',
    SRVR_PORT_NO           VARCHAR(10) NULL COMMENT '서버포트번호(공통표준)',
    EQPMNT_MDL_NM          VARCHAR(100) NULL COMMENT '장비모델명(공통표준)',
    SW_NM                  VARCHAR(300) NULL COMMENT '소프트웨어명(공통표준)',
    VER_NO                 VARCHAR(50) NULL COMMENT '버전번호(공통표준)',
    MNFTR_NO               VARCHAR(50) NULL COMMENT '제조번호(공통표준)',
    MKR_NM                 VARCHAR(100) NULL COMMENT '제조사명(공통표준)',
    INSTL_YMD              DATE NULL COMMENT '설치일자(공통표준)',
    EXPT_END_YMD           DATE NULL COMMENT '예상종료일자',
    BZENTY_SN              BIGINT UNSIGNED NULL COMMENT '납품·유지보수업체일련번호',
    PING_MNTRG_YN          CHAR(1) NOT NULL DEFAULT 'Y' COMMENT 'PING모니터링여부',
    PING_CYCLE_SEC         INT UNSIGNED NOT NULL DEFAULT 30 COMMENT 'PING주기초수',
    EQPMNT_EXPLN           VARCHAR(4000) NULL COMMENT '장비설명(공통표준)',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (EQPMNT_SN),
    UNIQUE KEY UK_EQPMNT_MNG_NO (EQPMNT_MNG_NO),
    KEY IX_EQPMNT_SYS_STN (LINK_SYS_SN, STN_SN, EQPMNT_SE_CD),
    KEY IX_EQPMNT_IP (EQPMNT_IP_ADDR),
    CONSTRAINT FK_EQPMNT_LINK_SYS FOREIGN KEY (LINK_SYS_SN) REFERENCES link_sys_info (LINK_SYS_SN),
    CONSTRAINT FK_EQPMNT_STN FOREIGN KEY (STN_SN) REFERENCES stn_info (STN_SN),
    CONSTRAINT FK_EQPMNT_BZENTY FOREIGN KEY (BZENTY_SN) REFERENCES bzenty_info (BZENTY_SN),
    CONSTRAINT CK_EQPMNT_YN CHECK (PING_MNTRG_YN IN ('Y','N') AND USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='통합관리장비';

CREATE TABLE IF NOT EXISTS eqpmnt_cfg_hist (
    EQPMNT_CFG_HIST_SN     BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '장비설정이력일련번호',
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL COMMENT '장비일련번호',
    CFG_VER_NO             VARCHAR(50) NULL COMMENT '설정버전번호',
    CFG_FILE_NM            VARCHAR(300) NULL COMMENT '설정파일명',
    CFG_FILE_PATH_NM       VARCHAR(300) NULL COMMENT '설정파일경로명',
    CHG_ARTCL_NM           VARCHAR(100) NULL COMMENT '변경항목명',
    CHG_BFR_CN             VARCHAR(4000) NULL COMMENT '변경이전내용',
    CHG_AFTR_CN            VARCHAR(4000) NULL COMMENT '변경이후내용',
    CHG_RSN                VARCHAR(4000) NULL COMMENT '변경사유(공통표준)',
    BKUP_DT                DATETIME NULL COMMENT '백업일시',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    PRIMARY KEY (EQPMNT_CFG_HIST_SN),
    KEY IX_EQPMNT_CFG_HIST (EQPMNT_SN, REG_DT),
    CONSTRAINT FK_EQPMNT_CFG_EQPMNT FOREIGN KEY (EQPMNT_SN) REFERENCES eqpmnt_info (EQPMNT_SN)
) ENGINE=InnoDB COMMENT='장비설정및백업이력';

CREATE TABLE IF NOT EXISTS eqpmnt_sync_hist (
    SYNC_HIST_SN           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '동기화이력일련번호',
    LINK_SYS_SN            BIGINT UNSIGNED NOT NULL COMMENT '연계시스템일련번호',
    SYNC_BGNG_DT           DATETIME NOT NULL COMMENT '동기화시작일시',
    SYNC_END_DT            DATETIME NULL COMMENT '동기화종료일시',
    ADD_NOCS               INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '추가건수',
    MDFCN_NOCS             INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '수정건수',
    DEL_NOCS               INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '삭제건수(공통표준)',
    FAIL_NOCS              INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '실패건수',
    STTS_CD                VARCHAR(20) NOT NULL COMMENT '상태코드',
    ERR_CN                 VARCHAR(4000) NULL COMMENT '오류내용',
    PRIMARY KEY (SYNC_HIST_SN),
    KEY IX_SYNC_HIST_SYS_DT (LINK_SYS_SN, SYNC_BGNG_DT),
    CONSTRAINT FK_SYNC_HIST_SYS FOREIGN KEY (LINK_SYS_SN) REFERENCES link_sys_info (LINK_SYS_SN)
) ENGINE=InnoDB COMMENT='장비구성동기화현황';

CREATE TABLE IF NOT EXISTS cctv_info (
    CCTV_SN                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'CCTV일련번호',
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL COMMENT '장비일련번호',
    CCTV_UNQ_NO            VARCHAR(50) NOT NULL COMMENT 'CCTV고유번호(공통표준)',
    CCTV_NM                VARCHAR(100) NOT NULL COMMENT 'CCTV명(공통표준)',
    CHNL_CNT               INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '채널수(공통표준)',
    VDO_URL_ADDR           VARCHAR(2000) NULL COMMENT '동영상URL주소(공통표준)',
    PTZ_USE_YN             CHAR(1) NOT NULL DEFAULT 'N' COMMENT 'PTZ사용여부',
    VDO_STTS_CD            VARCHAR(20) NOT NULL DEFAULT 'NORMAL' COMMENT '영상상태코드',
    LAST_FRAME_DT          DATETIME NULL COMMENT '최종프레임일시',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    PRIMARY KEY (CCTV_SN),
    UNIQUE KEY UK_CCTV_UNQ_NO (CCTV_UNQ_NO),
    UNIQUE KEY UK_CCTV_EQPMNT (EQPMNT_SN),
    KEY IX_CCTV_STTS (VDO_STTS_CD, LAST_FRAME_DT),
    CONSTRAINT FK_CCTV_EQPMNT FOREIGN KEY (EQPMNT_SN) REFERENCES eqpmnt_info (EQPMNT_SN),
    CONSTRAINT CK_CCTV_YN CHECK (PTZ_USE_YN IN ('Y','N') AND USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='CCTV상세정보';

CREATE TABLE IF NOT EXISTS cctv_chnl_info (
    CCTV_CHNL_SN           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'CCTV채널일련번호',
    CCTV_SN                BIGINT UNSIGNED NOT NULL COMMENT 'CCTV일련번호',
    CHNL_NO                INT UNSIGNED NOT NULL COMMENT '채널번호',
    CHNL_NM                VARCHAR(200) NULL COMMENT '채널명(공통표준)',
    VDO_URL_ADDR           VARCHAR(2000) NOT NULL COMMENT '동영상URL주소(공통표준)',
    PROTCL_CD              VARCHAR(20) NULL COMMENT '프로토콜코드',
    USER_ID                VARCHAR(20) NULL COMMENT '영상접속사용자아이디(공통표준)',
    ENPSWD                 VARCHAR(256) NULL COMMENT '영상접속암호화비밀번호',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    PRIMARY KEY (CCTV_CHNL_SN),
    UNIQUE KEY UK_CCTV_CHNL (CCTV_SN, CHNL_NO),
    CONSTRAINT FK_CCTV_CHNL_CCTV FOREIGN KEY (CCTV_SN) REFERENCES cctv_info (CCTV_SN),
    CONSTRAINT CK_CCTV_CHNL_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='CCTV영상채널';

CREATE TABLE IF NOT EXISTS acss_evnt_hist (
    ACSS_EVNT_SN           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '출입이벤트일련번호',
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL COMMENT '출입통제장비일련번호',
    EVNT_CD                VARCHAR(50) NOT NULL COMMENT '이벤트코드',
    EVNT_NM                VARCHAR(200) NOT NULL COMMENT '이벤트명',
    ACSS_DT                DATETIME NOT NULL COMMENT '출입일시',
    ACSS_RSLT_CD           VARCHAR(20) NOT NULL COMMENT '출입결과코드',
    APRV_YN                CHAR(1) NULL COMMENT '승인여부',
    CARD_NO_HASH           VARCHAR(256) NULL COMMENT '카드번호해시값',
    EVNT_CN                VARCHAR(4000) NULL COMMENT '이벤트내용',
    CLCT_DT                DATETIME NOT NULL COMMENT '수집일시(공통표준)',
    PRIMARY KEY (ACSS_EVNT_SN),
    KEY IX_ACSS_EVNT_DT (ACSS_DT, EQPMNT_SN),
    CONSTRAINT FK_ACSS_EVNT_EQPMNT FOREIGN KEY (EQPMNT_SN) REFERENCES eqpmnt_info (EQPMNT_SN),
    CONSTRAINT CK_ACSS_EVNT_APRV_YN CHECK (APRV_YN IS NULL OR APRV_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='SCADA시설출입보안이벤트_업무확정필요';

/* =========================================================
 * 3. 수집주기·상태·성능·Raw 데이터
 * ========================================================= */

CREATE TABLE IF NOT EXISTS clct_cycle_info (
    CLCT_CYCLE_SN          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수집주기일련번호',
    LINK_SYS_SN            BIGINT UNSIGNED NOT NULL COMMENT '연계시스템일련번호',
    DATA_SE_CD             VARCHAR(20) NOT NULL COMMENT '데이터구분코드(F/P/C/S)',
    CLCT_CYCLE_SEC         INT UNSIGNED NOT NULL DEFAULT 300 COMMENT '수집주기초수',
    STTS_MNTRG_CYCLE_SEC   INT UNSIGNED NOT NULL DEFAULT 30 COMMENT '상태감시주기초수',
    TIMEOUT_SEC            INT UNSIGNED NOT NULL DEFAULT 10 COMMENT '타임아웃초수',
    RETRY_NOCS             INT UNSIGNED NOT NULL DEFAULT 3 COMMENT '재시도건수',
    LAST_EXCN_DT           DATETIME NULL COMMENT '최종실행일시',
    NEXT_EXCN_DT           DATETIME NULL COMMENT '다음실행일시',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (CLCT_CYCLE_SN),
    UNIQUE KEY UK_CLCT_CYCLE (LINK_SYS_SN, DATA_SE_CD),
    CONSTRAINT FK_CLCT_CYCLE_SYS FOREIGN KEY (LINK_SYS_SN) REFERENCES link_sys_info (LINK_SYS_SN),
    CONSTRAINT CK_CLCT_CYCLE_SEC CHECK (CLCT_CYCLE_SEC >= 60 AND STTS_MNTRG_CYCLE_SEC <= 30),
    CONSTRAINT CK_CLCT_CYCLE_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='시스템별수집및상태감시주기';

CREATE TABLE IF NOT EXISTS clct_excn_hist (
    CLCT_EXCN_SN           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '수집실행일련번호',
    CLCT_CYCLE_SN          BIGINT UNSIGNED NOT NULL COMMENT '수집주기일련번호',
    EXCN_BGNG_DT           DATETIME NOT NULL COMMENT '실행시작일시',
    EXCN_END_DT            DATETIME NULL COMMENT '실행종료일시',
    CLCT_NOCS              BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '수집건수(공통표준)',
    SUCC_NOCS              BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '성공건수',
    FAIL_NOCS              BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '실패건수',
    STTS_CD                VARCHAR(20) NOT NULL COMMENT '상태코드',
    ERR_CN                 VARCHAR(4000) NULL COMMENT '오류내용',
    PRIMARY KEY (CLCT_EXCN_SN),
    KEY IX_CLCT_EXCN_DT (CLCT_CYCLE_SN, EXCN_BGNG_DT),
    CONSTRAINT FK_CLCT_EXCN_CYCLE FOREIGN KEY (CLCT_CYCLE_SN) REFERENCES clct_cycle_info (CLCT_CYCLE_SN)
) ENGINE=InnoDB COMMENT='수집실행이력';

CREATE TABLE IF NOT EXISTS perf_metric_info (
    METRIC_CD              VARCHAR(50) NOT NULL COMMENT '성능지표코드',
    METRIC_NM              VARCHAR(100) NOT NULL COMMENT '성능지표명',
    DATA_SE_CD             VARCHAR(20) NOT NULL COMMENT '데이터구분코드',
    UNIT_NM                VARCHAR(100) NULL COMMENT '단위명(공통표준)',
    DATA_TYPE_NM           VARCHAR(100) NOT NULL DEFAULT 'DECIMAL' COMMENT '데이터타입명',
    METRIC_EXPLN           VARCHAR(4000) NULL COMMENT '성능지표설명',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    PRIMARY KEY (METRIC_CD),
    CONSTRAINT CK_METRIC_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='성능지표정의';

CREATE TABLE IF NOT EXISTS thrshld_info (
    THRSHLD_SN             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '임계치일련번호',
    LINK_SYS_SN            BIGINT UNSIGNED NULL COMMENT '연계시스템일련번호(NULL=공통)',
    EQPMNT_SE_CD           VARCHAR(20) NULL COMMENT '장비구분코드',
    METRIC_CD              VARCHAR(50) NOT NULL COMMENT '성능지표코드',
    CAUTION_VAL            DECIMAL(20,6) NULL COMMENT '주의값',
    WARNING_VAL            DECIMAL(20,6) NULL COMMENT '경고값',
    CRITICAL_VAL           DECIMAL(20,6) NULL COMMENT '심각값',
    CMPR_OPRTR_CD          VARCHAR(10) NOT NULL DEFAULT 'GE' COMMENT '비교연산자코드',
    DRTN_SEC               INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '지속초수',
    RCVR_VAL               DECIMAL(20,6) NULL COMMENT '복구값',
    ALRM_USE_YN            CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '알람사용여부(공통표준)',
    SMS_USE_YN             CHAR(1) NOT NULL DEFAULT 'N' COMMENT 'SMS사용여부(공통표준)',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (THRSHLD_SN),
    UNIQUE KEY UK_THRSHLD (LINK_SYS_SN, EQPMNT_SE_CD, METRIC_CD),
    CONSTRAINT FK_THRSHLD_SYS FOREIGN KEY (LINK_SYS_SN) REFERENCES link_sys_info (LINK_SYS_SN),
    CONSTRAINT FK_THRSHLD_METRIC FOREIGN KEY (METRIC_CD) REFERENCES perf_metric_info (METRIC_CD),
    CONSTRAINT CK_THRSHLD_YN CHECK (ALRM_USE_YN IN ('Y','N') AND SMS_USE_YN IN ('Y','N') AND USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='다단계임계치';

CREATE TABLE IF NOT EXISTS sys_health_stts (
    LINK_SYS_SN            BIGINT UNSIGNED NOT NULL COMMENT '연계시스템일련번호',
    SRVR_NM                VARCHAR(100) NOT NULL COMMENT '서버명(공통표준)',
    CPU_USGRT              DECIMAL(5,2) NULL COMMENT 'CPU사용률(공통표준)',
    MMRY_USGRT             DECIMAL(5,2) NULL COMMENT '메모리사용률(공통표준)',
    HDD_USGRT              DECIMAL(5,2) NULL COMMENT '하드디스크사용률',
    NETWK_IN_BPS           BIGINT UNSIGNED NULL COMMENT '네트워크수신초당비트수',
    NETWK_OUT_BPS          BIGINT UNSIGNED NULL COMMENT '네트워크송신초당비트수',
    STTS_CD                VARCHAR(20) NOT NULL DEFAULT 'NORMAL' COMMENT '상태코드',
    CLCT_DT                DATETIME NOT NULL COMMENT '수집일시(공통표준)',
    PRIMARY KEY (LINK_SYS_SN, SRVR_NM),
    KEY IX_SYS_HEALTH_STTS (STTS_CD, CLCT_DT),
    CONSTRAINT FK_SYS_HEALTH_SYS FOREIGN KEY (LINK_SYS_SN) REFERENCES link_sys_info (LINK_SYS_SN),
    CONSTRAINT CK_SYS_HEALTH_RATE CHECK (
      (CPU_USGRT IS NULL OR CPU_USGRT BETWEEN 0 AND 100) AND
      (MMRY_USGRT IS NULL OR MMRY_USGRT BETWEEN 0 AND 100) AND
      (HDD_USGRT IS NULL OR HDD_USGRT BETWEEN 0 AND 100)
    )
) ENGINE=InnoDB COMMENT='연계시스템서버현재상태';

CREATE TABLE IF NOT EXISTS eqpmnt_stts (
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL COMMENT '장비일련번호',
    CNTN_YN                CHAR(1) NOT NULL DEFAULT 'N' COMMENT '접속여부(공통표준)',
    PING_RSPNS_MS          INT UNSIGNED NULL COMMENT 'PING응답밀리초수',
    STTS_CD                VARCHAR(20) NOT NULL DEFAULT 'UNKNOWN' COMMENT '상태코드',
    STTS_EXPLN             VARCHAR(4000) NULL COMMENT '상태설명(공통표준)',
    LAST_RSPNS_DT          DATETIME NULL COMMENT '최종응답일시',
    CLCT_DT                DATETIME NOT NULL COMMENT '수집일시(공통표준)',
    PRIMARY KEY (EQPMNT_SN),
    KEY IX_EQPMNT_STTS (STTS_CD, CLCT_DT),
    CONSTRAINT FK_EQPMNT_STTS_EQPMNT FOREIGN KEY (EQPMNT_SN) REFERENCES eqpmnt_info (EQPMNT_SN),
    CONSTRAINT CK_EQPMNT_STTS_CNTN_YN CHECK (CNTN_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='장비현재상태';

CREATE TABLE IF NOT EXISTS eqpmnt_perf_stts (
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL COMMENT '장비일련번호',
    METRIC_CD              VARCHAR(50) NOT NULL COMMENT '성능지표코드',
    MSRMT_VAL              DECIMAL(20,6) NULL COMMENT '측정값',
    TEXT_VAL               VARCHAR(4000) NULL COMMENT '문자값',
    UNIT_NM                VARCHAR(100) NULL COMMENT '단위명(공통표준)',
    STTS_CD                VARCHAR(20) NOT NULL DEFAULT 'NORMAL' COMMENT '상태코드',
    CLCT_DT                DATETIME NOT NULL COMMENT '수집일시(공통표준)',
    PRIMARY KEY (EQPMNT_SN, METRIC_CD),
    KEY IX_PERF_CURR_STTS (STTS_CD, CLCT_DT),
    CONSTRAINT FK_PERF_CURR_EQPMNT FOREIGN KEY (EQPMNT_SN) REFERENCES eqpmnt_info (EQPMNT_SN),
    CONSTRAINT FK_PERF_CURR_METRIC FOREIGN KEY (METRIC_CD) REFERENCES perf_metric_info (METRIC_CD)
) ENGINE=InnoDB COMMENT='장비성능현재값_대시보드용';

/*
 * 대용량 원본 성능 테이블.
 * 월 파티션 적용 시 모든 UNIQUE KEY에 CLCT_DT가 포함되어야 하고,
 * MariaDB 파티션 테이블은 FK 제약을 사용할 수 없으므로 참조 무결성은 수집 모듈에서 검증한다.
 */
CREATE TABLE IF NOT EXISTS perf_raw_data (
    PERF_RAW_SN            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '성능원본일련번호',
    CLCT_DT                DATETIME NOT NULL COMMENT '수집일시(공통표준)',
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL COMMENT '장비일련번호',
    METRIC_CD              VARCHAR(50) NOT NULL COMMENT '성능지표코드',
    MSRMT_VAL              DECIMAL(20,6) NULL COMMENT '측정값',
    TEXT_VAL               VARCHAR(4000) NULL COMMENT '문자값',
    UNIT_NM                VARCHAR(100) NULL COMMENT '단위명(공통표준)',
    CLCT_STTS_CD           VARCHAR(20) NOT NULL DEFAULT 'SUCCESS' COMMENT '수집상태코드',
    SRC_EVNT_NO            VARCHAR(100) NULL COMMENT '원천이벤트번호',
    PRIMARY KEY (CLCT_DT, PERF_RAW_SN),
    KEY IX_PERF_RAW_SN (PERF_RAW_SN),
    KEY IX_PERF_RAW_EQPMNT (EQPMNT_SN, METRIC_CD, CLCT_DT),
    KEY IX_PERF_RAW_STTS (CLCT_STTS_CD, CLCT_DT)
) ENGINE=InnoDB COMMENT='성능Raw데이터_3개월보존';

CREATE TABLE IF NOT EXISTS perf_hr_stats (
    STATS_HR_DT            DATETIME NOT NULL COMMENT '통계시간일시',
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL COMMENT '장비일련번호',
    METRIC_CD              VARCHAR(50) NOT NULL COMMENT '성능지표코드',
    AVG_VAL                DECIMAL(20,6) NULL COMMENT '평균값',
    MIN_VAL                DECIMAL(20,6) NULL COMMENT '최솟값',
    MAX_VAL                DECIMAL(20,6) NULL COMMENT '최댓값',
    SUM_VAL                DECIMAL(30,6) NULL COMMENT '합계값',
    CLCT_NOCS              BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '수집건수(공통표준)',
    FAIL_NOCS              BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '실패건수',
    PRIMARY KEY (STATS_HR_DT, EQPMNT_SN, METRIC_CD),
    KEY IX_PERF_HR_EQPMNT (EQPMNT_SN, METRIC_CD, STATS_HR_DT)
) ENGINE=InnoDB COMMENT='성능1시간통계_1년보존';

CREATE TABLE IF NOT EXISTS perf_day_stats (
    STATS_YMD              DATE NOT NULL COMMENT '통계일자',
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL COMMENT '장비일련번호',
    METRIC_CD              VARCHAR(50) NOT NULL COMMENT '성능지표코드',
    AVG_VAL                DECIMAL(20,6) NULL COMMENT '평균값',
    MIN_VAL                DECIMAL(20,6) NULL COMMENT '최솟값',
    MAX_VAL                DECIMAL(20,6) NULL COMMENT '최댓값',
    SUM_VAL                DECIMAL(30,6) NULL COMMENT '합계값',
    CLCT_NOCS              BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '수집건수(공통표준)',
    FAIL_NOCS              BIGINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '실패건수',
    PRIMARY KEY (STATS_YMD, EQPMNT_SN, METRIC_CD),
    KEY IX_PERF_DAY_EQPMNT (EQPMNT_SN, METRIC_CD, STATS_YMD)
) ENGINE=InnoDB COMMENT='성능일통계_3년보존';

CREATE TABLE IF NOT EXISTS link_raw_data (
    LINK_RAW_SN            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '연계원본일련번호',
    LINK_SYS_SN            BIGINT UNSIGNED NOT NULL COMMENT '연계시스템일련번호',
    CLCT_DT                DATETIME NOT NULL COMMENT '수집일시(공통표준)',
    SRC_EVNT_NO            VARCHAR(100) NULL COMMENT '원천이벤트번호',
    DATA_SE_CD             VARCHAR(20) NOT NULL COMMENT '데이터구분코드',
    RAW_DATA               LONGTEXT NOT NULL COMMENT '수신원본데이터',
    CLCT_STTS_CD           VARCHAR(20) NOT NULL DEFAULT 'SUCCESS' COMMENT '수집상태코드',
    ERR_CN                 VARCHAR(4000) NULL COMMENT '오류내용',
    PRIMARY KEY (LINK_RAW_SN),
    KEY IX_LINK_RAW_SYS_DT (LINK_SYS_SN, CLCT_DT),
    KEY IX_LINK_RAW_STTS_DT (CLCT_STTS_CD, CLCT_DT),
    CONSTRAINT FK_LINK_RAW_SYS FOREIGN KEY (LINK_SYS_SN) REFERENCES link_sys_info (LINK_SYS_SN)
) ENGINE=InnoDB COMMENT='연계수신Raw데이터_보존정책확정필요';

/* =========================================================
 * 4. 장애·조치·예외
 * ========================================================= */

CREATE TABLE IF NOT EXISTS dsblty_type_info (
    DSBLTY_TYPE_SN         BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '장애유형일련번호',
    LINK_SYS_SN            BIGINT UNSIGNED NULL COMMENT '연계시스템일련번호(NULL=공통)',
    EVNT_CD                VARCHAR(50) NOT NULL COMMENT '이벤트코드',
    DSBLTY_TYPE_NM         VARCHAR(300) NOT NULL COMMENT '장애유형명(공통표준)',
    DSBLTY_NM              VARCHAR(300) NULL COMMENT '장애명(공통표준)',
    DFLT_GRD_CD            VARCHAR(20) NOT NULL COMMENT '기본등급코드',
    JGMT_CRTR_CN           VARCHAR(4000) NULL COMMENT '판단기준내용',
    AUTO_END_YN            CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '자동종료여부',
    SMS_USE_YN             CHAR(1) NOT NULL DEFAULT 'N' COMMENT 'SMS사용여부(공통표준)',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    AUTO_REG_YN            CHAR(1) NOT NULL DEFAULT 'N' COMMENT '자동등록여부',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (DSBLTY_TYPE_SN),
    UNIQUE KEY UK_DSBLTY_TYPE_EVNT (LINK_SYS_SN, EVNT_CD),
    CONSTRAINT FK_DSBLTY_TYPE_SYS FOREIGN KEY (LINK_SYS_SN) REFERENCES link_sys_info (LINK_SYS_SN),
    CONSTRAINT CK_DSBLTY_TYPE_YN CHECK (
      AUTO_END_YN IN ('Y','N') AND SMS_USE_YN IN ('Y','N') AND
      USE_YN IN ('Y','N') AND AUTO_REG_YN IN ('Y','N')
    )
) ENGINE=InnoDB COMMENT='장애유형';

CREATE TABLE IF NOT EXISTS dsblty_info (
    DSBLTY_SN              BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '장애일련번호',
    DSBLTY_NO              VARCHAR(50) NOT NULL COMMENT '장애번호',
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL COMMENT '장비일련번호',
    DSBLTY_TYPE_SN         BIGINT UNSIGNED NULL COMMENT '장애유형일련번호',
    DSBLTY_GRD_CD          VARCHAR(20) NOT NULL COMMENT '장애등급코드',
    DSBLTY_OCRN_DT         DATETIME NOT NULL COMMENT '장애발생일시(공통표준)',
    DSBLTY_END_DT          DATETIME NULL COMMENT '장애종료일시',
    DSBLTY_OCRN_CN         VARCHAR(4000) NOT NULL COMMENT '장애발생내용(공통표준)',
    DSBLTY_RSN             VARCHAR(4000) NULL COMMENT '장애사유(공통표준)',
    DSBLTY_JGMT_CD         VARCHAR(20) NULL COMMENT '장애판단코드(서비스/상태)',
    PRCS_STTS_CD           VARCHAR(20) NOT NULL DEFAULT 'UNCONFIRMED' COMMENT '처리상태코드',
    IDNTY_USER_SN          BIGINT UNSIGNED NULL COMMENT '확인사용자일련번호',
    IDNTY_DT               DATETIME NULL COMMENT '확인일시(공통표준)',
    EXCP_APLY_YN           CHAR(1) NOT NULL DEFAULT 'N' COMMENT '예외적용여부',
    SRC_EVNT_NO            VARCHAR(100) NULL COMMENT '원천이벤트번호',
    LAST_MDFCN_DT          DATETIME NULL COMMENT '최종수정일시(공통표준)',
    PRIMARY KEY (DSBLTY_SN),
    UNIQUE KEY UK_DSBLTY_NO (DSBLTY_NO),
    KEY IX_DSBLTY_ACTIVE (DSBLTY_END_DT, DSBLTY_GRD_CD, PRCS_STTS_CD),
    KEY IX_DSBLTY_EQPMNT_DT (EQPMNT_SN, DSBLTY_OCRN_DT),
    CONSTRAINT FK_DSBLTY_EQPMNT FOREIGN KEY (EQPMNT_SN) REFERENCES eqpmnt_info (EQPMNT_SN),
    CONSTRAINT FK_DSBLTY_TYPE FOREIGN KEY (DSBLTY_TYPE_SN) REFERENCES dsblty_type_info (DSBLTY_TYPE_SN),
    CONSTRAINT CK_DSBLTY_EXCP_YN CHECK (EXCP_APLY_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='실시간및이력장애';

CREATE TABLE IF NOT EXISTS dsblty_actn_hist (
    ACTN_SN                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '조치일련번호',
    DSBLTY_SN              BIGINT UNSIGNED NOT NULL COMMENT '장애일련번호',
    ACTN_SE_CD             VARCHAR(20) NOT NULL COMMENT '조치구분코드(임시/완료/이관/제어)',
    ACTN_CN                VARCHAR(4000) NOT NULL COMMENT '조치내용(공통표준)',
    ACTN_RSLT_CN           VARCHAR(4000) NULL COMMENT '조치결과내용(공통표준)',
    ACTN_PIC_NM            VARCHAR(100) NULL COMMENT '조치담당자명(공통표준)',
    ACTN_USER_SN           BIGINT UNSIGNED NULL COMMENT '조치사용자일련번호',
    ACTN_DT                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '조치일시',
    CTRL_CMD_CN            VARCHAR(4000) NULL COMMENT '제어명령내용',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    PRIMARY KEY (ACTN_SN),
    KEY IX_DSBLTY_ACTN (DSBLTY_SN, ACTN_DT),
    CONSTRAINT FK_DSBLTY_ACTN_DSBLTY FOREIGN KEY (DSBLTY_SN) REFERENCES dsblty_info (DSBLTY_SN)
) ENGINE=InnoDB COMMENT='장애임시·완료·이관·제어조치';

CREATE TABLE IF NOT EXISTS dsblty_excp_group_info (
    EXCP_GROUP_SN          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '예외그룹일련번호',
    EXCP_GROUP_NM          VARCHAR(100) NOT NULL COMMENT '예외그룹명',
    EXCP_GROUP_EXPLN       VARCHAR(4000) NULL COMMENT '예외그룹설명',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (EXCP_GROUP_SN),
    UNIQUE KEY UK_EXCP_GROUP_NM (EXCP_GROUP_NM),
    CONSTRAINT CK_EXCP_GROUP_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='장애예외장비그룹';

CREATE TABLE IF NOT EXISTS dsblty_excp_group_eqpmnt_rel (
    EXCP_GROUP_SN          BIGINT UNSIGNED NOT NULL COMMENT '예외그룹일련번호',
    EQPMNT_SN              BIGINT UNSIGNED NOT NULL COMMENT '장비일련번호',
    METRIC_CD              VARCHAR(50) NOT NULL DEFAULT '*' COMMENT '예외대상지표코드',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    PRIMARY KEY (EXCP_GROUP_SN, EQPMNT_SN, METRIC_CD),
    CONSTRAINT FK_EXCP_GROUP_EQPMNT_GROUP FOREIGN KEY (EXCP_GROUP_SN)
        REFERENCES dsblty_excp_group_info (EXCP_GROUP_SN),
    CONSTRAINT FK_EXCP_GROUP_EQPMNT_EQPMNT FOREIGN KEY (EQPMNT_SN)
        REFERENCES eqpmnt_info (EQPMNT_SN)
) ENGINE=InnoDB COMMENT='장애예외그룹장비';

CREATE TABLE IF NOT EXISTS dsblty_excp_schdl_info (
    EXCP_SCHDL_SN          BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '예외일정일련번호',
    EXCP_GROUP_SN          BIGINT UNSIGNED NOT NULL COMMENT '예외그룹일련번호',
    EXCP_SCHDL_NM          VARCHAR(100) NOT NULL COMMENT '예외일정명',
    BGNG_DT                DATETIME NOT NULL COMMENT '시작일시',
    END_DT                 DATETIME NOT NULL COMMENT '종료일시(공통표준)',
    REPT_CYCLE_CN          VARCHAR(4000) NULL COMMENT '반복주기내용(공통표준)',
    EXCP_GRD_CD_LIST       VARCHAR(200) NULL COMMENT '예외등급코드목록',
    EXCP_RSN               VARCHAR(4000) NOT NULL COMMENT '예외사유',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (EXCP_SCHDL_SN),
    KEY IX_EXCP_SCHDL_TIME (BGNG_DT, END_DT, USE_YN),
    CONSTRAINT FK_EXCP_SCHDL_GROUP FOREIGN KEY (EXCP_GROUP_SN)
        REFERENCES dsblty_excp_group_info (EXCP_GROUP_SN),
    CONSTRAINT CK_EXCP_SCHDL_DT CHECK (END_DT > BGNG_DT),
    CONSTRAINT CK_EXCP_SCHDL_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='장애예외시간설정';

/* =========================================================
 * 5. SMS·UI설정·로그·보고서
 * ========================================================= */

CREATE TABLE IF NOT EXISTS sms_group_info (
    SMS_GROUP_SN           BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'SMS그룹일련번호',
    SMS_GROUP_NM           VARCHAR(100) NOT NULL COMMENT 'SMS그룹명',
    DSBLTY_GRD_CD          VARCHAR(20) NULL COMMENT '전송대상장애등급코드',
    LINK_SYS_SN            BIGINT UNSIGNED NULL COMMENT '전송대상연계시스템일련번호',
    TRSM_BGNG_TM           TIME NULL COMMENT '전송시작시각',
    TRSM_END_TM            TIME NULL COMMENT '전송종료시각',
    RETRSM_CYCLE_MIN       INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '재전송주기분수',
    MAX_TRSM_NOCS          INT UNSIGNED NOT NULL DEFAULT 1 COMMENT '최대전송건수',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (SMS_GROUP_SN),
    UNIQUE KEY UK_SMS_GROUP_NM (SMS_GROUP_NM),
    CONSTRAINT FK_SMS_GROUP_SYS FOREIGN KEY (LINK_SYS_SN) REFERENCES link_sys_info (LINK_SYS_SN),
    CONSTRAINT CK_SMS_GROUP_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='SMS전송그룹';

CREATE TABLE IF NOT EXISTS sms_group_user_rel (
    SMS_GROUP_SN           BIGINT UNSIGNED NOT NULL COMMENT 'SMS그룹일련번호',
    USER_SN                BIGINT UNSIGNED NOT NULL COMMENT '사용자일련번호',
    SMS_RCPTN_TELNO        VARCHAR(11) NOT NULL COMMENT 'SMS수신전화번호(공통표준)',
    RCPTN_YN               CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '수신여부',
    PRIMARY KEY (SMS_GROUP_SN, USER_SN),
    CONSTRAINT FK_SMS_GROUP_USER_GROUP FOREIGN KEY (SMS_GROUP_SN) REFERENCES sms_group_info (SMS_GROUP_SN),
    CONSTRAINT FK_SMS_GROUP_USER_USER FOREIGN KEY (USER_SN) REFERENCES user_info (USER_SN),
    CONSTRAINT CK_SMS_GROUP_USER_YN CHECK (RCPTN_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='SMS전송그룹사용자';

CREATE TABLE IF NOT EXISTS sms_trsm_hist (
    SMS_TRSM_SN            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT 'SMS전송일련번호(공통표준)',
    SMS_GROUP_SN           BIGINT UNSIGNED NULL COMMENT 'SMS그룹일련번호',
    DSBLTY_SN              BIGINT UNSIGNED NULL COMMENT '장애일련번호',
    SMS_RCPTN_TELNO        VARCHAR(11) NOT NULL COMMENT 'SMS수신전화번호(공통표준)',
    SMS_CN                 VARCHAR(4000) NOT NULL COMMENT 'SMS내용',
    TRSM_DT                DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '전송일시',
    TRSM_RSLT_CD           VARCHAR(20) NOT NULL COMMENT '전송결과코드',
    FAIL_RSN               VARCHAR(4000) NULL COMMENT '실패사유',
    PRIMARY KEY (SMS_TRSM_SN),
    KEY IX_SMS_TRSM_DT (TRSM_DT, TRSM_RSLT_CD),
    CONSTRAINT FK_SMS_TRSM_GROUP FOREIGN KEY (SMS_GROUP_SN) REFERENCES sms_group_info (SMS_GROUP_SN),
    CONSTRAINT FK_SMS_TRSM_DSBLTY FOREIGN KEY (DSBLTY_SN) REFERENCES dsblty_info (DSBLTY_SN)
) ENGINE=InnoDB COMMENT='SMS전송이력';

CREATE TABLE IF NOT EXISTS ui_stng_info (
    UI_STNG_CD             VARCHAR(50) NOT NULL COMMENT 'UI설정코드',
    UI_STNG_NM             VARCHAR(100) NOT NULL COMMENT 'UI설정명',
    UI_STNG_VAL            VARCHAR(4000) NOT NULL COMMENT 'UI설정값',
    UI_STNG_EXPLN          VARCHAR(4000) NULL COMMENT 'UI설정설명',
    USE_YN                 CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '사용여부(공통표준)',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    RGTR_SN                BIGINT UNSIGNED NULL COMMENT '등록자일련번호(공통표준)',
    MDFCN_DT               DATETIME NULL COMMENT '수정일시(공통표준)',
    MDFR_SN                BIGINT UNSIGNED NULL COMMENT '수정자일련번호(공통표준)',
    PRIMARY KEY (UI_STNG_CD),
    CONSTRAINT CK_UI_STNG_USE_YN CHECK (USE_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='UI설정';

CREATE TABLE IF NOT EXISTS cntn_log (
    CNTN_LOG_SN            BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '접속로그일련번호(공통표준)',
    USER_SN                BIGINT UNSIGNED NULL COMMENT '사용자일련번호',
    USER_ID                VARCHAR(20) NULL COMMENT '사용자아이디(공통표준)',
    LGN_IP_ADDR            VARCHAR(15) NULL COMMENT '로그인IP주소(공통표준, IPv4)',
    CNTN_BGNG_DT           DATETIME NOT NULL COMMENT '접속시작일시(공통표준)',
    LGT_DT                 DATETIME NULL COMMENT '로그아웃일시(공통표준)',
    CNTN_BRWSR_NM          VARCHAR(300) NULL COMMENT '접속브라우저명(공통표준)',
    CNTN_YN                CHAR(1) NOT NULL COMMENT '접속여부(공통표준)',
    FAIL_RSN               VARCHAR(4000) NULL COMMENT '실패사유',
    PRIMARY KEY (CNTN_LOG_SN),
    KEY IX_CNTN_LOG_USER_DT (USER_SN, CNTN_BGNG_DT),
    KEY IX_CNTN_LOG_RESULT_DT (CNTN_YN, CNTN_BGNG_DT),
    CONSTRAINT CK_CNTN_LOG_YN CHECK (CNTN_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='로그인접속이력';

CREATE TABLE IF NOT EXISTS job_log (
    JOB_LOG_SN             BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '작업로그일련번호',
    USER_SN                BIGINT UNSIGNED NULL COMMENT '사용자일련번호',
    USER_ID                VARCHAR(20) NULL COMMENT '사용자아이디(공통표준)',
    USER_IP_ADDR           VARCHAR(15) NULL COMMENT '사용자IP주소(공통표준, IPv4)',
    CNTN_MENU_NM           VARCHAR(100) NULL COMMENT '접속메뉴명(공통표준)',
    JOB_SE_CD              VARCHAR(20) NOT NULL COMMENT '작업구분코드',
    TRGT_KEY_VAL           VARCHAR(200) NULL COMMENT '대상키값',
    LOG_CN                 VARCHAR(4000) NULL COMMENT '로그내용(공통표준)',
    CHG_BFR_CN             VARCHAR(4000) NULL COMMENT '변경이전내용',
    CHG_AFTR_CN            VARCHAR(4000) NULL COMMENT '변경이후내용',
    JOB_RSLT_CD            VARCHAR(20) NOT NULL COMMENT '작업결과코드',
    LOG_CRT_DT             DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '로그생성일시(공통표준)',
    PRIMARY KEY (JOB_LOG_SN),
    KEY IX_JOB_LOG_USER_DT (USER_SN, LOG_CRT_DT),
    KEY IX_JOB_LOG_MENU_DT (CNTN_MENU_NM, LOG_CRT_DT),
    KEY IX_JOB_LOG_RESULT_DT (JOB_RSLT_CD, LOG_CRT_DT)
) ENGINE=InnoDB COMMENT='사용자웹작업로그';

CREATE TABLE IF NOT EXISTS rptp_otpt_hist (
    RPTP_SN                BIGINT UNSIGNED NOT NULL AUTO_INCREMENT COMMENT '보고서일련번호(공통표준)',
    RPTP_NO                VARCHAR(20) NOT NULL COMMENT '보고서번호(공통표준)',
    RPTP_NM                VARCHAR(256) NOT NULL COMMENT '보고서명(공통표준)',
    RPTP_SE_CD             VARCHAR(20) NOT NULL COMMENT '보고서구분코드',
    SRCH_CND_CN            VARCHAR(4000) NULL COMMENT '검색조건내용',
    RPTP_FILE_NM           VARCHAR(300) NULL COMMENT '보고서파일명(공통표준)',
    RPTP_URL_ADDR          VARCHAR(2000) NULL COMMENT '보고서URL주소(공통표준)',
    RPTP_OTPT_YN           CHAR(1) NOT NULL DEFAULT 'Y' COMMENT '보고서출력여부(공통표준)',
    RPTP_WRT_YMD           DATE NOT NULL COMMENT '보고서작성일자(공통표준)',
    OTPT_USER_SN           BIGINT UNSIGNED NULL COMMENT '출력사용자일련번호',
    REG_DT                 DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '등록일시(공통표준)',
    PRIMARY KEY (RPTP_SN),
    UNIQUE KEY UK_RPTP_NO (RPTP_NO),
    KEY IX_RPTP_WRT_YMD (RPTP_WRT_YMD, RPTP_SE_CD),
    CONSTRAINT CK_RPTP_OTPT_YN CHECK (RPTP_OTPT_YN IN ('Y','N'))
) ENGINE=InnoDB COMMENT='보고서출력이력';

/* =========================================================
 * 6. 초기 공통코드·기본 지표·5종 시스템·역사
 * ========================================================= */

INSERT IGNORE INTO com_cd_group_info
  (COM_CD_GROUP_ID, COM_CD_GROUP_NM, COM_CD_GROUP_EXPLN, COM_CD_LEN)
VALUES
  ('SYS_STTS', '시스템상태', '연계시스템 및 장비 상태', 20),
  ('DSBLTY_GRD', '장애등급', '정상·주의·경고·심각', 20),
  ('PRCS_STTS', '처리상태', '장애 처리상태', 20),
  ('PROTOCOL', '프로토콜', '연계 통신 프로토콜', 20),
  ('DATA_SE', '데이터구분', 'Fault·Performance·Configuration·Security', 20),
  ('EQPMNT_SE', '장비구분', 'TNMS 관리 장비 유형', 20),
  ('JOB_SE', '작업구분', '조회·등록·수정·삭제·제어·로그인', 20);

INSERT IGNORE INTO com_cd_info
  (COM_CD_GROUP_ID, COM_CD, COM_CD_NM, COM_CD_SEQ, EXT1_CN)
VALUES
  ('SYS_STTS','NORMAL','정상',1,'#45DF9A'),
  ('SYS_STTS','CAUTION','주의',2,'#FFCC66'),
  ('SYS_STTS','WARNING','경고',3,'#FF9955'),
  ('SYS_STTS','CRITICAL','심각',4,'#FF7389'),
  ('SYS_STTS','UNKNOWN','알수없음',5,'#74869A'),
  ('DSBLTY_GRD','CAUTION','주의',1,'#FFCC66'),
  ('DSBLTY_GRD','WARNING','경고',2,'#FF9955'),
  ('DSBLTY_GRD','CRITICAL','심각',3,'#FF7389'),
  ('PRCS_STTS','UNCONFIRMED','미확인',1,NULL),
  ('PRCS_STTS','CONFIRMED','확인',2,NULL),
  ('PRCS_STTS','TEMP_ACTN','임시조치',3,NULL),
  ('PRCS_STTS','COMPLETED','완료',4,NULL),
  ('PROTOCOL','SNMP_V1','SNMP v1',1,NULL),
  ('PROTOCOL','SNMP_V2C','SNMP v2c',2,NULL),
  ('PROTOCOL','SNMP_V3','SNMP v3',3,NULL),
  ('PROTOCOL','TL1','TL1',4,NULL),
  ('PROTOCOL','RMON','RMON',5,NULL),
  ('PROTOCOL','SYSLOG','Syslog',6,NULL),
  ('PROTOCOL','ICMP','ICMP',7,NULL),
  ('PROTOCOL','REST_API','REST API',8,NULL),
  ('PROTOCOL','TCP_IP','TCP/IP Socket',9,NULL),
  ('DATA_SE','F','Fault',1,NULL),
  ('DATA_SE','P','Performance',2,NULL),
  ('DATA_SE','C','Configuration',3,NULL),
  ('DATA_SE','S','Security',4,NULL);

INSERT IGNORE INTO perf_metric_info
  (METRIC_CD, METRIC_NM, DATA_SE_CD, UNIT_NM, METRIC_EXPLN)
VALUES
  ('CPU_USGRT','CPU 사용률','P','%','CPU 사용 비율'),
  ('MMRY_USGRT','메모리 사용률','P','%','메모리 사용 비율'),
  ('HDD_USGRT','디스크 사용률','P','%','디스크 사용 비율'),
  ('TRFC_USGRT','트래픽 사용률','P','%','회선 대비 트래픽 사용 비율'),
  ('ERR_PKT_RT','에러 패킷률','P','%','전체 패킷 대비 오류 패킷 비율'),
  ('PING_RSPNS_MS','PING 응답시간','P','ms','ICMP 응답시간'),
  ('VDO_FRAME_LOSS_RT','영상 프레임 손실률','P','%','CCTV 영상 프레임 손실 비율'),
  ('CNTN_YN','접속 여부','P','-','장비 접속 상태');

INSERT IGNORE INTO stn_info
  (STN_CD, STN_NM, STN_SEQ)
VALUES
  ('AREX01','서울역',1), ('AREX02','공덕',2), ('AREX03','홍대입구',3),
  ('AREX04','디지털미디어시티',4), ('AREX05','마곡나루',5), ('AREX06','김포공항',6),
  ('AREX07','계양',7), ('AREX08','검암',8), ('AREX09','청라국제도시',9),
  ('AREX10','영종',10), ('AREX11','운서',11), ('AREX12','공항화물청사',12),
  ('AREX13','인천공항1터미널',13), ('AREX14','인천공항2터미널',14);

INSERT IGNORE INTO link_sys_info
  (LINK_SYS_CD, LINK_SYS_NM, PROTCL_CD, STTS_CD)
VALUES
  ('EMS_TX','EMS 전송설비','SNMP_V3','NORMAL'),
  ('EMS_PIDS','EMS 행선안내설비','REST_API','NORMAL'),
  ('SCADA_SEC','SCADA 출입보안설비','TCP_IP','NORMAL'),
  ('PBX','전화교환설비','SNMP_V2C','NORMAL'),
  ('VMS','영상감시설비','REST_API','NORMAL');

INSERT IGNORE INTO ui_stng_info
  (UI_STNG_CD, UI_STNG_NM, UI_STNG_VAL, UI_STNG_EXPLN)
VALUES
  ('LIST_ROW_CNT','목록 기본 행수','20','목록 화면의 페이지당 기본 행 수'),
  ('DASHBOARD_REFRESH_SEC','대시보드 갱신주기','10','대시보드 자동 갱신 초'),
  ('PSWD_CHG_NOTICE_DAY','비밀번호 변경알림','90','비밀번호 변경 안내 주기 일'),
  ('ALRM_POPUP_GRD','장애 팝업 등급','WARNING','해당 등급 이상 팝업'),
  ('ALRM_SOUND_GRD','장애 사운드 등급','CRITICAL','해당 등급 이상 사운드'),
  ('DASHBOARD_55IN_USE_YN','55인치 표출모드','Y','통합 대시보드 TV 표출 여부');

/* =========================================================
 * 7. 대시보드 조회 View
 * ========================================================= */

CREATE OR REPLACE VIEW vw_dashboard_sys_stts AS
SELECT
    S.LINK_SYS_SN,
    S.LINK_SYS_CD,
    S.LINK_SYS_NM,
    S.STTS_CD,
    S.LAST_LINK_RCPTN_DT,
    COUNT(E.EQPMNT_SN) AS EQPMNT_NOCS,
    SUM(CASE WHEN C.STTS_CD = 'NORMAL' THEN 1 ELSE 0 END) AS NORMAL_NOCS,
    SUM(CASE WHEN C.STTS_CD IN ('CAUTION','WARNING') THEN 1 ELSE 0 END) AS WARNING_NOCS,
    SUM(CASE WHEN C.STTS_CD = 'CRITICAL' THEN 1 ELSE 0 END) AS CRITICAL_NOCS
FROM link_sys_info S
LEFT JOIN eqpmnt_info E ON E.LINK_SYS_SN = S.LINK_SYS_SN AND E.USE_YN = 'Y'
LEFT JOIN eqpmnt_stts C ON C.EQPMNT_SN = E.EQPMNT_SN
WHERE S.USE_YN = 'Y'
GROUP BY S.LINK_SYS_SN, S.LINK_SYS_CD, S.LINK_SYS_NM, S.STTS_CD, S.LAST_LINK_RCPTN_DT;

CREATE OR REPLACE VIEW vw_dashboard_dsblty_summary AS
SELECT
    DSBLTY_GRD_CD,
    COUNT(*) AS DSBLTY_NOCS,
    SUM(CASE WHEN PRCS_STTS_CD = 'UNCONFIRMED' THEN 1 ELSE 0 END) AS UNCONFIRMED_NOCS
FROM dsblty_info
WHERE DSBLTY_END_DT IS NULL
  AND EXCP_APLY_YN = 'N'
GROUP BY DSBLTY_GRD_CD;

/*
 * 운영 전 필수 후속 작업
 * 1) perf_raw_data / link_raw_data 실제 일수집량 측정 후 월 파티션 적용
 * 2) Raw 3개월, 1시간 통계 1년, 일 통계 3년 삭제 배치 작성
 * 3) 5개 연동업체별 프로토콜·이벤트코드·장비식별키·시간동기화 규칙 확정
 * 4) SCADA가 시설 출입보안인지 AFC 승객 카드 집계인지 확정 후 acss_evnt_hist 재검토
 * 5) CCTV 영상 URL/토큰/계정은 DB 평문 저장 금지. 별도 비밀키 관리 또는 암호화 적용
 * 6) 사용자 비밀번호는 BCrypt/Argon2 해시만 저장하고 복호화 가능한 암호문 저장 금지
 */
