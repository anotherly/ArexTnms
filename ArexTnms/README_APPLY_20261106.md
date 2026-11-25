# TNMS 수집주기 관리 — 원래 화면 복구 + com_ping_info CRUD + 누락 컬럼 추가

## 실제 수정 범위
- 사용자가 제공한 11/05 소스의 수집주기관리 화면 레이아웃 유지 (관리 목록 9개 열 / 수집 실행 현황)
- 11/06 사용자가 적용한 구형 수신현황 화면을 `cycle.jsp`/`cycle.js`로 덮어씀.
- 관리 목록 + 등록 버튼, 행별 수정/삭제, 등록/수정 모달.
- DB는 `com_ping_info`만 CRUD, `com_device_info` 등 원천 테이블 및 트리거 미수정.
- 기존 `com_ping_info`에는 누락된 `USE_YN`, `EXCN_TM`, `CYCLE_CRTR_CN`을 추가하며 기존 설정값 유지.
- 이미 설정된 값의 실행시각/설정근거는 임의 채우지 않음.
- 수집 실행 현황은 `raw_ping_log`와 `raw_usage_log`의 실제 수신 유무이며, 게이트웨이의 작업 성공/실패 여부와 같지 않음.

## 정확한 적용 순서
1. 현 적용 소스 및 DB 백업.
2. `com_ping_info`가 이미 존재하면 `db/20261106_02_ALTER_COM_PING_INFO_EXISTING.sql` 실행.
   없다면 `db/20261106_01_CREATE_COM_PING_INFO_CORRECTED.sql` 실행 (02는 선택적 확인용).
3. `db/20261106_03_ENABLE_SYS_ADMIN_CYCLE_CRUD.sql` 실행 (SYS_ADMIN 등록/수정/삭제 권한).
4. 기존 웹 화면의 수집주기 설정 10건을 복사하고 싶을 때만 `db/20261106_05_COPY_LEGACY_CYCLE_SETTINGS_OPTIONAL.sql` 실행 (기존 설정은 덮어쓰지 않음).
5. `src/` 전체 상대 경로를 Eclipse 프로젝트 루트에 덮어쓰기. `target/` 파일은 포함하지 않음.
6. Project > Clean, Tomcat Clean / Publish 및 재시작. Ctrl+F5.
7. 페이지에서 브라우저 F12 Console에 `[TNMS CYCLE] com_ping_info CRUD r2 loaded` 출력 확인.
8. 기존의 `관리 목록` 9개 열 유지 및 `+ 등록`, `수정`, `삭제` 노출 확인.
9. `db/20261106_04_VERIFY_COM_PING_READ_ONLY.sql` 실행, 설정 INSERT/UPDATE/DELETE 반영 확인.

## DB 설계 변경 근거
- (EMS_ID, DATA_SE_CD) 조합을 PK로 사용, 별도 시퀀스 생성 없음.
- `USE_YN`: 기존 웹 수집주기 테이블에서 따로 사용하던 설정 활성 상태. PERF/PING 토글과 독립적.
- `EXCN_TM`: 구성(C) 데이터 하루 1회 수집의 04:00 실행시각 같은 값.
- `CYCLE_CRTR_CN`: 설정 근거 및 비고(구형 수집주기 테이블의 주기근거내용).
- `LAST_EXCN_DT`/`NEXT_EXCN_DT`: 설정값이 아니라 수행 결과이므로 DB에 중복 저장하지 않음. 현재 목록의 '최근 수집'은 raw_usage_log 기반이고 '다음 수집'은 확정 데이터 없어 '-'로 표시.
- 기존 10개 웹 설정을 자동 복사하지 않음. com_ping_info가 비어 있으면 관리자 화면에서 등록해야 함.

## 주의
- 게이트웨이 개발자와 `com_ping_info` 공용 사용 방향은 협의되었음.
- 실제 SQL 적용 및 WAR 전체 구동은 서버에서 확인해야 함. 소스 문법만 정적 검증.
- `COM` 장비 원천 테이블, `RAW` 로그 및 게이트웨이 트리거와 기존 DB 객체 삭제는 실행하지 않음.
