-- TNMS 2026-11-10: WEB 조회용 코드 매핑 및 역할별 VIEW (MariaDB 11.8)
-- 1) 본 작업은 web_link_sys_info + WEB 조회 VIEW만 변경합니다. raw_/com_ 원본 테이블은 변경하지 않습니다.
-- 2) 사전에 전체 덤프 백업, 검증 SQL 실행, Tomcat 배포 중지/점검시간 지정 권장.
-- 3) 현재 web_link_sys_info.LINK_SYS_CD는 권한/FK/화면 계약으로 유지하고, GW EMS_ID 연계만 CD_DVIC를 사용합니다.
USE `tnms`;

-- ALTER로 추가되는 컬럼은 WEB 소유 테이블 한 곳뿐입니다.
ALTER TABLE web_link_sys_info
    ADD COLUMN IF NOT EXISTS DEVICE_COM_CD CHAR(11) NULL COMMENT 'CD_DVIC 공통코드 연계값';

-- 최초 1회 매핑. 런타임 CASE 하드코딩이 아니라 공통코드를 가리키는 관계 데이터입니다.
UPDATE web_link_sys_info SET DEVICE_COM_CD='CD_DVIC_001' WHERE LINK_SYS_CD='EMS_TX'  AND (DEVICE_COM_CD IS NULL OR DEVICE_COM_CD='CD_DVIC_001');
UPDATE web_link_sys_info SET DEVICE_COM_CD='CD_DVIC_002' WHERE LINK_SYS_CD='EMS_PIDS' AND (DEVICE_COM_CD IS NULL OR DEVICE_COM_CD='CD_DVIC_002');
UPDATE web_link_sys_info SET DEVICE_COM_CD='CD_DVIC_003' WHERE LINK_SYS_CD='SCADA_SEC' AND (DEVICE_COM_CD IS NULL OR DEVICE_COM_CD='CD_DVIC_003');
UPDATE web_link_sys_info SET DEVICE_COM_CD='CD_DVIC_004' WHERE LINK_SYS_CD='PBX' AND (DEVICE_COM_CD IS NULL OR DEVICE_COM_CD='CD_DVIC_004');
UPDATE web_link_sys_info SET DEVICE_COM_CD='CD_DVIC_005' WHERE LINK_SYS_CD='VMS' AND (DEVICE_COM_CD IS NULL OR DEVICE_COM_CD='CD_DVIC_005');

-- 신규 매핑 5건 확인. 아래 결과가 5행/EMS별 중복 0이어야 다음 CREATE VIEW를 실행합니다.
SELECT C.COM_CD, C.COM_CD_NM, C.GW_CD, L.LINK_SYS_CD
  FROM com_cd_info C JOIN web_link_sys_info L ON L.DEVICE_COM_CD=C.COM_CD
 WHERE C.COM_CD_GROUP_ID='CD_DVIC' AND C.GW_SRC_COL='ems_id' AND C.COM_CD_USE_YN='Y' AND L.USE_YN='Y'
 ORDER BY C.COM_CD_SEQ;

-- 권한/메뉴에 쓰는 기존 LINK_SYS_CD는 유지. EMS_ID 매핑의 근거는 공통코드 GW_CD 한 곳.
CREATE OR REPLACE ALGORITHM=UNDEFINED SQL SECURITY INVOKER VIEW vw_tnms_system_map AS
SELECT CAST(C.GW_CD AS UNSIGNED) AS ems_id,
       C.COM_CD AS device_com_cd, C.COM_CD_NM AS device_com_nm,
       C.COM_CD_SEQ AS sort_seq, L.LINK_SYS_CD AS link_sys_cd,
       L.LINK_SYS_NM AS link_sys_nm, L.PROTCL_CD AS protcl_cd
  FROM com_cd_info C
  JOIN web_link_sys_info L ON L.DEVICE_COM_CD=C.COM_CD AND L.USE_YN='Y'
 WHERE C.COM_CD_GROUP_ID='CD_DVIC' AND C.GW_SRC_COL='ems_id'
   AND C.COM_CD_USE_YN='Y' AND C.GW_CD REGEXP '^[0-9]+$';

CREATE OR REPLACE ALGORITHM=UNDEFINED SQL SECURITY INVOKER VIEW vw_tnms_device_base AS
SELECT D.ems_id, D.device_id, D.device_nm, D.device_type, D.device_ip,
       D.device_station, D.stn_cd, D.device_desc, D.device_model,
       D.server_ip, D.device_maker, D.device_check, D.test_yn,
       D.ping_alive, D.ping_dt,
       M.link_sys_cd, M.device_com_cd
  FROM com_device_info D
  JOIN vw_tnms_system_map M ON M.ems_id=D.ems_id
 WHERE D.use_yn='Y';

CREATE OR REPLACE ALGORITHM=UNDEFINED SQL SECURITY INVOKER VIEW vw_tnms_device_performance AS
SELECT D.*, U.cpu_usage, U.memory_usage, U.disk_usage, U.reg_dt AS usage_dt,
       CASE WHEN U.reg_dt >= CURRENT_TIMESTAMP() - INTERVAL 5 MINUTE THEN 'Y' ELSE 'N' END AS usage_fresh_yn,
       CASE WHEN U.reg_dt >= CURRENT_TIMESTAMP() - INTERVAL 5 MINUTE THEN 'NORMAL' ELSE 'UNKNOWN' END AS stts_cd
  FROM vw_tnms_device_base D
  LEFT JOIN com_device_usage U ON U.ems_id=D.ems_id AND U.device_id=D.device_id;

-- 활성 장애만 집계. PING/성능 조회 시에는 이 VIEW가 실행되지 않습니다.
CREATE OR REPLACE ALGORITHM=UNDEFINED SQL SECURITY INVOKER VIEW vw_tnms_active_fault_summary AS
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

    GROUP BY q.ems_id, q.device_id;

-- 메인/역사 상태 전용: 성능 JOIN 없음. 설정값은 1행 서브쿼리(기본 5분).
CREATE OR REPLACE ALGORITHM=UNDEFINED SQL SECURITY INVOKER VIEW vw_tnms_device_status AS
SELECT D.*, F.fault_count, F.severe_grade, F.last_event_dt,
    CASE
        WHEN D.ping_dt IS NULL OR D.ping_alive=0 THEN 'UNKNOWN'
        WHEN TIMESTAMPDIFF(SECOND,D.ping_dt,CURRENT_TIMESTAMP()) >
            60 * GREATEST(1,COALESCE((SELECT CAST(UI_STNG_VL AS UNSIGNED)
                       FROM web_ui_stng_info WHERE UI_STNG_CD='DASHBOARD_OFFLINE_MIN'
                         AND USE_YN='Y' LIMIT 1),5)) THEN 'UNKNOWN'
        WHEN D.ping_alive=-1 THEN 'OFFLINE'
        WHEN D.ping_alive<>1 THEN 'UNKNOWN'
        WHEN F.severe_grade IN (1,2) THEN 'CRITICAL'
        WHEN F.severe_grade IN (3,4,5) THEN 'CAUTION'
        ELSE 'NORMAL'
    END AS stts_cd,
    CASE
        WHEN D.ping_alive=0 OR D.ping_dt IS NULL THEN 'PING 미확인'
        WHEN TIMESTAMPDIFF(SECOND,D.ping_dt,CURRENT_TIMESTAMP()) >
            60 * GREATEST(1,COALESCE((SELECT CAST(UI_STNG_VL AS UNSIGNED)
                       FROM web_ui_stng_info WHERE UI_STNG_CD='DASHBOARD_OFFLINE_MIN'
                         AND USE_YN='Y' LIMIT 1),5)) THEN 'PING 수집 지연'
        WHEN D.ping_alive=-1 THEN 'PING 실패'
        WHEN F.severe_grade IS NOT NULL THEN CONCAT('발생 장애(등급 ',F.severe_grade,')')
        ELSE '정상'
    END AS stts_expln
FROM vw_tnms_device_base D
LEFT JOIN vw_tnms_active_fault_summary F ON F.ems_id=D.ems_id AND F.device_id=D.device_id;

-- 기존 VIEW를 호출하는 외부 업무/이전 WAR 호환성 유지 (기존 인터페이스 그대로)
CREATE OR REPLACE ALGORITHM=UNDEFINED SQL SECURITY INVOKER VIEW vw_tnms_gateway_device_live AS
SELECT S.ems_id, S.device_id, S.device_nm, S.device_type, S.device_ip,
       S.device_station, S.stn_cd, S.device_desc, S.device_model,
       S.server_ip, S.device_maker, S.device_check, S.test_yn,
       S.ping_alive, S.ping_dt, S.link_sys_cd,
       P.cpu_usage, P.memory_usage, P.disk_usage, P.usage_dt,
       S.fault_count, S.severe_grade, S.last_event_dt,
       P.usage_fresh_yn, S.stts_cd, S.stts_expln
  FROM vw_tnms_device_status S
  LEFT JOIN vw_tnms_device_performance P
    ON P.ems_id=S.ems_id AND P.device_id=S.device_id;
