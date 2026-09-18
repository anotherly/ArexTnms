/*
 * AREX TNMS UI/UX 화면 표시 확인용 샘플 데이터
 * 선행 필수: 260917_UIUX_DB_01_SCHEMA.sql
 *
 * tnms 260917.sql에 이미 존재하는 UIUX-SAMPLE-* 데이터를 보강합니다.
 * 동일 스크립트를 재실행해도 장비/이벤트가 중복 생성되지 않도록 작성했습니다.
 */

/* --------------------------------------------------------------------------
 * 1. 행선안내: 기획 화면에서 HSE / LSE / 표시장치 및 '연결 LSE'가 보이도록 보강
 * -------------------------------------------------------------------------- */
INSERT INTO `eqpmnt_info`
(`EQPMNT_MNG_NO`,`EQPMNT_NM`,`EQPMNT_SE_CD`,`EQPMNT_CLSF_CD`,`LINK_SYS_CD`,`EMS_ID`,`STN_CD`,
 `INSTL_PLC_NM`,`EQPMNT_IP_ADDR`,`EQPMNT_MDL_NM`,`PING_MNTR_YN`,`PING_CYCLE_SEC`,`EQPMNT_EXPLN`,
 `USE_YN`,`REG_DT`,`RGTR_ID`)
SELECT 'UIUX-SAMPLE-PIDS-LSE-01','김포공항 LSE 01','LSE',NULL,'EMS_PIDS','LSE-GMP-01','AREX06',
       '통신기계실','192.168.10.133','PIDS-LSE','Y',30,'UI/UX 화면 표시 확인용 LSE 샘플','Y',NOW(),'SYSTEM'
WHERE NOT EXISTS (SELECT 1 FROM `eqpmnt_info` WHERE `EQPMNT_MNG_NO`='UIUX-SAMPLE-PIDS-LSE-01');

INSERT INTO `eqpmnt_info`
(`EQPMNT_MNG_NO`,`EQPMNT_NM`,`EQPMNT_SE_CD`,`EQPMNT_CLSF_CD`,`LINK_SYS_CD`,`EMS_ID`,`STN_CD`,
 `INSTL_PLC_NM`,`EQPMNT_IP_ADDR`,`EQPMNT_MDL_NM`,`PING_MNTR_YN`,`PING_CYCLE_SEC`,`EQPMNT_EXPLN`,
 `USE_YN`,`REG_DT`,`RGTR_ID`)
SELECT 'UIUX-SAMPLE-PIDS-HSE-01','행선안내 HSE Main','HSE',NULL,'EMS_PIDS','HSE-MAIN-01','AREX06',
       '통신기계실','192.168.10.134','PIDS-HSE','Y',30,'UI/UX 화면 표시 확인용 HSE 샘플','Y',NOW(),'SYSTEM'
WHERE NOT EXISTS (SELECT 1 FROM `eqpmnt_info` WHERE `EQPMNT_MNG_NO`='UIUX-SAMPLE-PIDS-HSE-01');

/* 표시장치 2대 -> LSE 1대 연결 */
INSERT INTO `pids_eqpmnt_lse_rel` (`EQPMNT_SN`,`LSE_EQPMNT_SN`,`REG_DT`)
SELECT P.`EQPMNT_SN`, L.`EQPMNT_SN`, NOW()
  FROM `eqpmnt_info` P
  JOIN `eqpmnt_info` L ON L.`EQPMNT_MNG_NO`='UIUX-SAMPLE-PIDS-LSE-01'
 WHERE P.`EQPMNT_MNG_NO` IN ('UIUX-SAMPLE-PIDS-01','UIUX-SAMPLE-PIDS-02')
ON DUPLICATE KEY UPDATE `REG_DT`=VALUES(`REG_DT`);

/* --------------------------------------------------------------------------
 * 2. 장비 상태: 신규 LSE/HSE가 통신단절이 아니라 정상으로 보이게 현재 상태 추가
 * -------------------------------------------------------------------------- */
INSERT INTO `eqpmnt_stts`
(`EQPMNT_SN`,`CNTN_YN`,`PING_RSPNS_MS`,`STTS_CD`,`STTS_EXPLN`,`LAST_RSPNS_DT`,`CLCT_DT`)
SELECT E.`EQPMNT_SN`,'Y',12,'NORMAL','정상 수신',NOW(),NOW()
  FROM `eqpmnt_info` E
 WHERE E.`EQPMNT_MNG_NO` IN ('UIUX-SAMPLE-PIDS-LSE-01','UIUX-SAMPLE-PIDS-HSE-01')
ON DUPLICATE KEY UPDATE
 `CNTN_YN`='Y',`PING_RSPNS_MS`=VALUES(`PING_RSPNS_MS`),`STTS_CD`='NORMAL',
 `STTS_EXPLN`='정상 수신',`LAST_RSPNS_DT`=NOW(),`CLCT_DT`=NOW();

/* --------------------------------------------------------------------------
 * 3. CPU / Memory: 기존 eqpmnt_perf_stts 구조 사용
 * -------------------------------------------------------------------------- */
INSERT INTO `eqpmnt_perf_stts`
(`EQPMNT_SN`,`PERF_IDCT_CD`,`MSRMT_VL`,`LTR_VL`,`UNIT_NM`,`STTS_CD`,`CLCT_DT`)
SELECT E.`EQPMNT_SN`, V.`PERF_IDCT_CD`, V.`MSRMT_VL`, NULL, '%', 'NORMAL', NOW()
  FROM `eqpmnt_info` E
  CROSS JOIN (
        SELECT 'CPU_USGRT' AS `PERF_IDCT_CD`, 24.700000 AS `MSRMT_VL`
        UNION ALL SELECT 'MMRY_USGRT', 41.300000
  ) V
 WHERE E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-PIDS-LSE-01'
ON DUPLICATE KEY UPDATE `MSRMT_VL`=VALUES(`MSRMT_VL`),`UNIT_NM`='%',`STTS_CD`='NORMAL',`CLCT_DT`=NOW();

INSERT INTO `eqpmnt_perf_stts`
(`EQPMNT_SN`,`PERF_IDCT_CD`,`MSRMT_VL`,`LTR_VL`,`UNIT_NM`,`STTS_CD`,`CLCT_DT`)
SELECT E.`EQPMNT_SN`, V.`PERF_IDCT_CD`, V.`MSRMT_VL`, NULL, '%', 'NORMAL', NOW()
  FROM `eqpmnt_info` E
  CROSS JOIN (
        SELECT 'CPU_USGRT' AS `PERF_IDCT_CD`, 19.800000 AS `MSRMT_VL`
        UNION ALL SELECT 'MMRY_USGRT', 36.500000
  ) V
 WHERE E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-PIDS-HSE-01'
ON DUPLICATE KEY UPDATE `MSRMT_VL`=VALUES(`MSRMT_VL`),`UNIT_NM`='%',`STTS_CD`='NORMAL',`CLCT_DT`=NOW();

/* 전송 장비 CPU/Memory 값을 기획 화면에서 확인하기 좋은 값으로 보강 */
INSERT INTO `eqpmnt_perf_stts`
(`EQPMNT_SN`,`PERF_IDCT_CD`,`MSRMT_VL`,`LTR_VL`,`UNIT_NM`,`STTS_CD`,`CLCT_DT`)
SELECT E.`EQPMNT_SN`, V.`PERF_IDCT_CD`,
       CASE WHEN E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-TX-01' AND V.`PERF_IDCT_CD`='CPU_USGRT' THEN 42.5
            WHEN E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-TX-01' THEN 57.2
            WHEN V.`PERF_IDCT_CD`='CPU_USGRT' THEN 31.8 ELSE 48.4 END,
       NULL, '%', 'NORMAL', NOW()
  FROM `eqpmnt_info` E
  CROSS JOIN (SELECT 'CPU_USGRT' AS `PERF_IDCT_CD` UNION ALL SELECT 'MMRY_USGRT') V
 WHERE E.`EQPMNT_MNG_NO` IN ('UIUX-SAMPLE-TX-01','UIUX-SAMPLE-TX-02')
ON DUPLICATE KEY UPDATE `MSRMT_VL`=VALUES(`MSRMT_VL`),`UNIT_NM`='%',`STTS_CD`='NORMAL',`CLCT_DT`=NOW();

/* --------------------------------------------------------------------------
 * 4. 전송설비 Interface 10 / 12 및 논리 연결관계 표시
 * -------------------------------------------------------------------------- */
INSERT INTO `eqpmnt_perf_stts`
(`EQPMNT_SN`,`PERF_IDCT_CD`,`MSRMT_VL`,`LTR_VL`,`UNIT_NM`,`STTS_CD`,`CLCT_DT`)
SELECT E.`EQPMNT_SN`, V.`PERF_IDCT_CD`,
       CASE
         WHEN E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-TX-01' AND V.`PERF_IDCT_CD`='IF_USE_NOCS' THEN 6
         WHEN E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-TX-01' AND V.`PERF_IDCT_CD`='IF_TOTAL_NOCS' THEN 8
         WHEN E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-TX-02' AND V.`PERF_IDCT_CD`='IF_USE_NOCS' THEN 4
         ELSE 4
       END,
       NULL, 'port', 'NORMAL', NOW()
  FROM `eqpmnt_info` E
  CROSS JOIN (SELECT 'IF_USE_NOCS' AS `PERF_IDCT_CD` UNION ALL SELECT 'IF_TOTAL_NOCS') V
 WHERE E.`EQPMNT_MNG_NO` IN ('UIUX-SAMPLE-TX-01','UIUX-SAMPLE-TX-02')
ON DUPLICATE KEY UPDATE `MSRMT_VL`=VALUES(`MSRMT_VL`),`UNIT_NM`='port',`STTS_CD`='NORMAL',`CLCT_DT`=NOW();

INSERT INTO `eqpmnt_lnk_rel`
(`FROM_EQPMNT_SN`,`TO_EQPMNT_SN`,`LINK_TYPE_CD`,`LINK_NM`,`USE_YN`,`REG_DT`)
SELECT F.`EQPMNT_SN`, T.`EQPMNT_SN`, 'LOGICAL', '김포공항 주 전송 링크', 'Y', NOW()
  FROM `eqpmnt_info` F
  JOIN `eqpmnt_info` T ON T.`EQPMNT_MNG_NO`='UIUX-SAMPLE-TX-02'
 WHERE F.`EQPMNT_MNG_NO`='UIUX-SAMPLE-TX-01'
ON DUPLICATE KEY UPDATE `LINK_NM`=VALUES(`LINK_NM`),`USE_YN`='Y',`MDFCN_DT`=NOW();

/* 관리메모가 상세/수정화면에서 바로 보이도록 기존 샘플 설명 보강 */
UPDATE `eqpmnt_info`
   SET `EQPMNT_EXPLN` = CASE `EQPMNT_MNG_NO`
       WHEN 'UIUX-SAMPLE-TX-01' THEN '김포공항역 전송 주 스위치 / 인터페이스 및 CPU·Memory 표시 확인용'
       WHEN 'UIUX-SAMPLE-TX-02' THEN '김포공항역 광전송 장치 / 논리 구성도 연결 확인용'
       WHEN 'UIUX-SAMPLE-PIDS-01' THEN '승강장 표시장치 / LSE 복수 연결 저장·조회 확인용'
       WHEN 'UIUX-SAMPLE-PIDS-02' THEN '대합실 표시장치 / LSE 연결정보 표시 확인용'
       ELSE `EQPMNT_EXPLN` END,
       `MDFCN_DT`=NOW(), `MDFR_ID`='SYSTEM'
 WHERE `EQPMNT_MNG_NO` IN ('UIUX-SAMPLE-TX-01','UIUX-SAMPLE-TX-02','UIUX-SAMPLE-PIDS-01','UIUX-SAMPLE-PIDS-02');

/* --------------------------------------------------------------------------
 * 5. CCTV: 층 / 카메라 수가 화면에 표시되도록 기존 샘플 상세정보 보강
 * -------------------------------------------------------------------------- */
INSERT INTO `cctv_info`
(`EQPMNT_SN`,`NEW_LBL_NM`,`LBL_NM`,`FLR_NM`,`CMRA_QTY`,`RSRV_YN`,`REG_DT`,`MDFCN_DT`)
SELECT E.`EQPMNT_SN`,NULL,'UIUX-CCTV-01','B2',8,'N',NOW(),NOW()
  FROM `eqpmnt_info` E WHERE E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-VMS-01'
ON DUPLICATE KEY UPDATE `FLR_NM`='B2',`CMRA_QTY`=8,`RSRV_YN`='N',`MDFCN_DT`=NOW();

INSERT INTO `cctv_info`
(`EQPMNT_SN`,`NEW_LBL_NM`,`LBL_NM`,`FLR_NM`,`CMRA_QTY`,`RSRV_YN`,`REG_DT`,`MDFCN_DT`)
SELECT E.`EQPMNT_SN`,NULL,'UIUX-CCTV-02','B2',6,'N',NOW(),NOW()
  FROM `eqpmnt_info` E WHERE E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-VMS-02'
ON DUPLICATE KEY UPDATE `FLR_NM`='B2',`CMRA_QTY`=6,`RSRV_YN`='N',`MDFCN_DT`=NOW();

/* --------------------------------------------------------------------------
 * 6. 교환기: 설비명 / 구성품 / MTBF가 상세 및 표에 보이도록 샘플 보강
 * -------------------------------------------------------------------------- */
INSERT INTO `pbx_info`
(`EQPMNT_SN`,`EQPM_NM`,`CMPNT_NM`,`MTBF_HR`,`RMRK_CN`,`REG_DT`,`MDFCN_DT`)
SELECT E.`EQPMNT_SN`,'교환설비','Media Gateway',87600,'UI/UX 화면 표시 확인용',NOW(),NOW()
  FROM `eqpmnt_info` E WHERE E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-PBX-01'
ON DUPLICATE KEY UPDATE `EQPM_NM`='교환설비',`CMPNT_NM`='Media Gateway',`MTBF_HR`=87600,`MDFCN_DT`=NOW();

INSERT INTO `pbx_info`
(`EQPMNT_SN`,`EQPM_NM`,`CMPNT_NM`,`MTBF_HR`,`RMRK_CN`,`REG_DT`,`MDFCN_DT`)
SELECT E.`EQPMNT_SN`,'교환설비','L2 POE스위치',87600,'UI/UX 화면 표시 확인용',NOW(),NOW()
  FROM `eqpmnt_info` E WHERE E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-PBX-02'
ON DUPLICATE KEY UPDATE `EQPM_NM`='교환설비',`CMPNT_NM`='L2 POE스위치',`MTBF_HR`=87600,`MDFCN_DT`=NOW();

/* --------------------------------------------------------------------------
 * 7. SCADA: 최근 출입이벤트 카드에 실제 DB 데이터가 보이도록 샘플 추가
 * -------------------------------------------------------------------------- */
INSERT INTO `enex_evnt_hstry`
(`EQPMNT_SN`,`EVNT_CD`,`EVNT_NM`,`ENEX_DT`,`ENEX_RSLT_CD`,`APRV_YN`,`CARD_NO_HASH`,`EVNT_CN`,`CLCT_DT`)
SELECT E.`EQPMNT_SN`,'UIUX_DOOR_OPEN','출입문 개방',DATE_SUB(NOW(),INTERVAL 2 MINUTE),'SUCCESS','Y',NULL,
       '김포공항역 역무실 정상 출입 이벤트',NOW()
  FROM `eqpmnt_info` E
 WHERE E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-SCADA-01'
   AND NOT EXISTS (
       SELECT 1 FROM `enex_evnt_hstry` H
        WHERE H.`EQPMNT_SN`=E.`EQPMNT_SN` AND H.`EVNT_CD`='UIUX_DOOR_OPEN'
   );

INSERT INTO `enex_evnt_hstry`
(`EQPMNT_SN`,`EVNT_CD`,`EVNT_NM`,`ENEX_DT`,`ENEX_RSLT_CD`,`APRV_YN`,`CARD_NO_HASH`,`EVNT_CN`,`CLCT_DT`)
SELECT E.`EQPMNT_SN`,'UIUX_DOOR_DENIED','미승인 출입 시도',DATE_SUB(NOW(),INTERVAL 7 MINUTE),'DENIED','N',NULL,
       '김포공항역 보안구역 미승인 출입 확인용 이벤트',NOW()
  FROM `eqpmnt_info` E
 WHERE E.`EQPMNT_MNG_NO`='UIUX-SAMPLE-SCADA-02'
   AND NOT EXISTS (
       SELECT 1 FROM `enex_evnt_hstry` H
        WHERE H.`EQPMNT_SN`=E.`EQPMNT_SN` AND H.`EVNT_CD`='UIUX_DOOR_DENIED'
   );

/* --------------------------------------------------------------------------
 * 8. 사용자별 알림 읽음 샘플
 * admin/admin1으로 로그인했을 때 읽음 탭도 비어 있지 않도록 계정신청 알림 1건을 읽음 처리합니다.
 * 실제 알림 원천 데이터는 변경하지 않습니다.
 * -------------------------------------------------------------------------- */
INSERT INTO `user_ntcn_read_info` (`USER_ID`,`NTCN_ID`,`READ_DT`)
SELECT U.`USER_ID`, CONCAT('ACCOUNT:', A.`APLY_NO`), NOW()
  FROM `user_info` U
  CROSS JOIN (SELECT `APLY_NO` FROM `user_acnt_aply_info` ORDER BY `APLY_DT` DESC LIMIT 1) A
 WHERE U.`USER_ID` IN ('admin','admin1')
ON DUPLICATE KEY UPDATE `READ_DT`=VALUES(`READ_DT`);

/* 확인용 조회 */
SELECT E.`EQPMNT_MNG_NO`, E.`EQPMNT_NM`, E.`EQPMNT_SE_CD`, E.`LINK_SYS_CD`, E.`STN_CD`,
       S.`STTS_CD`, CPU.`MSRMT_VL` AS `CPU_USGRT`, MMRY.`MSRMT_VL` AS `MMRY_USGRT`,
       IFU.`MSRMT_VL` AS `IF_USE_NOCS`, IFT.`MSRMT_VL` AS `IF_TOTAL_NOCS`, E.`EQPMNT_EXPLN`
  FROM `eqpmnt_info` E
  LEFT JOIN `eqpmnt_stts` S ON S.`EQPMNT_SN`=E.`EQPMNT_SN`
  LEFT JOIN `eqpmnt_perf_stts` CPU ON CPU.`EQPMNT_SN`=E.`EQPMNT_SN` AND CPU.`PERF_IDCT_CD`='CPU_USGRT'
  LEFT JOIN `eqpmnt_perf_stts` MMRY ON MMRY.`EQPMNT_SN`=E.`EQPMNT_SN` AND MMRY.`PERF_IDCT_CD`='MMRY_USGRT'
  LEFT JOIN `eqpmnt_perf_stts` IFU ON IFU.`EQPMNT_SN`=E.`EQPMNT_SN` AND IFU.`PERF_IDCT_CD`='IF_USE_NOCS'
  LEFT JOIN `eqpmnt_perf_stts` IFT ON IFT.`EQPMNT_SN`=E.`EQPMNT_SN` AND IFT.`PERF_IDCT_CD`='IF_TOTAL_NOCS'
 WHERE E.`EQPMNT_MNG_NO` LIKE 'UIUX-SAMPLE-%'
 ORDER BY E.`EQPMNT_SN` DESC;
