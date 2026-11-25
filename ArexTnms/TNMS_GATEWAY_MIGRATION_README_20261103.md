# 공항철도 TNMS 게이트웨이 실데이터 조회 전환 — 1차 소스 수정본

기준: `ArexTnms(5).zip` 및 `tnms_full_20261103_140704.sql` (MariaDB 11.8.6, Ubuntu 26.04)

**주의: 소스 검토용 수정본입니다. 실제 DB 연결·Maven WAR 컴파일·화면 시연은 이 환경에서 수행하지 못했습니다. 바로 운영 반영하지 말고 개발서버에서 테스트하세요.**

## 변경 목표와 전제

- 데이터 원천: 게이트웨이(`raw_*`)는 **쓰기 금지**, 기존 4개 raw 트리거 유지
- EMS ID: 전송=1, 영상=4, 교환=11, 행선=13, SCADA=16 (`com_ems_info`)
- 장비 PK: `(ems_id,device_id)` 유지, 웹 `EQPMNT_SN`은 이 키와 무관
- PING: `1=성공`, `-1=실패`, `0=미확인`; 수집 지연은 `DASHBOARD_OFFLINE_MIN` 적용
- 최신 장비 성능: `com_device_usage`; 시간별/일별 추세 및 Raw: `raw_usage_log`
- 진행 중 장애: `raw_event_action` (`event_yn=1`); 이력: `raw_event_log`
- 공통코드: `com_cd_group_info`/`com_cd_info`, 그룹 7개 (`CD_DATA/CD_FALT/CD_DVIC/CD_JOBT/CD_PROS/CD_PROT/CD_SYST`), `GW_CD`/`GW_SRC_COL` 이용
- 화면 색상: `web_cd_color_info`에 분리. 기존 웹용 코드 확장 컬럼 `EXT1_CN`,`EXT2_CN`을 공통 DB에 다시 만들지 않음

## 적용 순서 (HeidiSQL 개발 DB)

1. 기존 전체 백업 확인 (`tnms_full_20261103_140704.sql.gz`) 및 별도 보관. **현 DB에 복원 명령 실행 금지**.
2. `com_cd_group_info`, `com_cd_info`에 7개 그룹·34개 상세 코드와 `GW_CD`, `GW_SRC_COL`이 존재하는지 확인하세요. 기존 SQL로 11개 그룹을 만들었다면 불필요한 네 그룹은 나중에 개별 검증 후 정리하세요.
3. `db/20261103_WEB_CODE_COLOR_CREATE.sql` 적용 — 웹 전용 색상 테이블 신규 생성, 공통코드 생성 완료 후 실행.
4. `db/20261103_GATEWAY_LIVE_READ_VIEWS.sql` 적용 — **조회용 뷰 1개 생성**. 원천 테이블·트리거·프로시저 수정 없음.
5. 수정 Java/JSP/JS/MyBatis 소스를 Eclipse 프로젝트에 반영한 뒤 Project > Clean 및 Maven 빌드, 개발서버 Tomcat에 WAR 배포.
6. 개발서버에서 테스트: 전송(1), 행선(13) 장비 목록·상태, 게이트웨이 PING 1/-1/0 변경, `raw_usage_log` 신규 INSERT 후 성능 정보, `raw_event_action` 신규 발생·해제 후 장애 목록(읽기 전용).
7. **실제 조회 확인 후** `db/20261103_DEMO_CLEANUP_REVIEW_ONLY.sql` 실행해 제거 대상을 점검하세요. 그 파일에는 DROP/DELETE 명령이 없습니다.

## 변경 소스 목록

- 신규 `gateway/mapper/GatewayLiveMapper.java` + `gateway/service/GatewayLiveService.java` + `gatewayLiveMapper.xml`:
  조회 권한 필터 적용, 장비·역사·EMS 집계, 원천 장애·성능·원본 통계 조회
- `MonitoringServiceImpl`, `MonitoringController`, `EquipmentVO`, `monitoringMapper.xml`: 장비 목록, 역사별 카드, 대시보드 조회, 게이트웨이 장비 상세 `(emsId,deviceId)` API
- `PerformanceServiceImpl`: 실시간 장비 성능, CPU·MEM 추세, Raw 성능 조회
- `FaultServiceImpl`: 현재 원천 장애와 이력 표시, 게이트웨이 장애 수정 요청 차단
- `SettingServiceImpl`, `SettingMapper`, `settingMapper.xml`, `setting/common-ui.js`: 신규 공통코드와 웹 전용 색상 조회/저장
- 설비·실시간장애·성능·원본 JS: 10초 간격 화면 재조회 (입력·모달 조작 중 보류), 게이트웨이 장비/장애 읽기 전용

## 기능 범위/남은 작업 (완료로 오해하지 마세요)

- **화면은 10초 폴링 방식**이며 WebSocket/SSE 기반 진정한 즉시 Push는 아닙니다. 게이트웨이가 DB에 데이터를 수집한 다음 다음 폴링에 반영됩니다.
- `com_device_usage`와 `raw_usage_log`에 현재 장비의 신규 수집값이 실제로 들어와야 성능값이 표시됩니다. 데이터가 없으면 0으로 꾸며 표시하지 않습니다.
- 게이트웨이 개발자가 새 장애·성능 테이블을 만든다고 했으므로 DDL이 확정되면 지금의 `raw_event_*`, `com_device_usage` 기반 조회를 최종 신규 테이블에 맞게 재검토해야 합니다.
- `EQPMNT_SN`에 묶인 웹 전용 부가정보(CCTV 카메라, 교환기 구성품, 행선 LSE 관계, 전송 링크 토폴로지)는 원천 `(ems_id,device_id)` 매핑이 확정되지 않아 임의 연결하지 않았습니다. **일부 기존 UI에서 이 관계 데이터가 나오지 않을 수 있습니다.**
- `web_dsblty_info`에 저장하던 사용자 조치(확인/완료/예외)는 게이트웨이 장애에서 **읽기 전용**입니다. 웹 전용 조치 테이블과 `(ems_id,device_id,event_id)`의 안정적인 연동 및 CRUD 설계가 필요합니다.
- `performance/cycle`, `performance/threshold`, `performance/raw`의 인터페이스 탭, 장애 예외/유형 관리, 통계/보고서 등 아직 일부 기존 웹 데이터 테이블을 사용합니다. **이 객체를 삭제하면 기능이 깨집니다.** 현재 변경은 대시보드·장비목록·실시간장애·성능 주요 화면에 집중했습니다.
- `web_com_cd_*`의 기존 참조가 남아있는 Mapper가 있을 수 있으므로 당장 삭제하지 마세요. 전체 참조 제거 및 회귀 테스트 후 삭제합니다.
- 전송/행선 장비의 `stn_cd`가 `com_stn_info` 코드와 일치해야 정확한 역사 배치가 됩니다. 코드가 `Unknown`이면 역사 미지정으로 남습니다.
- 시스템 상태의 장애등급 우선순위는 현재 1/2→CRITICAL, 3/4/5→CAUTION으로 뷰에 고정했습니다. 웹 UI의 등급별 가변 매핑 정책과 최종 통합이 필요합니다.
- `DASHBOARD_OFFLINE_MIN`은 PING 점검주기에 맞춰 조정해야 합니다. 마지막 수집 일시가 오래됐을 때 '정상'으로 간주하지 않습니다.
- `event_scheduler`가 OFF인 운영 환경에서도 원천 게이트웨이 트리거는 작동할 수 있습니다. 기존 시연용 이벤트를 다시 켜지 마세요.

## 예상 개발 검증 SQL

```sql
-- 신규 뷰 존재 확인
SELECT ems_id, device_id, device_nm, ping_alive, ping_dt, stts_cd,
       cpu_usage, memory_usage, disk_usage, usage_dt
FROM vw_tnms_gateway_device_live
WHERE ems_id IN (1,13)
ORDER BY ems_id, device_id LIMIT 30;

-- 실제 성능 수집 최신값
SELECT ems_id, device_id, reg_dt, cpu_usage, memory_usage, disk_usage
FROM com_device_usage WHERE ems_id IN (1,13)
ORDER BY reg_dt DESC LIMIT 20;

-- 실제 활성 장애 (게이트웨이 트리거 결과)
SELECT event_seq, ems_id, device_id, event_grade, event_yn, event_dt
FROM raw_event_action WHERE ems_id IN (1,13)
ORDER BY event_dt DESC LIMIT 20;
```
