-- [선택 / Gateway 개발자 사전 협의 필수] 실행 시 raw_*의 인덱스만 추가. 원천 레코드 수정 없음.
-- 대량 누적(30초 * 1500대 = 432만건/일)에서 오늘치 히트맵·최근 5분 수신수를 인덱스로 조회하기 위함.
-- Gateway 수집 쓰기 성능/스토리지 및 실제 쿼리 계획을 먼저 확인 후, 점검시간에만 시행.
-- 이 파일은 기본 01/02 적용 대상이 아닙니다.
USE arex_tnms;
-- SHOW INDEX FROM raw_ping_log;
-- SHOW INDEX FROM raw_usage_log;
-- 기존 인덱스가 없는 경우에만 아래 각 구문을 별도 실행. 생성 중 I/O 부하 주의.
-- ALTER TABLE raw_ping_log ADD INDEX IX_RAW_PING_REG_EMS (reg_dt, ems_id);
-- ALTER TABLE raw_usage_log ADD INDEX IX_RAW_USAGE_REG_EMS_DEV (reg_dt, ems_id, device_id);
