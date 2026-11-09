-- 2026-11-05 TNMS 웹 중복 저장 구조 제거 (수동 실행 ONLY)
-- 절대 1차 실행하지 마세요. 신규 ZIP 배포 → 화면 테스트 → 전 DB 백업 → PRECHECK 확인 후 진행.
-- INNODB 트랜잭션으로 롤백할 수 없는 DDL입니다. 기존 테이블에 저장된 과거 기록은 삭제됩니다.
-- raw_*, com_device_*, com_ems_info, 게이트웨이 트리거는 변경하지 않습니다.
USE arex_tnms;

-- (A) 이전 제공된 시연용 객체 정리: 아직 미실행인 경우 해당 SQL을 먼저 실행하세요.
-- db/20261104_DEMO_OBJECTS_CLEANUP_APPLY_MANUAL.sql
-- 예: sp_tnms_demo_refresh_stats가 과거 web_perf_* 통계테이블을 참조하므로 선행 정리가 필요합니다.

-- (B) 웹에서 참조가 제거된 '구형' 공통코드
-- 기존 데이터의 이관과 신규 코드 기능을 검증한 후 실행
DROP TABLE IF EXISTS web_com_cd_info;
DROP TABLE IF EXISTS web_com_cd_group_info;

-- (C) 예전 WEB 수집주기 설정 / 실행이력
-- 게이트웨이 실수신 조회로 화면 전환됨; 웹의 '수정' 기능은 의도적으로 비활성화됨.
-- 이 테이블은 실제 게이트웨이 수집주기를 제어하지 않습니다.
DROP TABLE IF EXISTS web_clct_excn_hstry;
DROP TABLE IF EXISTS web_clct_cycle_info;

-- (D) 웹 화면 시연·중복 성능 통계: 실제 조회는 raw_usage_log 기반
-- 이력 보존 정책에 따라 별도 백업·검증 후 진행하십시오.
DROP TABLE IF EXISTS web_perf_day_stats;
DROP TABLE IF EXISTS web_perf_hr_stats;
DROP TABLE IF EXISTS web_perf_raw_data;

-- (E) 현재 소스에서 참조하지 않는 구형 WEB EMS 마스터
-- com_ems_info로 대체한 사실을 검증한 뒤 실행
DROP TABLE IF EXISTS web_ems_info;

-- (F) 이 SQL에서 절대로 삭제하지 않는 객체:
-- web_eqpmnt_info : 18개 FK 참조, 장비 부가정보/예외설정/레거시 편집 연결
-- web_dsblty_info : 웹 조치·판단·예외와 연계, web_dsblty_actn_hstry의 FK 대상
-- web_eqpmnt_stts, web_eqpmnt_perf_stts : 구형 DB 함수·프로시저/뷰 잔존, 별도 검토
-- web_thrshld_info, web_perf_thrshld_eval_stts : 성능 임계치 업무 및 평가이력
-- web_cctv_info, web_pbx_info, web_pids_eqpmnt_lse_rel 등 웹 고유 부가정보

-- 실행 후 확인
SHOW TABLES LIKE 'web_com_cd%';
SHOW TABLES LIKE 'web_clct_%';
SHOW TABLES LIKE 'web_perf_%';
SELECT TRIGGER_NAME,EVENT_OBJECT_TABLE FROM information_schema.TRIGGERS
 WHERE TRIGGER_SCHEMA=DATABASE() ORDER BY TRIGGER_NAME;
