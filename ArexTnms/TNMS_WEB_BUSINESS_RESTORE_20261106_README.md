# TNMS (2026-11-06 17:43 DB / 08:46 source) 기능 복원 및 원천/웹 구분

## 목표
- 장비 기본정보 등록/수정/삭제: `com_device_info`에 `(ems_id,device_id)` 복합키로 직접 CRUD. **기존 com_* / raw_* 구조·트리거 변경 없음.** `ping_alive`, `ping_dt`, 수집 성능값은 수정하지 않음.
- 게이트웨이 장애: `raw_event_action` / `raw_event_log` **SELECT만**, 판단/임시조치/이관/완료·조치 이력은 `web_fault_process_*` 테이블에 저장.
- 웹 예외그룹/일정/요일/시간: `web_dsblty_excp_*` 테이블에 저장. 원본 장애는 유지, 웹 장애 목록·알림·대시보드·보고서에서 조건 충족 시만 제외.
- 웹 임계치: `web_thrshld_info` 저장·수정, `raw_usage_log`의 새 CPU/MEMORY 수집값 연속 N회를 웹 전용 평가 이벤트가 판정. 생성 결과는 `web_perf_thrshld_event`, 평가 상태는 `web_perf_thrshld_eval_state`에만 씀. 웹 실시간 장애·장애이력·알림·보고서 포함.
- 수집주기관리와 `com_ping_info`: **이번 패치에서 변경하지 않음**.

## 적용 순서 (개발/테스트 서버에서 먼저)
1. 현재 소스 및 DB를 재백업. 기존 이전 패치의 `20261106_02_DROP_LEGACY_WEB_MANUAL.sql`은 **실행 금지**.
2. `db/20261106_RESTORE_WEB_BUSINESS_TABLES.sql` 실행: 웹 업무테이블만 생성. 기존 실데이터는 삭제하지 않음.
3. 변경 `src/...` 파일을 **경로 유지**하여 덮어쓴 후 Eclipse Clean 및 Tomcat 재배포.
4. `db/20261106_03_UPDATE_WEB_EXCEPTION_VIEW.sql` 실행: **VIEW만 변경** (원천 테이블/트리거 미변경). 웹 예외·웹 임계치 판정 포함. VIEW가 없는 DB라면 이 스크립트에서 생성.
5. `db/20261106_02_WEB_THRESHOLD_EVALUATOR.sql` 실행: 웹 평가 상태/장애 이력 테이블, 웹 평가 프로시저/이벤트 생성. **기존 게이트웨이 스케줄러/프로시저는 변경하지 않음.** SQL 파일은 DB 생성 스크립트 실행 후 사용.
6. `db/20261106_05_RESTORE_WEB_MENUS.sql` 실행: 두 웹 전용 설정 메뉴 보이게 하기(역할별 권한은 유지).
7. **선택** `db/20261106_04_THRESHOLD_SCREEN_DEFAULTS_OPTIONAL.sql`: 11월 6일 화면에 보이던 네 임계치 설정값을 복원할 때만 실행. 실제 공장검수 설정으로 확정된 값이 아니라면 실행하지 말 것. 같은 지표/시스템에 다중 설정이 있으면 최초 THRSHLD_SN을 평가에 사용.
8. `db/20261106_06_WEB_BUSINESS_RESTORE_CHECK_READ_ONLY.sql` 실행, UI 실조회/CRUD/Excel 및 게이트웨이 수집 검증.

**중요**: MariaDB `event_scheduler`가 `OFF`면 웹 임계치 자동 평가는 실행되지 않음. `SHOW VARIABLES LIKE 'event_scheduler';`로 확인하고 서버 관리자와 활성화 여부를 결정. 데이터 변경·뷰·이벤트/프로시저 실제 실행 테스트는 이 환경에서 수행하지 않음.

## 장비 화면 필드 중 `com_device_info`에 없는 항목
| 화면/기능 | 실제 com_device_info에 없는 정보 | 처리 |
| --- | --- | --- |
| CCTV | MAC 주소, VMS 서버/저장방식, 펌웨어, CCTV 계정, 수요자, 카메라 수량, 층명 등 | 이번 원천 테이블에는 저장 불가. UI 편집폼에는 해당 필드를 제공하지 않음; 상세에서도 값이 없으면 `-` 표시 |
| 교환기 | 구성품, MTBF, 유지보수 담당자 세부정보 | 별도 공급사 DB 스키마 확정 전에는 저장 불가 |
| 행선 | HSE-LSE-표시장치 다대다 연결관계, LSE 수신가능 여부 | `com_device_info`에 관계 컬럼 없음. 임의 연결하지 않음 |
| 장비 상태 | `pingRspnsMs`/실시간 응답속도, 전송 성공률/처리시간 등 | 원천 수집값 없으면 임의 계산하지 않음 |
| 모든 장비 | 이전 웹 `EQPMNT_SN` 및 관계 참조 | 기존 일련번호 이관 없음; `(ems_id,device_id)` 사용 |

## 개발상 검증 결과 및 남은 검증
- 수정 Java 핵심 서비스·Mapper·VO **Java 8 소스/타깃으로 컴파일** (기존 target 클래스+필요 최소 스텁 사용). 전체 Maven WAR 빌드 및 실제 Tomcat 부팅은 수행하지 않음.
- MyBatis XML 파싱, 변경 JavaScript Node.js 문법 검사, 압축 무결성 검사.
- 실제 MariaDB `CREATE`/`ALTER VIEW`/`CREATE EVENT` 실행, 실수신 스케줄러 평가, UI CRUD E2E 검증은 사용 환경에서 수행 필요.
- 웹 예외그룹 및 임계치의 **기존 삭제 데이터는 백업에만 있음**. 새 웹 업무테이블은 빈 상태로 생성; 이전 더미 장비번호를 그대로 복원하지 않음.
- 웹 임계치 evaluator: 수집 간격 및 중단 상황을 고려해 `raw_usage_log` 최근 10분 신규값만 순서대로 판정. 구형 성능 생성 프로시저를 다시 활성화하지 않음.
