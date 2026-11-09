# TNMS 원천데이터 단일화 (2026-11-06)

## 기준
- 소스 기준: `ArexTnms(20261105-032652).zip` → `ArexTnms_WEB_TO_GATEWAY_CHANGED_ONLY_20261105.zip` → `TNMS_equipment_migration_20261106.zip` 순서로 덮어쓴 후 **web_gateway_device_ref 구현을 폐기**한 최종본.
- DB: `arex_tnms_backup_20261105_113259.sql` (실행 전 백업 버전 재확인 필요).
- `com_*`, `raw_*` 테이블/데이터/트리거: 변경 없음. 기존 `vw_tnms_gateway_device_live` 유지.
- 새로운 장비 참조 테이블을 만들지 않음. 장비 식별은 `(ems_id,device_id)`.

## 중요: 삭제할 웹 기능 (의도된 기능 축소)
- 장비 자체 등록/수정/삭제: 불가. 게이트웨이 수신 장비만 조회.
- 장애 자체 판단/조치/이관/완료: 불가. `raw_event_action`·`raw_event_log` 조회만 제공.
- 장애 예외 그룹/스케줄: 기존 테이블 삭제. 예외설정 화면은 비활성 안내만 표시.
- 성능 임계치 관리 및 `sp_tnms_eval_performance_threshold`: 삭제. 자동 임계치 장애 생성 **중단**; 게이트웨이 자체 장애 수신은 계속 조회.
- 임계치와 예외설정의 메뉴는 DB 적용 시 사용 안 함으로 설정; 개별 URL 직접 호출 시 수정 API는 거부.
- 보고서: `raw_event_log`, 성능현황: `raw_usage_log`/`com_device_usage`, PING: `raw_ping_log`/`com_device_info`.
- 웹 `web_link_sys_info`, `web_menu_info`, `web_authrt_*`, `web_ui_stng_info`는 권한·메뉴·UI 관리 메타데이터이므로 유지.

## 적용 순서 (반드시 준수)
1. 운영과 같은 환경의 MariaDB/프로젝트 **새 전체 백업**을 준비하고 복원 테스트.
2. `db/20261106_01_PRECHECK_READ_ONLY.sql` 실행: 남아 있는 FK/뷰/프로시저/이벤트·트리거/장비 건수 확인.
3. 이 ZIP의 `src/`만 소스에 경로 유지 덮어쓴 후 빌드(실제 Maven 빌드는 여기서는 미실행) 및 Tomcat 재배포.
4. DB 삭제 시점을 정하고, 같은 DB 스키마에서 `db/20261106_02_DROP_LEGACY_WEB_MANUAL.sql` 을 **수동 실행**. MySQL/MariaDB DDL은 통상 롤백되지 않음.
5. `db/20261106_03_POSTCHECK_READ_ONLY.sql` 실행. 웹 로그인/대시보드/설비(5개)/성능/RAW/실시간 장애/장애이력/보고서/알림/코드 설정 검사.
6. `db/`의 **옛 설치·시연·데모 SQL은 다시 실행하지 말 것** (`CREATE TABLE web_*`를 되살릴 수 있음).

## 주의
- SQL은 최신 11/05 백업을 근거로 생성되었으나, 실제 연결된 서버에서 실행하거나 복원 테스트하지 않음.
- `raw_*` 장애 데이터와 `com_device_info`의 식별키 불일치는 웹에서 임의 보정하지 않음. 매핑되지 않은 정보는 원문만 표시.
- gateway trigger 4개(`trg_raw_*`)는 삭제·수정 대상에서 제외.
- 파일 압축 내 SQL은 실제 DB를 수정한 것이 아니며 수동 실행 후 확인 필요.
