-- [롤백] 반드시 기존 WAR/소스로 먼저 복귀한 후 실행. 2026-11-09 원본 VIEW 구조를 복원.
-- WEB 전용 매핑 컬럼 DEVICE_COM_CD는 삭제하지 않습니다(데이터 보존).
USE tnms;
CREATE OR REPLACE ALGORITHM=UNDEFINED SQL SECURITY INVOKER VIEW vw_tnms_gateway_device_live AS
SELECT
    -- ① 장비 기본정보 (com_device_info)
    d.ems_id          AS ems_id,
    d.device_id       AS device_id,
    d.device_nm       AS device_nm,
    d.device_type     AS device_type,
    d.device_ip       AS device_ip,
    d.device_station  AS device_station,
    d.stn_cd          AS stn_cd,
    d.device_desc     AS device_desc,
    d.device_model    AS device_model,
    d.server_ip       AS server_ip,
    d.device_maker    AS device_maker,
    d.device_check    AS device_check,
    d.test_yn         AS test_yn,
    d.ping_alive      AS ping_alive,
    d.ping_dt         AS ping_dt,

    -- ② EMS 번호 -> 5개 시스템 코드 변환
    CASE d.ems_id
        WHEN 1  THEN 'EMS_TX'
        WHEN 4  THEN 'VMS'
        WHEN 11 THEN 'PBX'
        WHEN 13 THEN 'EMS_PIDS'
        WHEN 16 THEN 'SCADA_SEC'
        ELSE NULL
    END AS link_sys_cd,

    -- ③ 장비 최신 성능 (com_device_usage)
    u.cpu_usage       AS cpu_usage,
    u.memory_usage    AS memory_usage,
    u.disk_usage      AS disk_usage,
    u.reg_dt          AS usage_dt,

    -- ④ 현재 장애 집계 (Gateway 장애 + WEB 임계치 장애, 예외일정 반영)
    f.fault_count     AS fault_count,
    f.severe_grade    AS severe_grade,
    f.last_event_dt   AS last_event_dt,

    -- ⑤ 성능값이 최근 5분 이내 수집됐는지
    CASE
        WHEN u.reg_dt >= CURRENT_TIMESTAMP() - INTERVAL 5 MINUTE THEN 'Y'
        ELSE 'N'
    END AS usage_fresh_yn,

    -- ⑥ 최종 상태 코드
    CASE
        WHEN d.ping_dt IS NULL OR d.ping_alive = 0 THEN 'UNKNOWN'
        WHEN TIMESTAMPDIFF(SECOND, d.ping_dt, CURRENT_TIMESTAMP())
             > 60 * GREATEST(
                 1,
                 COALESCE(
                     (
                         SELECT CAST(s.UI_STNG_VL AS UNSIGNED)
                         FROM web_ui_stng_info s
                         WHERE s.UI_STNG_CD = 'DASHBOARD_OFFLINE_MIN'
                           AND s.USE_YN = 'Y'
                         LIMIT 1
                     ),
                     5
                 )
             ) THEN 'UNKNOWN'
        WHEN d.ping_alive = -1 THEN 'OFFLINE'
        WHEN d.ping_alive <> 1 THEN 'UNKNOWN'
        WHEN f.severe_grade IN (1, 2) THEN 'CRITICAL'
        WHEN f.severe_grade IN (3, 4, 5) THEN 'CAUTION'
        ELSE 'NORMAL'
    END AS stts_cd,

    -- ⑦ 최종 상태 설명
    CASE
        WHEN d.ping_alive = 0 OR d.ping_dt IS NULL THEN 'PING 미확인'
        WHEN TIMESTAMPDIFF(SECOND, d.ping_dt, CURRENT_TIMESTAMP())
             > 60 * GREATEST(
                 1,
                 COALESCE(
                     (
                         SELECT CAST(s.UI_STNG_VL AS UNSIGNED)
                         FROM web_ui_stng_info s
                         WHERE s.UI_STNG_CD = 'DASHBOARD_OFFLINE_MIN'
                           AND s.USE_YN = 'Y'
                         LIMIT 1
                     ),
                     5
                 )
             ) THEN 'PING 수집 지연'
        WHEN d.ping_alive = -1 THEN 'PING 실패'
        WHEN f.severe_grade IS NOT NULL
             THEN CONCAT('발생 장애(등급 ', f.severe_grade, ')')
        ELSE '정상'
    END AS stts_expln

FROM com_device_info d

-- 장비별 최신 성능 정보
LEFT JOIN com_device_usage u
    ON u.ems_id = d.ems_id
   AND u.device_id = d.device_id

-- 활성 장애를 장비별로 집계 (예외일정에 해당하는 장애는 제외)
LEFT JOIN (
    SELECT
        q.ems_id                   AS ems_id,
        q.device_id                AS device_id,
        COUNT(0)                   AS fault_count,
        MIN(q.event_grade)         AS severe_grade,
        MAX(q.event_dt)            AS last_event_dt

    FROM (
        -- A. Gateway 장애
        SELECT
            a.ems_id AS ems_id,
            CONVERT(a.device_id USING utf8mb4)
                COLLATE utf8mb4_unicode_ci AS device_id,
            CAST(a.event_grade AS UNSIGNED) AS event_grade,
            a.event_dt AS event_dt
        FROM raw_event_action a
        WHERE a.event_yn = 1
          AND a.event_grade IN ('1', '2', '3', '4', '5')

        UNION ALL

        -- B. WEB 성능 임계치에서 자체 생성한 장애
        SELECT
            p.EMS_ID AS ems_id,
            CONVERT(p.DEVICE_ID USING utf8mb4)
                COLLATE utf8mb4_unicode_ci AS device_id,
            CAST(p.EVENT_GRADE AS UNSIGNED) AS event_grade,
            p.EVENT_DT AS event_dt
        FROM web_perf_thrshld_event p
        WHERE p.EVENT_YN = 1
    ) q

    WHERE 1 = 1
      AND NOT EXISTS (
          -- 현재 시간에 해당하는 예외일정이 있으면 그 장애는 집계에서 제외
          SELECT 1
          FROM web_dsblty_excp_group_eqpmnt_rel m
          JOIN web_dsblty_excp_group_info g
              ON g.EXCP_GROUP_SN = m.EXCP_GROUP_SN
             AND g.USE_YN = 'Y'
          JOIN web_dsblty_excp_schdl_info x
              ON x.EXCP_GROUP_SN = g.EXCP_GROUP_SN
             AND x.USE_YN = 'Y'
          WHERE m.EMS_ID = q.ems_id
            AND m.DEVICE_ID = q.device_id
            AND CURRENT_TIMESTAMP() >= x.BGNG_DT
            AND (
                x.NO_END_YN = 'Y'
                OR x.END_DT IS NULL
                OR CURRENT_TIMESTAMP() <= x.END_DT
            )
            AND (
                -- 해당 예외일정에 장애등급 조건이 없거나, 현재 장애등급이 포함되는 경우
                NOT EXISTS (
                    SELECT 1
                    FROM web_dsblty_excp_schdl_grd_rel r
                    WHERE r.EXCP_SCHDL_SN = x.EXCP_SCHDL_SN
                    LIMIT 1
                )
                OR EXISTS (
                    SELECT 1
                    FROM web_dsblty_excp_schdl_grd_rel r
                    WHERE r.EXCP_SCHDL_SN = x.EXCP_SCHDL_SN
                      AND r.DSBLTY_GRD_CD = CASE q.event_grade
                          WHEN 1 THEN 'EMERGENCY'
                          WHEN 2 THEN 'HIGH'
                          WHEN 3 THEN 'LOW'
                          WHEN 4 THEN 'WARNING'
                          WHEN 5 THEN 'INFO'
                      END
                    LIMIT 1
                )
            )
            AND (
                -- 1회 실행
                x.REPT_CYCLE_CN = 'ONCE'
                OR (
                    x.REPT_CYCLE_CN LIKE 'REPEAT|%'
                    AND (
                        -- 매일 반복
                        x.REPT_CYCLE_CN LIKE 'REPEAT|DAILY|%'
                        OR (
                            -- 매주 지정 요일 반복
                            x.REPT_CYCLE_CN LIKE 'REPEAT|WEEKLY|%'
                            AND FIND_IN_SET(
                                ELT(
                                    WEEKDAY(CURRENT_TIMESTAMP()) + 1,
                                    'MON', 'TUE', 'WED', 'THU',
                                    'FRI', 'SAT', 'SUN'
                                ),
                                SUBSTRING_INDEX(x.REPT_CYCLE_CN, '|', -1)
                            ) > 0
                        )
                        OR (
                            -- 매월 시작일과 같은 일자 반복
                            x.REPT_CYCLE_CN LIKE 'REPEAT|MONTHLY|%'
                            AND DAYOFMONTH(CURRENT_TIMESTAMP())
                                = DAYOFMONTH(x.BGNG_DT)
                        )
                    )
                    AND (
                        -- 시간 제한이 없거나, 같은 날/자정 넘김 구간에 해당
                        x.REPT_START_TM IS NULL
                        OR x.REPT_END_TM IS NULL
                        OR (
                            x.REPT_START_TM <= x.REPT_END_TM
                            AND CAST(CURRENT_TIMESTAMP() AS TIME)
                                BETWEEN x.REPT_START_TM AND x.REPT_END_TM
                        )
                        OR (
                            x.REPT_START_TM > x.REPT_END_TM
                            AND (
                                CAST(CURRENT_TIMESTAMP() AS TIME) >= x.REPT_START_TM
                                OR CAST(CURRENT_TIMESTAMP() AS TIME) <= x.REPT_END_TM
                            )
                        )
                    )
                )
            )
          LIMIT 1
      )

    GROUP BY q.ems_id, q.device_id
) f
    ON f.ems_id = d.ems_id
   AND f.device_id = d.device_id

WHERE d.use_yn = 'Y'
  AND d.ems_id IN (1, 4, 11, 13, 16);

DROP VIEW IF EXISTS vw_tnms_device_status;
DROP VIEW IF EXISTS vw_tnms_active_fault_summary;
DROP VIEW IF EXISTS vw_tnms_device_performance;
DROP VIEW IF EXISTS vw_tnms_device_base;
DROP VIEW IF EXISTS vw_tnms_system_map;
