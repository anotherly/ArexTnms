-- ============================================================
-- AREX TNMS 지도 대시보드 상태 확인용 샘플 데이터 갱신
-- 기준: DASHBOARD_OFFLINE_MIN 설정값을 그대로 적용함.
-- 현재 설정이 5분이면 이 SQL 실행 후 5분 동안 신규 수집이 없을 경우
-- 다시 통신단절(UNKNOWN)로 보이는 것이 정상 동작임.
-- 실제 운영에서는 EMS/수집 프로세스가 CLCT_DT를 지속 갱신해야 함.
-- ============================================================

-- 김포공항(AREX06): 심각 상태 확인용
UPDATE eqpmnt_stts S
JOIN eqpmnt_info E ON E.EQPMNT_SN = S.EQPMNT_SN
SET S.CNTN_YN       = 'Y',
    S.STTS_CD       = 'CRITICAL',
    S.STTS_EXPLN    = '김포공항 심각 상태 확인용',
    S.LAST_RSPNS_DT = NOW(),
    S.CLCT_DT       = NOW()
WHERE E.EQPMNT_MNG_NO = 'UIUX-SAMPLE-VMS-01'
  AND E.STN_CD = 'AREX06'
  AND E.USE_YN = 'Y';

-- 계양(AREX07): 주의 상태 확인용
UPDATE eqpmnt_stts S
JOIN eqpmnt_info E ON E.EQPMNT_SN = S.EQPMNT_SN
SET S.CNTN_YN       = 'Y',
    S.STTS_CD       = 'CAUTION',
    S.STTS_EXPLN    = '계양 주의 상태 확인용',
    S.LAST_RSPNS_DT = NOW(),
    S.CLCT_DT       = NOW()
WHERE E.EQPMNT_MNG_NO = 'UIUX-SAMPLE-VMS-03'
  AND E.STN_CD = 'AREX07'
  AND E.USE_YN = 'Y';

-- 설정값/샘플 상태 확인
SELECT UI_STNG_CD, UI_STNG_VL
  FROM ui_stng_info
 WHERE UI_STNG_CD IN ('DASHBOARD_OFFLINE_MIN', 'STATION_STATUS_PRIORITY')
 ORDER BY UI_STNG_CD;

SELECT E.STN_CD, E.EQPMNT_MNG_NO, E.EQPMNT_NM,
       S.CNTN_YN, S.STTS_CD, S.STTS_EXPLN, S.CLCT_DT
  FROM eqpmnt_info E
  JOIN eqpmnt_stts S ON S.EQPMNT_SN = E.EQPMNT_SN
 WHERE E.EQPMNT_MNG_NO IN ('UIUX-SAMPLE-VMS-01', 'UIUX-SAMPLE-VMS-03')
 ORDER BY E.STN_CD;
