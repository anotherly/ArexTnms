# TNMS 2026-11-06 삭제/대체 목록

원천 `com_*`/`raw_*`는 구조·내용·트리거를 수정하지 않음. `web_*`는 웹 권한/메뉴/설정 메타데이터만 보존.

| 삭제 대상 WEB 테이블 | 대체 조회 / 종료 기능 |
|---|---|
| `web_cctv_info` | `com_device_info` |
| `web_cctv_info_bak_260923` | **기능 종료** (웹 더미/설정) |
| `web_clct_cycle_info` | 수신 원천 `raw_ping_log`, `raw_usage_log`, `raw_receive_log` |
| `web_clct_excn_hstry` | 수신 원천 `raw_ping_log`, `raw_usage_log`, `raw_receive_log` |
| `web_dsblty_actn_hstry` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_dsblty_excp_group_eqpmnt_idct_rel` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_dsblty_excp_group_eqpmnt_rel` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_dsblty_excp_group_info` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_dsblty_excp_schdl_grd_rel` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_dsblty_excp_schdl_info` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_dsblty_exprs_info` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_dsblty_info` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_dsblty_type_info` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_ems_info` | **기능 종료** (웹 더미/설정) |
| `web_enex_evnt_hstry` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_eqpmnt_clsf_info` | **기능 종료** (웹 더미/설정) |
| `web_eqpmnt_cntn_acnt_info` | **기능 종료** (웹 더미/설정) |
| `web_eqpmnt_info` | `com_device_info` |
| `web_eqpmnt_lnk_rel` | **기능 종료** (웹 더미/설정) |
| `web_eqpmnt_mtbf_info` | **기능 종료** (웹 더미/설정) |
| `web_eqpmnt_perf_stts` | `vw_tnms_gateway_device_live`, `com_device_info` |
| `web_eqpmnt_qty_stts` | `vw_tnms_gateway_device_live`, `com_device_info` |
| `web_eqpmnt_stng_hstry` | **기능 종료** (웹 더미/설정) |
| `web_eqpmnt_stts` | `vw_tnms_gateway_device_live`, `com_device_info` |
| `web_eqpmnt_sync_hstry` | **기능 종료** (웹 더미/설정) |
| `web_link_raw_data` | 수신 원천 `raw_ping_log`, `raw_usage_log`, `raw_receive_log` |
| `web_pbx_info` | `com_device_info` |
| `web_perf_day_stats` | 성능 원천 `com_device_usage`, `raw_usage_log`; 임계치 쓰기 기능 종료 |
| `web_perf_hr_stats` | 성능 원천 `com_device_usage`, `raw_usage_log`; 임계치 쓰기 기능 종료 |
| `web_perf_idct_info` | 성능 원천 `com_device_usage`, `raw_usage_log`; 임계치 쓰기 기능 종료 |
| `web_perf_raw_data` | 성능 원천 `com_device_usage`, `raw_usage_log`; 임계치 쓰기 기능 종료 |
| `web_perf_thrshld_eval_stts` | `vw_tnms_gateway_device_live`, `com_device_info` |
| `web_pids_eqpmnt_lse_rel` | **기능 종료** (웹 더미/설정) |
| `web_sms_trsm_hstry` | 장애 원천 `raw_event_log`, `raw_event_action`; 조치·예외 쓰기 기능 종료 |
| `web_srvr_log_link_info` | **기능 종료** (웹 더미/설정) |
| `web_sys_health_stts` | `vw_tnms_gateway_device_live`, `com_device_info` |
| `web_thrshld_info` | 성능 원천 `com_device_usage`, `raw_usage_log`; 임계치 쓰기 기능 종료 |
| `web_tnms_demo_device` | **기능 종료** (웹 더미/설정) |
| `web_tnms_demo_excn_ids` | **기능 종료** (웹 더미/설정) |
| `web_tnms_demo_run_config` | **기능 종료** (웹 더미/설정) |

총 **40개** 테이블. `web_gateway_device_ref`는 덤프에는 없지만 혹시 생성된 경우 DROP 포함.

## DROP 전 원천 데이터 확인

- 대상의 외부 참조 FK 수: 0건 (11/05 백업 기준)
- 원천 4개 트리거 (`trg_raw_action_log_after_insert`, `trg_raw_event_log_after_insert`, `trg_raw_ping_log_after_insert`, `trg_raw_usage_log_after_insert`) 유지
- `web_link_sys_info`는 연계시스템 구분/권한 화면 메타데이터로 유지 (장비 원천 데이터 아님)
- 레거시 VIEW 5개 삭제, 게이트웨이 VIEW는 유지
- 이벤트 3개, 웹 관련 프로시저 8개, 함수 2개 삭제
- 편집 불가능한 임계치/장애 예외 메뉴만 미사용 처리

## 주의

본 목록은 기존 DB의 장비/성능/장애 관련 `web_*` 데이터가 모두 폐기 가능하다는 사용자 결정에 따른 것임. 기존 장애 조치 기록, 예외 설정, CCTV/PBX 부가정보는 복원 가능한 백업에만 남고 운영 DB에서 삭제됨.
