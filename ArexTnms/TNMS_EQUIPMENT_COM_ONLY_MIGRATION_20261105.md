# TNMS WEB 장비기본정보 제거 / COM 장비기준 전환

**검토 기준:** `ArexTnms(20261105-032652).zip`, `arex_tnms_backup_20261105_113259.sql`

## 적용 범위 및 승인 전제

- 전송(EMS 1), CCTV(EMS 4), 교환(EMS 11), 행선(EMS 13), SCADA(EMS 16)의 **장비 기본정보는 `com_device_info`만 신뢰**합니다.
- 현장/검수 테스트 장비 `test_yn=Y`도 게이트웨이 유효 장비로 인정합니다.
- 이전 `web_eqpmnt_info` 2,533건과 해당 장비를 참조하는 웹 전용 장비정보 및 시연성 이력은 복원 가능한 백업에 남기고 신규 DB에는 이관하지 않습니다.
- `raw_*`, `com_*`, 게이트웨이 트리거의 **DDL/DML은 0개**입니다. 웹은 SELECT만 사용합니다.
- 게이트웨이 신규 장비가 추가돼도 설비 목록/상세는 기존의 COM 직접 조회를 유지합니다.
- 다만 예외설정처럼 과거 숫자 장비일련번호에 의존하는 웹 기능은 `web_gateway_device_ref`라는 **웹 전용 (ems_id, device_id) 연결표**를 사용합니다.

## 확인 결과

- `web_eqpmnt_info`: 2,533건 / `com_device_info`: 373건.
- 기존 웹의 `EMS_ID`, `SOU_EQPMNT_ID`와 게이트웨이 `(ems_id,device_id)`를 직접 대조하면 동일 키 0건.
- `web_eqpmnt_info`에 대한 참조 외래키 18개(하위 테이블 16개).
- `web_dsblty_excp_group_eqpmnt_rel`의 기존 멤버 7건 및 멤버별 지표 설정은 **폐기**합니다. 그룹과 예외일정 정의 자체는 유지합니다. 새로운 COM 장비를 예외그룹에 다시 선택하면 됩니다.

## 파일 및 실행 순서 (개발·검수 환경에서)

1. 모든 DB를 최신 백업합니다. `db/20261105_EQUIPMENT_MIGRATION_PRECHECK_READ_ONLY.sql` 실행 후 FK와 건수를 확인합니다.
2. `db/20261105_STEP1_CREATE_GATEWAY_DEVICE_REF.sql` 실행. 새로운 WEB 참조 테이블과 COM 장비의 매핑만 생성합니다(파괴적 작업 없음).
3. ZIP 안의 `src/main` 변경 파일을 동일 상대경로에 반영하고 Eclipse에서 전체 빌드 및 Tomcat 재배포합니다. 기본 화면, 전송·행선 목록/상세, 현재 장애/성능 화면을 확인합니다.
4. 백업과 화면 확인 후 `db/20261105_STEP2_DROP_LEGACY_EQUIPMENT_MANUAL.sql` **수동 실행**. 기존 웹 장비 FK 18개 해제(예외그룹 FK는 새 WEB ref에 재지정), 옛 WEB 장비 및 시연성 객체 정리합니다.
5. `db/20261105_EQUIPMENT_MIGRATION_POSTCHECK_READ_ONLY.sql`로 장비 수, 웹 ref, VIEW, 잔존 FK를 확인합니다. 이후 예외설정에 실제 게이트웨이 장비를 새로 선택합니다.

**주의:** STEP2는 `DROP TABLE`, `ALTER TABLE`, `DROP PROCEDURE`가 포함된 **되돌리기 어려운 DDL**입니다. 백업만으로는 안전성이 검증된 게 아니며, 복원은 독립 인스턴스에서만 시험해야 합니다. MariaDB DDL은 일반 트랜잭션으로 롤백되지 않습니다.

**주의:** STEP2를 실행했다면 구버전 `20261104_DEMO_OBJECTS_CLEANUP_APPLY_MANUAL.sql` / `20261105_DROP_REPLACED_WEB_OBJECTS_MANUAL.sql`을 다시 실행하지 마세요. 제거 대상이 중복됩니다.

## 소스 변경

- `MonitoringMapper`의 기본장비 조회/등록/수정/삭제를 COM 장비 조회와 WEB 장비 참조 동기화로 교체.
- `MonitoringServiceImpl`의 장비 등록/수정/삭제를 **명시적 거부**로 전환. 게이트웨이 데이터 무단 수정 방지.
- `FaultMapper`의 예외그룹 장비 조회/검색을 `web_gateway_device_ref + com_device_info`로 변경.
- `FaultServiceImpl`은 예외그룹 조회/검색/저장 전에 WEB 참조키를 `INSERT IGNORE ... SELECT`로 동기화(게이트웨이 테이블에는 쓰지 않음).
- `SystemScopeSqlInterceptor`의 장비별 권한 필터가 기존 웹 마스터를 조회하지 않도록 수정.
- `facility.js`의 게이트웨이 장비 상세 버튼에 문자열 장비 ID를 올바르게 넘기도록 수정. 기존 웹 장비 편집 UI 비활성화.

## 의도적으로 보존한 객체 및 기능 제한

- `web_dsblty_info`, `web_dsblty_actn_hstry`, 장애 예외그룹/일정/코드·권한·색상 설정 등은 보존합니다. 과거 웹 장애데이터는 현재 주요 실시간 조회와 보고서에 사용되지 않습니다.
- 옛 `web_dsblty_info.EQPMNT_SN`은 더 이상 정상 COM 장비번호가 아니므로 신규 처리 기능의 ID로 사용하지 않아야 합니다.
- 웹 기존 성능 임계치 자동 장애 생성 이벤트/프로시저는 옛 `web_eqpmnt_perf_stts`에 의존하여 STEP2에서 **제거**합니다. 게이트웨이 장애 `raw_event_action`의 실시간 표출은 별개지만, *WEB 자체 성능 임계치 자동 판정은 이번 패치에서 재구현하지 않았습니다*. 공장검수에서 이를 시연해야 한다면 별도 COM 기반 판정 구현이 필요합니다.
- 실제 장비/선로 연결관계는 아직 COM/RAW 데이터로 확정되지 않았으므로 임의 구성도를 생성하지 않습니다.
- 교환/CCTV/SCADA의 현재 COM 미등록 장비는 화면에 나타나지 않으며 이후 게이트웨이 등록 시 조회됩니다.

## 정적 검사 범위

- MyBatis Mapper XML 구조 파싱 성공.
- `facility.js` JavaScript 문법 검사 성공.
- 변경 소스의 `web_eqpmnt_info` 직접 참조 제거 확인.
- DB 덤프의 FK 18개와 SQL 해제 목록 대조.
- **실제 MariaDB DDL 실행, Maven WAR 전체 빌드, Eclipse/Tomcat 연동 시험은 수행하지 못함.** 먼저 개발·검수 서버에서 실제 동작을 확인하세요.
