-- TNMS 최신 DB 및 소스 반영 후 확인 / SELECT 전용
USE arex_tnms;

-- (1) 갱신된 VIEW 상태 (PING 실패 -1이 최신이면 OFFLINE, 0·지연이면 UNKNOWN)
SELECT ems_id, COUNT(*) AS total,
 SUM(stts_cd='NORMAL') AS normal_cnt,
 SUM(stts_cd='CAUTION') AS caution_cnt,
 SUM(stts_cd='CRITICAL') AS critical_cnt,
 SUM(stts_cd='OFFLINE') AS offline_cnt,
 SUM(stts_cd='UNKNOWN') AS unknown_cnt,
 SUM(usage_fresh_yn='Y') AS recent_perf_count,
 MAX(ping_dt) AS last_ping_dt,
 MAX(usage_dt) AS last_usage_dt
FROM vw_tnms_gateway_device_live GROUP BY ems_id ORDER BY ems_id;

-- (2) 최근 게이트웨이 수신 추이: 전송(1), 행선(13)
SELECT ems_id, COUNT(*) AS ping_last5m, MAX(reg_dt) AS ping_latest
FROM raw_ping_log WHERE reg_dt>=NOW()-INTERVAL 5 MINUTE
GROUP BY ems_id;
SELECT ems_id, COUNT(*) AS usage_last5m, MAX(reg_dt) AS usage_latest
FROM raw_usage_log WHERE reg_dt>=NOW()-INTERVAL 5 MINUTE
GROUP BY ems_id;

-- (3) 성능값 0.00의 유효성은 DB만으로 증명할 수 없음
SELECT ems_id,device_id,cpu_usage,memory_usage,disk_usage,reg_dt
FROM com_device_usage ORDER BY reg_dt DESC;

-- (4) 실제 장애: 발생시각과 DB 등록시각을 구분해 확인
SELECT ems_id, COUNT(*) AS total,MAX(event_dt) AS newest_event_dt,MAX(reg_dt) AS newest_registration
FROM raw_event_log GROUP BY ems_id;

-- (5) 장비 ID 미매핑 현황 (수집 로그는 보존·조회되어야 함)
SELECT R.ems_id,COUNT(*) AS unmatched_events
FROM raw_event_log R LEFT JOIN com_device_info D
 ON D.ems_id=R.ems_id AND D.device_id=R.device_id
WHERE D.device_id IS NULL GROUP BY R.ems_id;

-- (6) 시연용 이벤트는 없어야 하며 업무 이벤트는 DISABLED 유지
SELECT EVENT_NAME,STATUS FROM information_schema.EVENTS
WHERE EVENT_SCHEMA='arex_tnms';
