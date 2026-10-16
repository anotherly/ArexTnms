-- ============================================================================
-- TNMS 화면 표출용 테스트 데이터 갱신 프로시저 / 5분 이벤트
-- 대상: MariaDB 10.6
-- 목적: eqpmnt_stts / eqpmnt_perf_stts "현재값"만 UPSERT하여 화면 테스트용 데이터를 유지
-- 주의: 운영 연계 수집기가 붙은 DB에서는 실행하지 마십시오. 실제 수집값을 덮어쓸 수 있습니다.
--      이 스크립트는 장애이력(dsblty_info) 같은 누적 이력 테이블에는 5분마다 INSERT하지 않습니다.
-- ============================================================================

-- 이벤트 스케줄러 상태 확인
SHOW VARIABLES LIKE 'event_scheduler';
-- OFF인 경우 DB 관리자 권한으로 1회 실행:
-- SET GLOBAL event_scheduler = ON;

DROP EVENT IF EXISTS ev_tnms_ui_test_refresh_5m;
DROP PROCEDURE IF EXISTS sp_tnms_ui_test_refresh;

DELIMITER $$

CREATE PROCEDURE sp_tnms_ui_test_refresh()
BEGIN
    DECLARE v_tick BIGINT DEFAULT FLOOR(UNIX_TIMESTAMP(NOW()) / 300);

    /*
      1) 5개 설비 시스템 현재 상태 갱신
         - 김포공항(AREX06): 시스템별 대표 1대 CRITICAL -> 역사 대표색 심각 확인
         - 계양(AREX07): 시스템별 대표 1대 CAUTION -> 역사 대표색 주의 확인
         - 일부 장비 UNKNOWN/CAUTION을 섞고 나머지는 NORMAL
         - PK(EQPMNT_SN) UPSERT이므로 행 수가 계속 증가하지 않음
    */
    INSERT INTO eqpmnt_stts
        (EQPMNT_SN, CNTN_YN, PING_RSPNS_MS, STTS_CD, STTS_EXPLN, LAST_RSPNS_DT, CLCT_DT)
    SELECT
        E.EQPMNT_SN,
        CASE
            WHEN MOD(E.EQPMNT_SN + v_tick, 113) = 0 THEN 'N'
            ELSE 'Y'
        END AS CNTN_YN,
        CASE
            WHEN MOD(E.EQPMNT_SN + v_tick, 113) = 0 THEN NULL
            ELSE 8 + MOD(E.EQPMNT_SN + v_tick, 35)
        END AS PING_RSPNS_MS,
        CASE
            WHEN E.STN_CD = 'AREX06' AND R.REP_SN = E.EQPMNT_SN THEN 'CRITICAL'
            WHEN E.STN_CD = 'AREX07' AND R.REP_SN = E.EQPMNT_SN THEN 'CAUTION'
            WHEN MOD(E.EQPMNT_SN + v_tick, 113) = 0 THEN 'UNKNOWN'
            WHEN MOD(E.EQPMNT_SN + v_tick, 47) = 0 THEN 'CAUTION'
            ELSE 'NORMAL'
        END AS STTS_CD,
        CASE
            WHEN E.STN_CD = 'AREX06' AND R.REP_SN = E.EQPMNT_SN THEN '화면 테스트용 심각 상태'
            WHEN E.STN_CD = 'AREX07' AND R.REP_SN = E.EQPMNT_SN THEN '화면 테스트용 주의 상태'
            WHEN MOD(E.EQPMNT_SN + v_tick, 113) = 0 THEN '화면 테스트용 통신단절'
            WHEN MOD(E.EQPMNT_SN + v_tick, 47) = 0 THEN '화면 테스트용 임계치 주의'
            ELSE '정상 수신'
        END AS STTS_EXPLN,
        NOW(),
        NOW()
    FROM eqpmnt_info E
    LEFT JOIN (
        SELECT STN_CD, LINK_SYS_CD, MIN(EQPMNT_SN) AS REP_SN
          FROM eqpmnt_info
         WHERE USE_YN = 'Y'
           AND LINK_SYS_CD IN ('EMS_TX', 'EMS_PIDS', 'SCADA_SEC', 'PBX', 'VMS')
         GROUP BY STN_CD, LINK_SYS_CD
    ) R
      ON R.STN_CD = E.STN_CD
     AND R.LINK_SYS_CD = E.LINK_SYS_CD
    WHERE E.USE_YN = 'Y'
      AND E.LINK_SYS_CD IN ('EMS_TX', 'EMS_PIDS', 'SCADA_SEC', 'PBX', 'VMS')
    ON DUPLICATE KEY UPDATE
        CNTN_YN      = VALUES(CNTN_YN),
        PING_RSPNS_MS= VALUES(PING_RSPNS_MS),
        STTS_CD      = VALUES(STTS_CD),
        STTS_EXPLN   = VALUES(STTS_EXPLN),
        LAST_RSPNS_DT= VALUES(LAST_RSPNS_DT),
        CLCT_DT      = VALUES(CLCT_DT);

    /*
      2) CPU / MEMORY 현재값 갱신
         - perf_idct_info에 실제 등록된 지표만 JOIN
         - PK(EQPMNT_SN, PERF_IDCT_CD) UPSERT -> 누적 증가 없음
    */
    INSERT INTO eqpmnt_perf_stts
        (EQPMNT_SN, PERF_IDCT_CD, MSRMT_VL, LTR_VL, UNIT_NM, STTS_CD, CLCT_DT)
    SELECT
        E.EQPMNT_SN,
        P.PERF_IDCT_CD,
        CASE P.PERF_IDCT_CD
            WHEN 'CPU_USGRT'  THEN 15 + MOD(E.EQPMNT_SN * 7  + v_tick, 60)
            WHEN 'MMRY_USGRT' THEN 25 + MOD(E.EQPMNT_SN * 11 + v_tick, 60)
        END AS MSRMT_VL,
        NULL,
        '%',
        'NORMAL',
        NOW()
    FROM eqpmnt_info E
    JOIN perf_idct_info P
      ON P.PERF_IDCT_CD IN ('CPU_USGRT', 'MMRY_USGRT')
    WHERE E.USE_YN = 'Y'
      AND E.LINK_SYS_CD IN ('EMS_TX', 'EMS_PIDS', 'SCADA_SEC', 'PBX', 'VMS')
    ON DUPLICATE KEY UPDATE
        MSRMT_VL = VALUES(MSRMT_VL),
        LTR_VL   = VALUES(LTR_VL),
        UNIT_NM  = VALUES(UNIT_NM),
        STTS_CD  = VALUES(STTS_CD),
        CLCT_DT  = VALUES(CLCT_DT);

    /* 3) 전송설비 Interface 사용/전체 포트 테스트값 */
    INSERT INTO eqpmnt_perf_stts
        (EQPMNT_SN, PERF_IDCT_CD, MSRMT_VL, LTR_VL, UNIT_NM, STTS_CD, CLCT_DT)
    SELECT
        E.EQPMNT_SN,
        P.PERF_IDCT_CD,
        CASE
            WHEN P.PERF_IDCT_CD = 'IF_TOTAL_NOCS' THEN 16
            ELSE 10 + MOD(E.EQPMNT_SN + v_tick, 7)
        END AS MSRMT_VL,
        NULL,
        'port',
        'NORMAL',
        NOW()
    FROM eqpmnt_info E
    JOIN perf_idct_info P
      ON P.PERF_IDCT_CD IN ('IF_USE_NOCS', 'IF_TOTAL_NOCS')
    WHERE E.USE_YN = 'Y'
      AND E.LINK_SYS_CD = 'EMS_TX'
    ON DUPLICATE KEY UPDATE
        MSRMT_VL = VALUES(MSRMT_VL),
        LTR_VL   = VALUES(LTR_VL),
        UNIT_NM  = VALUES(UNIT_NM),
        STTS_CD  = VALUES(STTS_CD),
        CLCT_DT  = VALUES(CLCT_DT);
END$$

DELIMITER ;

-- 최초 1회 즉시 반영
CALL sp_tnms_ui_test_refresh();

-- 5분마다 실행
CREATE EVENT ev_tnms_ui_test_refresh_5m
    ON SCHEDULE EVERY 5 MINUTE
    STARTS CURRENT_TIMESTAMP + INTERVAL 5 MINUTE
    ON COMPLETION PRESERVE
    ENABLE
    DO CALL sp_tnms_ui_test_refresh();

-- 확인
SHOW EVENTS WHERE Name = 'ev_tnms_ui_test_refresh_5m';

-- 중지할 때:
-- ALTER EVENT ev_tnms_ui_test_refresh_5m DISABLE;
-- 완전 삭제할 때:
-- DROP EVENT IF EXISTS ev_tnms_ui_test_refresh_5m;
-- DROP PROCEDURE IF EXISTS sp_tnms_ui_test_refresh;
