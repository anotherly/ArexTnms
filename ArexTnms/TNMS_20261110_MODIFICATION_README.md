# TNMS Gateway–WEB 공통코드 연동 / 조회 분리 / 성능 대량조회 수정
기준: `ArexTnms(6).zip` + `arex_tnms_backup_20261109_195434.sql` (2026-11-10 작업)

## 적용 순서 (납품 서버)
1. **기존 DB 전체 백업 및 기존 WAR 별도 보관.** `mariadb-dump --single-transaction --routines --events --triggers --databases arex_tnms` 사용.
2. 납품 MariaDB에서 `db/20261110_01_WEB_SYSTEM_MAP_AND_SPLIT_VIEWS.sql` 실행. 신규 테이블 생성/데이터 삭제 없음. `web_link_sys_info.DEVICE_COM_CD` 1컬럼 추가, 5개 레코드 연결, 조회 VIEW 5개 생성 및 종전 VIEW 호환 재정의. 실행 도중 5개 매핑이 나오지 않으면 WEB 배포 중단.
3. `db/20261110_02_WEB_SPLIT_VERIFY_READ_ONLY.sql` 실행. 매핑 5/중복 0, 장비 수 5종 일치 확인. 실제 조회 속도는 EXPLAIN 및 서버에서 확인.
4. ZIP 내부의 `src/` 변경 파일을 프로젝트 루트에 경로 그대로 덮어쓰기 → 기존 프로젝트에서 Maven WAR 빌드 → Tomcat 배포 후 화면 기능 확인.
5. 브라우저 강력 새로고침으로 캐시된 JS 반영 확인.

**로컬 PC 개발 DB `tnms`에는** `..._LOCAL.sql`을 대신 실행해야 합니다. 납품 서버 스크립트를 로컬 DB에서 실행하지 마세요.

## 설계 결정
- Gateway의 `raw_*`, `com_*` 테이블 **컬럼·데이터·트리거를 수정하지 않음**.
- `com_cd_info`의 `CD_DVIC.GW_CD` = Gateway `ems_id`를 단일 원천으로 사용. `web_link_sys_info.DEVICE_COM_CD`는 WEB의 기존 `LINK_SYS_CD`를 해당 공통코드에 연결하는 **관계키**. 시드 UPDATE의 다섯 값은 일회성 마이그레이션 데이터이며, 실행 소스에서 EMS 번호 CASE를 제거함.
- 기존 `LINK_SYS_CD` 문자열(`EMS_PIDS`, `SCADA_SEC` 등)은 권한/메뉴/화면의 기존 식별 계약이므로 보존. 이것을 DB 이관 없이 `CD_DVIC_002`로 치환하면 권한·FK·URL이 깨짐.
- `vw_tnms_system_map`: 공통코드-기존 LINK_SYS 매핑.
- `vw_tnms_device_base`: 장비/현재 PING 원천(이력 로그 미조회).
- `vw_tnms_device_performance`: 최신 장비 성능/5분 이내 여부, **활성 장애 조회 없음**.
- `vw_tnms_active_fault_summary`: 활성 장애+예외 일정 집계 (장애 미수집 상태도 정상적으로 0건 가능).
- `vw_tnms_device_status`: 장비/현재 PING+활성 장애 → 메인/역사 상태 전용, **성능 JOIN 없음**.
- `vw_tnms_gateway_device_live`: 기존 26컬럼 이름을 유지하는 호환 VIEW(장비 상세·장비별 KPI 등 실제 복합 정보가 필요한 곳만 사용).

## WEB 변경
- EMS ID ↔ LINK_SYS_CD 변환: Java 여러 상수 배열/스위치 및 Mapper CASE → `vw_tnms_system_map` 기준 DB 조회. 요청 단위 캐시 적용. 권한 허용 시스템 목록도 DB 매핑에서 읽음.
- 메인/역사 상태 SQL은 `vw_tnms_device_status`; 성능 목록/TOP5/수집 상태는 `vw_tnms_device_performance`.
- 성능현황 `LIMIT 500`을 폐기하고 DB 서버 페이지네이션 (`LIMIT ? OFFSET ?`, 페이지당 기본 10건, 최대 100건). 페이지 이동은 TOP5/성능추이 재호출 없이 목록과 전체 건수만 조회. **Excel은 전체 결과 다운로드**, 상세는 장비 ID 필터.
- `performance.js`, `facility.js` 10초 폴링 → 60초. 중복 요청 방지.
- 수집현황의 마지막 PING 시각은 `com_device_info.ping_dt`, 최신 성능 시각은 `com_device_usage.reg_dt`. 최근 5분 횟수는 `raw_*`를 5분 범위로 제한 (전체 이력 GROUP BY 제거).

## 규모와 남은 제약
- 1500대/30초=432만 PING 로그/일. 메인 조회는 `com_device_info`의 현재값(약 1500행) 위주이며, 원천 `raw_ping_log` 432만건을 매번 읽지 않음.
- **시설관리 화면은** 복합 KPI/장비별 시각화에 전체 장비 데이터를 사용하므로 클라이언트 페이지네이션을 유지. 성능목록만 서버 페이지네이션으로 변경. 시설관리 1500대 전체 응답은 실서버 부하 측정 후 분리하는 후속 과제.
- `raw_ping_log`/`raw_usage_log` 시간 범위 조회를 위한 인덱스는 수집 쓰기 성능에 영향이 있으므로 기본 적용에서 **제외**. `20261110_03_RAW_INDEX_OPTIONAL_GATEWAY_AGREEMENT.sql`의 주석 옵션을 Gateway 개발자 협의 후에만 적용.
- VIEW 내부 장애예외 반복 요일/자정 넘김 조건은 기존과 같은 판정 유지(별도 로직 수정 없음).
- MariaDB에 원격 접속하여 DDL과 모든 SELECT를 실행한 것은 아님. **실 DB 실행계획·브라우저 기능·응답시간은 미검증**.

## 이 환경에서 수행한 점검
- WAR에 포함된 97개 라이브러리로 수정 Java 75개 파일 `javac --release 8` 컴파일 통과.
- 수정 MyBatis 14개 XML 로딩 및 260개 SQL 바인딩 검사 오류 0건. (DB 실제 실행은 아님.)
- 변경 JS `node --check` 문법 검사 통과.

## 되돌리기
1. 기존 WAR/소스 복구.
2. `db/20261110_04_WEB_SPLIT_ROLLBACK.sql` 실행해 구 VIEW를 복원한 후 신규 분리 VIEW 제거. WEB 소유 `DEVICE_COM_CD` 컬럼은 원본 데이터를 보존하기 위해 남김.
3. 문제가 계속되면 백업한 전체 DB 덤프 기준으로 별도 복원 검토.

**테스트 관점:** EMS 1/13에서 장비현황, PING 상태, 성능 TOP5/성능목록 1/2페이지, 상세 모달, 권한별 시스템 조회, Excel, 수집현황 및 장애 예외를 순서대로 확인.
