let FAULT_DATA = {};
let FAULT_EQUIPMENT_EDIT = null;

function faultGradeOptions(rows, selected) {
  return '<option value="">전체 등급</option>' + mgmtOptions(rows, 'code', 'name', selected);
}

function faultProcessOptions(rows, selected) {
  return '<option value="">전체 조치</option>' + mgmtOptions(rows, 'code', 'name', selected);
}

function faultJudgmentName(code) {
  return ({SERVICE: '서비스장애', STATUS: '상태장애', INFO: '정보'}[code] || '미판단');
}

function faultRecoveryName(row) {
  if (row && (row.ocrnRcvrSeCd === '0' || row.dsbltyEndDt)) return '복구';
  return '발생 중';
}

function faultTempAction(actions) {
  const list = (actions || []).filter(function (x) { return x.actnSeCd === 'TEMP'; });
  return list.length ? list[list.length - 1] : null;
}

function realtimeCanModify() {
  return hasPermission('faults', 'mdfcnAuthrtYn') || (CURRENT_USER && CURRENT_USER.authrtCd === 'SYS_ADMIN');
}

function realtimeCanControl() {
  return hasPermission('faults', 'ctrlAuthrtYn') || realtimeCanModify() || (CURRENT_USER && CURRENT_USER.authrtCd === 'SYS_ADMIN');
}

function selectedFaultRows() {
  const set = {};
  checkedFaults().forEach(function (no) { set[no] = true; });
  return (FAULT_DATA.faults || []).filter(function (r) { return set[String(r.dsbltyNo)]; });
}

function selectionRowsHtml(rows) {
  if (!rows.length) return '<div class="mgmt-empty">선택된 장애가 없습니다.</div>';
  return '<div class="fault-selected-list">' + rows.map(function (r) {
    return '<div class="fault-selected-row">' +
      '<span class="fault-selected-dot ' + mgmtGradeClass(r.dsbltyGrdCd) + '"></span>' +
      '<b>' + mgmtE(mgmtGradeName(r.dsbltyGrdCd, r.dsbltyGrdNm)) + ' · ' + mgmtE(r.linkSysNm || '-') + ' · ' + mgmtE(r.stnNm || '-') + '</b>' +
      '<span>' + mgmtE(r.dsbltyOcrnCn || '-') + '</span>' +
      '</div>';
  }).join('') + '</div>';
}

function realtimeScreen() {
  const d = FAULT_DATA;
  const s = d.summary || {};
  const canModify = realtimeCanModify();
  const canControl = realtimeCanControl();
  const faults = d.faults || [];

  const rows = faults.length ? faults.map(function (r, idx) {
    const no = faults.length - idx;
    const equipmentType = r.eqpmntClsfNm || r.eqpmntSeCd || '-';
    const judgment = faultJudgmentName(r.dsbltyJgmtCd);
    const temp = r.tempActionYn === 'Y' ? '입력완료' : '미입력';
    const manage = '<div class="fault-row-actions">' +
      '<button class="btn sm" onclick="openEquipmentDetail(\'' + mgmtE(r.dsbltyNo) + '\')">장비</button>' +
      (canModify ? '<button class="btn sm" onclick="openFaultEdit(\'' + mgmtE(r.dsbltyNo) + '\')">수정</button>' : '') +
      '<button class="btn sm" onclick="openFaultDetail(\'' + mgmtE(r.dsbltyNo) + '\')">상세</button>' +
      '</div>';

    return '<tr>' +
      '<td class="center"><input class="mgmt-checkbox faultCheck" type="checkbox" value="' + mgmtE(r.dsbltyNo) + '" onchange="updateRealtimeSelectionState()"></td>' +
      '<td>' + no + '</td>' +
      '<td>' + mgmtBadge(mgmtGradeName(r.dsbltyGrdCd, r.dsbltyGrdNm), mgmtGradeClass(r.dsbltyGrdCd)) + '</td>' +
      '<td><b>' + mgmtE(r.linkSysNm || '-') + '</b></td>' +
      '<td>' + mgmtE(r.stnNm || '-') + '</td>' +
      '<td class="left"><b>' + mgmtE(r.eqpmntNm || r.souEqpmntId || '-') + '</b></td>' +
      '<td>' + mgmtE(r.ipAddr || '-') + '</td>' +
      '<td>' + mgmtE(equipmentType) + '</td>' +
      '<td>' + mgmtE(r.dsbltyOcrnPlcNm || r.instlPlcNm || '-') + '</td>' +
      '<td>' + mgmtE(r.dsbltyTypeNm || '-') + '</td>' +
      '<td class="left fault-content-cell">' + mgmtE(r.dsbltyOcrnCn || '-') + '</td>' +
      '<td>' + mgmtDt(r.dsbltyOcrnDt) + '</td>' +
      '<td><button class="mgmt-link" onclick="openJudgmentModalForOne(\'' + mgmtE(r.dsbltyNo) + '\')">' + mgmtE(judgment) + '</button></td>' +
      '<td>' + mgmtE(temp) + '</td>' +
      '<td>' + manage + '</td>' +
      '</tr>';
  }).join('') : '<tr><td colspan="15" class="center">현재 발생 중인 장애가 없습니다.</td></tr>';

  return '<div class="mgmt-page fault-realtime-page">' +
    '<div class="mgmt-summary six">' +
      '<div class="mgmt-stat"><div class="label">전체</div><strong>' + mgmtNum(s.totalCount) + '</strong><small>현재 발생 중</small></div>' +
      '<div class="mgmt-stat bad"><div class="label">긴급 · 등급 1</div><strong>' + mgmtNum(s.emergencyCount) + '</strong><small>최우선 조치</small></div>' +
      '<div class="mgmt-stat high"><div class="label">높음 · 등급 2</div><strong>' + mgmtNum(s.highCount) + '</strong><small>우선 조치</small></div>' +
      '<div class="mgmt-stat warn"><div class="label">낮음 · 등급 3</div><strong>' + mgmtNum(s.lowCount) + '</strong><small>상태 확인</small></div>' +
      '<div class="mgmt-stat warn"><div class="label">경고 · 등급 4</div><strong>' + mgmtNum(s.warningCount) + '</strong><small>관찰 필요</small></div>' +
      '<div class="mgmt-stat"><div class="label">정보 · 등급 5</div><strong>' + mgmtNum(s.infoCount) + '</strong><small>정보 이벤트</small></div>' +
    '</div>' +
    '<section class="mgmt-card">' +
      '<div class="mgmt-card-head fault-list-head"><div><h3>실시간 장애 목록</h3><small>총 ' + faults.length.toLocaleString() + '건</small></div><div class="fault-list-actions"><button class="btn" onclick="downloadRealtimeExcel()">Excel</button></div></div>' +
      '<div class="mgmt-filter">' +
        '<select id="faultGrade" class="input">' + faultGradeOptions(d.gradeCodes) + '</select>' +
        '<select id="faultSystem" class="input"><option value="">전체 설비</option>' + mgmtOptions(d.systems, 'linkSysCd', 'linkSysNm') + '</select>' +
        '<select id="faultStation" class="input"><option value="">전체 역사</option>' + mgmtOptions(d.stations, 'stnCd', 'stnNm') + '</select>' +
        '<select id="faultStatus" class="input">' + faultProcessOptions(d.processCodes) + '</select>' +
        '<input id="faultKeyword" class="input wide" placeholder="검색어를 입력해 주세요" onkeydown="if(event.key===\'Enter\')loadRealtime()">' +
        '<div class="spacer"></div><button class="btn primary" onclick="loadRealtime()">검색</button>' +
      '</div>' +
      '<div class="mgmt-table-wrap"><table class="mgmt-table fault-realtime-table"><thead><tr>' +
        '<th><input id="faultCheckAll" class="mgmt-checkbox" type="checkbox" onchange="toggleAllFaults(this.checked)"></th>' +
        '<th>NO.</th><th>등급</th><th>설비</th><th>역사/시설</th><th>장비명</th><th>IP</th><th>장비종류</th><th>발생위치</th><th>장애유형</th><th>장애내용</th><th>발생시각</th><th>장애판단</th><th>임시조치</th><th>관리</th>' +
      '</tr></thead><tbody>' + rows + '</tbody></table></div>' +
      '<div class="fault-bottom-toolbar">' +
        '<div class="mgmt-actions">' +
          (canControl ? '<button id="faultTransferBtn" class="btn" disabled onclick="openTransferModal()">선택 장애 이관</button>' : '') +
          (canModify ? '<button id="faultJudgmentBtn" class="btn" disabled onclick="openJudgmentModal()">판단 적용</button>' : '') +
        '</div>' +
        '<span class="muted" id="faultSelectionCount">선택 0건</span>' +
      '</div>' +
    '</section>' +
  '</div>';
}

function checkedFaults() {
  return Array.from(document.querySelectorAll('.faultCheck:checked')).map(function (x) { return x.value; });
}

function toggleAllFaults(checked) {
  document.querySelectorAll('.faultCheck').forEach(function (x) { x.checked = checked; });
  updateRealtimeSelectionState();
}

function updateRealtimeSelectionState() {
  const count = checkedFaults().length;
  const transfer = document.getElementById('faultTransferBtn');
  const judgment = document.getElementById('faultJudgmentBtn');
  const countEl = document.getElementById('faultSelectionCount');
  const all = document.getElementById('faultCheckAll');
  if (transfer) transfer.disabled = count === 0;
  if (judgment) judgment.disabled = count === 0;
  if (countEl) countEl.textContent = '선택 ' + count + '건';
  if (all) {
    const checks = Array.from(document.querySelectorAll('.faultCheck'));
    all.checked = checks.length > 0 && checks.every(function (x) { return x.checked; });
    all.indeterminate = count > 0 && !all.checked;
  }
}

async function loadRealtime() {
  try {
    const p = {
      grade: document.getElementById('faultGrade') ? document.getElementById('faultGrade').value : '',
      linkSysCd: document.getElementById('faultSystem') ? document.getElementById('faultSystem').value : '',
      stnCd: document.getElementById('faultStation') ? document.getElementById('faultStation').value : '',
      prcsSttsCd: document.getElementById('faultStatus') ? document.getElementById('faultStatus').value : '',
      keyword: document.getElementById('faultKeyword') ? document.getElementById('faultKeyword').value : ''
    };
    FAULT_DATA = await mgmtGet('/fault/realtime-data.ajax', p);
    renderPage('faults', realtimeScreen(), '<button class="btn" onclick="loadRealtime()">새로고침</button>');
    updateRealtimeSelectionState();
  } catch (e) {
    showToast(e.message, true);
  }
}

function currentRealtimeFilters() {
  return {
    grade: document.getElementById('faultGrade') ? document.getElementById('faultGrade').value : '',
    linkSysCd: document.getElementById('faultSystem') ? document.getElementById('faultSystem').value : '',
    stnCd: document.getElementById('faultStation') ? document.getElementById('faultStation').value : '',
    prcsSttsCd: document.getElementById('faultStatus') ? document.getElementById('faultStatus').value : '',
    keyword: document.getElementById('faultKeyword') ? document.getElementById('faultKeyword').value : ''
  };
}

function downloadRealtimeExcel() {
  const q = new URLSearchParams();
  const filters = currentRealtimeFilters();
  Object.keys(filters).forEach(function (k) { if (filters[k]) q.append(k, filters[k]); });
  location.href = CONTEXT_PATH + '/fault/realtime-excel.do' + (q.toString() ? '?' + q.toString() : '');
}

async function openFaultDetail(no) {
  try {
    const d = await mgmtGet('/fault/detail.ajax', {dsbltyNo: no});
    const r = d.fault;
    const temp = faultTempAction(d.actions || []);
    showModal('<div class="fault-modal-wide">' +
      '<div class="mgmt-modal-title"><h2>장애 상세</h2></div>' +
      faultBasicInfoHtml(r, false) +
      '<h3 class="fault-section-title">장애 내용 및 판단</h3>' +
      '<div class="mgmt-form">' +
        fieldReadonly('수신된 장애내용', r.dsbltyOcrnCn || '-', true) +
        fieldReadonly('장애 판단', faultJudgmentName(r.dsbltyJgmtCd)) +
        fieldReadonly('발생·복구 상태', faultRecoveryName(r)) +
      '</div>' +
      faultActionDetailHtml(r, temp) +
      '<div class="mgmt-modal-actions">' +
        '<button class="btn" onclick="closeModal()">닫기</button>' +
        (realtimeCanModify() ? '<button class="btn" onclick="closeModal();openFaultEdit(\'' + mgmtE(no) + '\')">수정</button>' : '') +
        (r.eqpmntSn ? '<button class="btn primary" onclick="closeModal();openEquipmentDetail(\'' + mgmtE(no) + '\')">장비 상세</button>' : '') +
      '</div>' +
    '</div>');
  } catch (e) {
    showToast(e.message, true);
  }
}

function faultBasicInfoHtml(r, editable) {
  const grade = mgmtBadge(mgmtGradeName(r.dsbltyGrdCd, r.dsbltyGrdNm), mgmtGradeClass(r.dsbltyGrdCd));
  return '<h3 class="fault-section-title">장애 기본정보 <span class="fault-title-grade">' + grade + '</span></h3>' +
    '<div class="mgmt-form">' +
      fieldReadonly('설비 / 역사', (r.linkSysNm || '-') + ' / ' + (r.stnNm || '-')) +
      fieldReadonly('장비 ID / 장비명', (r.eqpmntMngNo || r.souEqpmntId || '-') + ' / ' + (r.eqpmntNm || '-')) +
      fieldReadonly('IP / 장비종류', (r.ipAddr || '-') + ' / ' + (r.eqpmntClsfNm || r.eqpmntSeCd || '-')) +
      fieldReadonly('발생위치', r.dsbltyOcrnPlcNm || r.instlPlcNm || '-') +
      fieldReadonly('장애유형 / 등급', (r.dsbltyTypeNm || '-') + ' / ' + mgmtGradeName(r.dsbltyGrdCd, r.dsbltyGrdNm)) +
      fieldReadonly('발생시각 / 경과', mgmtDt(r.dsbltyOcrnDt) + ' / ' + mgmtDuration(r.elapsedSec)) +
    '</div>';
}

function fieldReadonly(label, value, full) {
  return '<div class="mgmt-field' + (full ? ' full' : '') + '"><label>' + mgmtE(label) + '</label><div class="mgmt-readonly">' + mgmtE(value) + '</div></div>';
}

function faultActionDetailHtml(r, temp) {
  return '<h3 class="fault-section-title">임시조치 정보 ' + (temp ? '<span class="status-chip-ok">입력완료</span>' : '<span class="status-chip-off">미입력</span>') + '</h3>' +
    '<div class="mgmt-form">' +
      fieldReadonly('현상', temp && temp.symptom ? temp.symptom : '-') +
      fieldReadonly('추정 원인', temp && temp.reason ? temp.reason : (r.dsbltyRsn || '-')) +
      fieldReadonly('임시조치 내용', temp && temp.actnCn ? temp.actnCn : '-', true) +
      fieldReadonly('조치 진행상태', r.prcsSttsNm || r.prcsSttsCd || '-') +
      fieldReadonly('조치자', temp && (temp.actorName || temp.actorId) ? (temp.actorName || temp.actorId) : '-') +
      fieldReadonly('최종 조치일시', temp && temp.actnDt ? mgmtDt(temp.actnDt) : '-') +
    '</div>';
}

async function openFaultEdit(no) {
  try {
    const d = await mgmtGet('/fault/detail.ajax', {dsbltyNo: no});
    const r = d.fault;
    const temp = faultTempAction(d.actions || []);
    const processOptions = (FAULT_DATA.processCodes || []).filter(function (x) { return x.code !== 'COMPLETED'; });
    showModal('<div class="fault-modal-wide">' +
      '<div class="mgmt-modal-title"><h2>장애 수정</h2></div>' +
      faultBasicInfoHtml(r, true) +
      '<form id="faultEditForm">' +
        '<input type="hidden" name="dsbltyNo" value="' + mgmtE(r.dsbltyNo) + '">' +
        '<h3 class="fault-section-title">장애 내용 및 판단</h3>' +
        '<div class="mgmt-form">' +
          fieldReadonly('수신된 장애내용', r.dsbltyOcrnCn || '-', true) +
          '<div class="mgmt-field"><label>장애 판단</label><select class="input" name="dsbltyJgmtCd">' + judgmentOptions(r.dsbltyJgmtCd) + '</select></div>' +
          fieldReadonly('발생·복구 상태', faultRecoveryName(r)) +
        '</div>' +
        '<h3 class="fault-section-title">임시조치 정보 ' + (temp ? '<span class="status-chip-ok">입력완료</span>' : '<span class="status-chip-off">미입력</span>') + '</h3>' +
        '<div class="mgmt-form">' +
          '<div class="mgmt-field"><label>현상</label><input class="input" name="symptom" value="' + mgmtE(temp ? temp.symptom || '' : '') + '" placeholder="현상을 입력해 주세요."></div>' +
          '<div class="mgmt-field"><label>추정 원인</label><input class="input" name="actionReason" value="' + mgmtE(temp ? temp.reason || r.dsbltyRsn || '' : r.dsbltyRsn || '') + '" placeholder="추정 원인을 입력해 주세요."></div>' +
          '<div class="mgmt-field full"><label>임시조치 내용</label><textarea name="actionCn" placeholder="임시조치 내용을 입력해 주세요.">' + mgmtE(temp ? temp.actnCn || '' : '') + '</textarea></div>' +
          '<div class="mgmt-field"><label>조치 진행상태</label><select class="input" name="prcsSttsCd">' + mgmtOptions(processOptions, 'code', 'name', r.prcsSttsCd) + '</select></div>' +
          fieldReadonly('조치자', temp && (temp.actorName || temp.actorId) ? (temp.actorName || temp.actorId) : (CURRENT_USER.userNm || CURRENT_USER.userId || '-')) +
          fieldReadonly('최종 조치일시', temp && temp.actnDt ? mgmtDt(temp.actnDt) : '-') +
        '</div>' +
      '</form>' +
      '<div class="mgmt-modal-actions"><button class="btn" onclick="closeModal()">취소</button><button class="btn primary" onclick="saveFaultEdit()">변경 저장</button></div>' +
    '</div>');
  } catch (e) {
    showToast(e.message, true);
  }
}

function judgmentOptions(selected) {
  const rows = [
    {code: 'SERVICE', name: '서비스장애'},
    {code: 'STATUS', name: '상태장애'},
    {code: 'INFO', name: '정보'}
  ];
  return rows.map(function (x) {
    return '<option value="' + x.code + '" ' + (x.code === selected ? 'selected' : '') + '>' + x.name + '</option>';
  }).join('');
}

async function saveFaultEdit() {
  const form = document.getElementById('faultEditForm');
  if (!form) return;
  const params = Object.fromEntries(new FormData(form).entries());
  try {
    await mgmtPost('/fault/save.ajax', params);
    closeModal();
    showToast('정보가 수정되었습니다.');
    await loadRealtime();
  } catch (e) {
    showToast(e.message, true);
  }
}

function openJudgmentModalForOne(no) {
  document.querySelectorAll('.faultCheck').forEach(function (x) { x.checked = x.value === no; });
  updateRealtimeSelectionState();
  openJudgmentModal();
}

function openJudgmentModal() {
  const rows = selectedFaultRows();
  if (!rows.length) return showToast('장애를 선택해 주세요.', true);
  showModal('<div class="fault-action-modal">' +
    '<div class="mgmt-modal-title"><h2>장애 판단 적용</h2></div>' +
    '<div class="fault-modal-label">선택 장애 <span class="fault-count-chip">' + rows.length + '건 선택</span></div>' +
    selectionRowsHtml(rows) +
    '<div class="fault-modal-label fault-judgment-title">적용할 장애 판단 <span>선택한 장애에 동일하게 적용됩니다.</span></div>' +
    '<div class="fault-radio-list">' +
      '<label><input type="radio" name="judgmentChoice" value="SERVICE" checked><b>서비스장애</b><span>서비스에 영향을 주는 실제 장애로 분류</span></label>' +
      '<label><input type="radio" name="judgmentChoice" value="STATUS"><b>상태장애</b><span>장비 상태 변화 또는 성능 저하로 분류</span></label>' +
      '<label><input type="radio" name="judgmentChoice" value="INFO"><b>정보</b><span>운영 참고용 이벤트로 분류</span></label>' +
    '</div>' +
    '<div class="mgmt-note warn" style="margin-top:12px">판단 변경은 장애를 복구하거나 목록에서 제거하는 기능이 아닙니다. 장애 판단 종류만 변경됩니다.</div>' +
    '<div class="mgmt-modal-actions"><button class="btn" onclick="closeModal()">취소</button><button class="btn primary" onclick="applyJudgmentFromModal()">판단 적용</button></div>' +
  '</div>');
}

async function applyJudgmentFromModal() {
  const nos = checkedFaults();
  const choice = document.querySelector('input[name="judgmentChoice"]:checked');
  if (!nos.length || !choice) return showToast('장애와 판단을 선택해 주세요.', true);
  try {
    await mgmtPost('/fault/judgment.ajax', {dsbltyNos: nos.join(','), judgment: choice.value});
    closeModal();
    showToast('장애 유형이 저장되었습니다.');
    await loadRealtime();
  } catch (e) {
    showToast(e.message, true);
  }
}

function openTransferModal() {
  const rows = selectedFaultRows();
  if (!rows.length) return showToast('장애를 선택해 주세요.', true);
  showModal('<div class="fault-action-modal">' +
    '<div class="mgmt-modal-title"><h2>선택 장애이관</h2></div>' +
    '<div class="fault-confirm-title"><span class="fault-warning-icon">!</span><div><b>선택한 장애 ' + rows.length + '건을 장애이력으로 이관하시겠습니까?</b><p>이관 후에는 실시간 장애목록에서 조회되지 않습니다.</p></div></div>' +
    '<div class="fault-modal-label">선택 장애</div>' + selectionRowsHtml(rows) +
    '<ul class="fault-transfer-notes"><li>이관된 장애는 장애이력·조치 화면에서 계속 조회할 수 있습니다.</li><li>임시조치 내용과 장애판단 정보도 함께 이관됩니다.</li><li class="warn">이관 후 복구 수신 처리 기준은 개발확인필요.</li></ul>' +
    '<div class="mgmt-modal-actions"><button class="btn" onclick="closeModal()">취소</button><button class="btn primary" onclick="applyTransferFromModal()">이관</button></div>' +
  '</div>');
}

async function applyTransferFromModal() {
  const nos = checkedFaults();
  if (!nos.length) return showToast('장애를 선택해 주세요.', true);
  try {
    await mgmtPost('/fault/transfer.ajax', {dsbltyNos: nos.join(',')});
    closeModal();
    showToast('선택된 ' + nos.length + '건의 장애가 이관되었습니다.');
    await loadRealtime();
  } catch (e) {
    showToast(e.message, true);
  }
}

async function openEquipmentDetail(dsbltyNo) {
  try {
    const fd = await mgmtGet('/fault/detail.ajax', {dsbltyNo: dsbltyNo});
    const fault = fd.fault;
    if (!fault.eqpmntSn) return showToast('연결된 장비 정보가 없습니다.', true);
    const e = await mgmtGet('/facility/detail.ajax', {eqpmntSn: fault.eqpmntSn, linkSysCd: fault.linkSysCd});
    const stts = ({NORMAL:'정상',CAUTION:'주의',CRITICAL:'심각',UNKNOWN:'통신단절',WARNING:'주의'}[e.sttsCd] || e.sttsCd || '-');
    showModal('<div class="fault-modal-wide">' +
      '<div class="mgmt-modal-title"><h2>장비 상세</h2></div>' +
      '<h3 class="fault-section-title">장비 기본정보 <span class="fault-title-grade">' + mgmtBadge(faultRecoveryName(fault) === '발생 중' ? '장애 발생' : '정상', faultRecoveryName(fault) === '발생 중' ? 'bad' : '') + '</span></h3>' +
      '<div class="mgmt-form">' +
        fieldReadonly('설비구분', e.linkSysNm || fault.linkSysNm || '-') +
        fieldReadonly('장비 ID', e.eqpmntMngNo || fault.eqpmntMngNo || '-') +
        fieldReadonly('역사 / 시설', (e.stnNm || fault.stnNm || '-') + (e.instlPlcNm ? ' / ' + e.instlPlcNm : '')) +
        fieldReadonly('장비명', e.eqpmntNm || '-') +
        fieldReadonly('세부위치', e.instlPlcNm || '-') +
        fieldReadonly('장비종류', e.eqpmntClsfNm || e.eqpmntSeCd || '-') +
        fieldReadonly('IP', e.eqpmntIpAddr || '-') +
        fieldReadonly('EMS 연동대상', e.emsId || '미지정') +
      '</div>' +
      '<h3 class="fault-section-title">현재 운영정보</h3>' +
      '<div class="fault-operating-grid">' +
        '<div class="fault-operating-card ' + (e.sttsCd === 'CRITICAL' || e.sttsCd === 'UNKNOWN' ? 'bad' : '') + '"><span>운영상태</span><b>' + mgmtE(stts) + '</b></div>' +
        '<div class="fault-operating-card info"><span>최근 응답</span><b>' + mgmtE(mgmtDt(e.lastRspnsDt || e.clctDt)) + '</b></div>' +
        '<div class="fault-operating-card cpu"><span>CPU 사용률</span><b>' + (e.cpuUsgrt == null ? '수신값 확인' : mgmtE(e.cpuUsgrt + '%')) + '</b></div>' +
        '<div class="fault-operating-card memory"><span>Memory 사용률</span><b>' + (e.mmryUsgrt == null ? '수신값 확인' : mgmtE(e.mmryUsgrt + '%')) + '</b></div>' +
      '</div>' +
      '<h3 class="fault-section-title">현재 장애 요약 ' + mgmtBadge(mgmtGradeName(fault.dsbltyGrdCd, fault.dsbltyGrdNm), mgmtGradeClass(fault.dsbltyGrdCd)) + '</h3>' +
      '<div class="fault-summary-box"><span>장애유형 <b>' + mgmtE(fault.dsbltyTypeNm || '-') + '</b></span><span>발생·복구 상태 <b>' + mgmtE(faultRecoveryName(fault)) + '</b></span><span class="full">장애내용 <b>' + mgmtE(fault.dsbltyOcrnCn || '-') + '</b></span><span>발생시각 <b>' + mgmtDt(fault.dsbltyOcrnDt) + '</b></span><span>현재 경과 <b>' + mgmtDuration(fault.elapsedSec) + '</b></span></div>' +
      '<h3 class="fault-section-title">관리 메모</h3><div class="mgmt-readonly fault-memo">' + mgmtE(e.eqpmntExpln || '-') + '</div>' +
      '<div class="mgmt-modal-actions"><button class="btn" onclick="closeModal()">닫기</button>' +
        (realtimeCanModify() ? '<button class="btn primary" onclick="openEquipmentEditFromDetail(' + Number(fault.eqpmntSn) + ',\'' + mgmtE(fault.linkSysCd || '') + '\',\'' + mgmtE(dsbltyNo) + '\')">장비정보 수정</button>' : '') +
      '</div>' +
    '</div>');
  } catch (e) {
    showToast(e.message, true);
  }
}

async function openEquipmentEditFromDetail(eqpmntSn, linkSysCd, dsbltyNo) {
  closeModal();
  try {
    const e = await mgmtGet('/facility/detail.ajax', {eqpmntSn: eqpmntSn, linkSysCd: linkSysCd});
    FAULT_EQUIPMENT_EDIT = e;
    const stationOptions = '<option value="">역사/시설 미지정</option>' + mgmtOptions(FAULT_DATA.stations, 'stnCd', 'stnNm', e.stnCd);
    showModal('<div class="fault-modal-wide">' +
      '<div class="mgmt-modal-title"><h2>장비정보 수정</h2><p><span style="color:#e44">* 표시는 필수 입력항목</span></p></div>' +
      '<form id="faultEquipmentEditForm" class="mgmt-form">' +
        fieldReadonly('장비 ID', e.eqpmntMngNo || '-') +
        fieldReadonly('설비구분', e.linkSysNm || e.linkSysCd || '-') +
        '<div class="mgmt-field"><label>장비명 *</label><input class="input" name="eqpmntNm" value="' + mgmtE(e.eqpmntNm || '') + '"></div>' +
        '<div class="mgmt-field"><label>장비종류 *</label><input class="input" name="eqpmntSeCd" value="' + mgmtE(e.eqpmntSeCd || '') + '"></div>' +
        '<div class="mgmt-field"><label>역사 / 시설 *</label><select class="input" name="stnCd">' + stationOptions + '</select></div>' +
        '<div class="mgmt-field"><label>세부위치</label><input class="input" name="instlPlcNm" value="' + mgmtE(e.instlPlcNm || '') + '"></div>' +
        '<div class="mgmt-field"><label>IP *</label><input class="input" name="eqpmntIpAddr" value="' + mgmtE(e.eqpmntIpAddr || '') + '"></div>' +
        fieldReadonly('EMS 연동대상', e.emsId || '미지정') +
        '<div class="mgmt-field"><label>연동 사용 여부</label><select class="input" name="useYn"><option value="Y" ' + (e.useYn !== 'N' ? 'selected' : '') + '>사용</option><option value="N" ' + (e.useYn === 'N' ? 'selected' : '') + '>미사용</option></select></div>' +
        '<div class="mgmt-field full"><label>관리 메모</label><textarea name="eqpmntExpln" placeholder="장비 운영 및 관리에 필요한 메모를 입력해 주세요.">' + mgmtE(e.eqpmntExpln || '') + '</textarea></div>' +
      '</form>' +
      '<div class="mgmt-note warn" style="margin-top:12px">현재 장애·CPU·Memory·최근 응답시간은 연동 수신값으로 직접 수정할 수 없습니다.</div>' +
      '<div class="mgmt-modal-actions"><button class="btn" onclick="closeModal();openEquipmentDetail(\'' + mgmtE(dsbltyNo) + '\')">취소</button><button class="btn primary" onclick="saveEquipmentEdit(\'' + mgmtE(dsbltyNo) + '\')">변경 저장</button></div>' +
    '</div>');
  } catch (e) {
    showToast(e.message, true);
  }
}

function addParam(params, key, value) {
  if (value !== undefined && value !== null) params.append(key, value);
}

async function saveEquipmentEdit(dsbltyNo) {
  const form = document.getElementById('faultEquipmentEditForm');
  const base = FAULT_EQUIPMENT_EDIT;
  if (!form || !base) return;
  const f = Object.fromEntries(new FormData(form).entries());
  if (!String(f.eqpmntNm || '').trim()) return showToast('장비명을 입력해 주세요.', true);
  if (!String(f.eqpmntSeCd || '').trim()) return showToast('장비종류를 입력해 주세요.', true);
  if (!String(f.eqpmntIpAddr || '').trim()) return showToast('IP를 입력해 주세요.', true);

  const p = new URLSearchParams();
  addParam(p, 'eqpmntSn', base.eqpmntSn);
  addParam(p, 'eqpmntMngNo', base.eqpmntMngNo);
  addParam(p, 'linkSysCd', base.linkSysCd);
  addParam(p, 'emsId', base.emsId || '');
  addParam(p, 'eqpmntClsfCd', base.eqpmntClsfCd || '');
  addParam(p, 'eqpmntNm', f.eqpmntNm);
  addParam(p, 'eqpmntSeCd', f.eqpmntSeCd);
  addParam(p, 'stnCd', f.stnCd || '');
  addParam(p, 'instlPlcNm', f.instlPlcNm || '');
  addParam(p, 'eqpmntIpAddr', f.eqpmntIpAddr || '');
  addParam(p, 'macAddr', base.macAddr || '');
  addParam(p, 'eqpmntMdlNm', base.eqpmntMdlNm || '');
  addParam(p, 'eqpmntExpln', f.eqpmntExpln || '');
  addParam(p, 'useYn', f.useYn || 'Y');

  if (base.lseEqpmntSnsCsv) {
    String(base.lseEqpmntSnsCsv).split(',').forEach(function (v) { if (v.trim()) addParam(p, 'lseEqpmntSns', v.trim()); });
  }

  if (base.linkSysCd === 'VMS') {
    addParam(p, 'vmsNm', base.vmsNm || '');
    addParam(p, 'strgMthNm', base.strgMthNm || '');
    addParam(p, 'cctvNm', f.eqpmntNm);
    addParam(p, 'cnsmrNm', base.cnsmrNm || '');
    addParam(p, 'cctvMdlNm', base.cctvMdlNm || base.eqpmntMdlNm || '');
    addParam(p, 'frmwrVerNo', base.frmwrVerNo || '');
    addParam(p, 'cctvIpAddr', f.eqpmntIpAddr);
    addParam(p, 'cctvMacAddr', base.cctvMacAddr || base.macAddr || '');
    addParam(p, 'acntNm', base.acntNm || '');
    addParam(p, 'vmsSrvrIpAddr', base.vmsSrvrIpAddr || '');
    addParam(p, 'flrNm', f.instlPlcNm || base.flrNm || '');
    addParam(p, 'cmraQty', base.cmraQty || 1);
  }

  try {
    await api('/facility/save.ajax', {method: 'POST', headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8'}, body: p.toString()});
    FAULT_EQUIPMENT_EDIT = null;
    closeModal();
    showToast('장비정보가 수정되었습니다.');
    await loadRealtime();
    await openEquipmentDetail(dsbltyNo);
  } catch (e) {
    showToast(e.message, true);
  }
}

window.TNMS_PAGE_INIT = loadRealtime;
