# VO · Mapper · DB 연계 점검표

## 사용자

| DB 컬럼 / 화면값 | MyBatis property | Java 선언 위치 |
|---|---|---|
| USER_SN | userSn | UserVO |
| USER_ID | userId | UserVO |
| USER_NM | userNm | UserVO |
| USER_ENPSWD | userEnpswd | UserVO |
| OGDP_BZENTY_NM | ogdpBzentyNm | UserVO |
| DEPT_NM | deptNm | UserVO |
| TELNO | telno | UserVO |
| EML_ADDR | emlAddr | UserVO |
| USER_STTS_NM | userSttsNm | UserVO |
| PSWD_EXPRY_YMD | pswdExpryYmd | UserVO |
| LAST_LGN_DT | lastLgnDt | UserVO |
| LGN_FAIL_NOCS | lgnFailNocs | UserVO |
| AUTHRT_SN | authrtSn | UserVO |
| AUTHRT_NM | authrtNm | UserVO |
| USE_YN | useYn | BaseVO 상속 |
| REG_DT | regDt | BaseVO 상속 |
| RGTR_SN | rgtrSn | BaseVO 상속 |
| MDFCN_DT | mdfcnDt | BaseVO 상속 |
| MDFR_SN | mdfrSn | BaseVO 상속 |
| 조회어 | searchKeyword | BaseVO 상속 |
| 입력 비밀번호 | password | UserVO (DB 직접 매핑 안 함) |
| 비밀번호 확인 | passwordConfirm | UserVO (DB 직접 매핑 안 함) |
| 로그인 IP | loginIp | UserVO (cntn_log 저장용) |
| 브라우저 | browserNm | UserVO (cntn_log 저장용) |
| 로그인 성공 여부 | loginSuccessYn | UserVO (cntn_log 저장용) |
| 실패 사유 | failRsn | UserVO (cntn_log 저장용) |

## 권한 및 메뉴 권한

| DB 컬럼 | MyBatis property | Java 선언 위치 |
|---|---|---|
| AUTHRT_SN | authrtSn | AuthVO / MenuAuthVO |
| AUTHRT_NM | authrtNm | AuthVO |
| AUTHRT_EXPLN | authrtExpln | AuthVO |
| AUTHRT_STTS_NM | authrtSttsNm | AuthVO |
| USER_NOCS 집계값 | userNocs | AuthVO |
| MENU_SN | menuSn | MenuAuthVO |
| UP_MENU_SN | upMenuSn | MenuAuthVO |
| MENU_NM | menuNm | MenuAuthVO |
| MENU_URL_ADDR | menuUrlAddr | MenuAuthVO |
| MENU_SEQ | menuSeq | MenuAuthVO |
| URL에서 계산 | screenKey | MenuAuthVO |
| LIST_AUTHRT_YN | listAuthrtYn | MenuAuthVO |
| DTL_AUTHRT_YN | dtlAuthrtYn | MenuAuthVO |
| REG_AUTHRT_YN | regAuthrtYn | MenuAuthVO |
| MDFCN_AUTHRT_YN | mdfcnAuthrtYn | MenuAuthVO |
| DEL_AUTHRT_YN | delAuthrtYn | MenuAuthVO |
| CTRL_AUTHRT_YN | ctrlAuthrtYn | MenuAuthVO |

## 대조 결과

- `userMapper.xml`: statement 15개, UserMapper 메소드 15개, 누락 0개
- `authMapper.xml`: statement 10개, AuthMapper 메소드 10개, 누락 0개
- `auditMapper.xml`: statement 1개, AuditMapper 메소드 1개, 누락 0개
- 모든 `resultMap property`, `#{parameter}`, 동적 SQL `test` 속성은 해당 VO 또는 BaseVO getter/setter와 일치
- Mapper가 참조하는 `user_info`, `user_authrt_rel`, `authrt_info`, `menu_info`, `authrt_menu_rel`, `cntn_log`, `job_log`은 제공 DDL에 존재
