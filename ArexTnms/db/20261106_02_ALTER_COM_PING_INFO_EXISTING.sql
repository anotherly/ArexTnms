-- com_ping_info 기생성 환경 누락 필드 보강. 기존 데이터는 삭제/초기화하지 않음.
-- DB: arex_tnms, MariaDB 11.8. 공유 중인 COM 테이블 중 com_ping_info만 변경
USE arex_tnms;

ALTER TABLE com_ping_info
  ADD COLUMN IF NOT EXISTS USE_YN CHAR(1) NOT NULL DEFAULT 'Y'
    COMMENT '해당 시스템/데이터구분 설정 사용여부' AFTER TIMEOUT_POLL_SEC,
  ADD COLUMN IF NOT EXISTS EXCN_TM TIME DEFAULT NULL
    COMMENT '일일 구성 수집 실행시각' AFTER USE_YN,
  ADD COLUMN IF NOT EXISTS CYCLE_CRTR_CN VARCHAR(1000) DEFAULT NULL
    COMMENT '주기 설정 근거 및 비고' AFTER EXCN_TM;

-- 이미 존재하는 설정값에 대해서는 USE_YN='Y' 기본값을 적용하고
-- 기존 시간/메모는 임의 설정하지 않음 (필요시 화면에서 입력)
SELECT EMS_ID, DATA_SE_CD, USE_YN, EXCN_TM, CYCLE_CRTR_CN,
       CLCT_CYCLE_SEC, STTS_MNTR_CYCLE_SEC, TIMEOUT_SEC, RTRY_NOCS
  FROM com_ping_info ORDER BY EMS_ID, DATA_SE_CD;
