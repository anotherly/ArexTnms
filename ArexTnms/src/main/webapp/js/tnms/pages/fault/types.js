let TYPE_DATA={};
function typeGradeOptions(rows,selected){return '<option value="">전체 등급</option>'+mgmtOptions(rows,'code','name',selected);}
function typesScreen(){const d=TYPE_DATA;return `<div class="mgmt-page"><section class="mgmt-card"><div class="mgmt-filter"><select id="typeSystem" class="input"><option value="">전체 시스템</option>${mgmtOptions(d.systems,'linkSysCd','linkSysNm')}</select><select id="typeGrade" class="input">${typeGradeOptions(d.gradeCodes)}</select><select id="typeUse" class="input"><option value="">전체 사용여부</option><option value="Y">사용</option><option value="N">미사용</option></select><input id="typeKeyword" class="input wide" placeholder="장애유형명 / 이벤트코드"><div class="spacer"></div><button class="btn primary" onclick="loadTypes()">검색</button></div><div class="mgmt-table-wrap"><table class="mgmt-table"><thead><tr><th>이벤트코드</th><th>장애유형명</th><th>시스템</th><th>기본등급</th><th>판단기준</th><th>자동종료</th><th>SMS</th><th>자동등록</th><th>사용여부</th><th>상세</th></tr></thead><tbody>${(d.types||[]).length?d.types.map(r=>`<tr><td>${mgmtE(r.evntCd)}</td><td class="left"><b>${mgmtE(r.dsbltyTypeNm)}</b></td><td>${mgmtE(r.linkSysNm||'공통')}</td><td>${mgmtBadge(mgmtGradeName(r.bscGrdCd,r.bscGrdNm),mgmtGradeClass(r.bscGrdCd))}</td><td class="left">${mgmtE(r.jgmtCrtrCn||'-')}</td><td>${mgmtE(r.autoEndYn)}</td><td>${mgmtE(r.smsUseYn)}</td><td>${mgmtE(r.autoRegYn)}</td><td>${mgmtYN(r.useYn)}</td><td><button class="btn sm" onclick="openType(${r.dsbltyTypeSn})">상세</button></td></tr>`).join(''):'<tr><td colspan="10" class="center">조회 결과가 없습니다.</td></tr>'}</tbody></table></div><div class="mgmt-note" style="margin-top:12px">기획 SVG 기준 이 화면은 <b>조회/상세 확인</b> 중심입니다. 장애유형은 설비 EMS 연동으로 등록되는 구조이므로 임의의 수동 등록·수정 기능은 추가하지 않았습니다.</div></section></div>`;}
async function loadTypes(){try{const p={linkSysCd:document.getElementById('typeSystem')?.value||'',grade:document.getElementById('typeGrade')?.value||'',useYn:document.getElementById('typeUse')?.value||'',keyword:document.getElementById('typeKeyword')?.value||''};TYPE_DATA=await mgmtGet('/fault/types-data.ajax',p);renderPage('faultTypes',typesScreen());}catch(e){showToast(e.message,true);}}
async function openType(sn){
  try{
    const r=await mgmtGet('/fault/type-detail.ajax',{dsbltyTypeSn:sn});
    const lastSync=r.mdfcnDt||r.regDt;
    const desc=r.dsbltyNm||r.jgmtCrtrCn||'-';
    showModal(`<div class="fault-type-detail-modal">
      <div class="mgmt-modal-title fault-type-detail-title">
        <div><h2>장애유형 상세</h2><p>EMS에서 자동 동기화된 장애유형 정보를 확인합니다.</p></div>
        <span class="fault-type-readonly">읽기 전용</span>
        <button type="button" class="fault-type-close" onclick="closeModal()" aria-label="닫기">×</button>
      </div>
      <h3 class="fault-type-section-title">기본 연동정보</h3>
      <div class="fault-type-grid">
        <div class="fault-type-field"><label>설비/EMS</label><div>${mgmtE(r.linkSysNm||'공통')}</div></div>
        <div class="fault-type-field"><label>장애코드</label><div>${mgmtE(r.evntCd||'-')}</div></div>
        <div class="fault-type-field"><label>장애유형명</label><div>${mgmtE(r.dsbltyTypeNm||'-')}</div></div>
        <div class="fault-type-field"><label>발생위치</label><div>${mgmtE(r.dsbltyOcrnPlcNm||'-')}</div></div>
        <div class="fault-type-field"><label>장애등급</label><div class="fault-type-grade"><i class="fault-type-grade-dot ${mgmtGradeClass(r.bscGrdCd)}"></i>${mgmtE(mgmtGradeName(r.bscGrdCd,r.bscGrdNm))}</div></div>
        <div class="fault-type-field"><label>최종 동기화 일시</label><div>${mgmtDt(lastSync)}</div></div>
        <div class="fault-type-field full"><label>장애 설명</label><div class="fault-type-description">${mgmtE(desc)}<small>EMS에서 수신한 장애 설명을 원문 기준으로 표시합니다.</small></div></div>
      </div>
      <div class="fault-type-info-note"><b>ⓘ&nbsp; 이 화면에서는 장애유형 정보를 수정하지 않습니다.</b><span>장애유형은 설비 EMS 연동 시 자동 추가·동기화되며, 발생·복구 시간은 장애이력에서 확인합니다.</span></div>
      <div class="mgmt-modal-actions fault-type-actions"><button class="btn primary" onclick="closeModal()">닫기</button></div>
    </div>`);
  }catch(e){showToast(e.message,true);}
}
window.TNMS_PAGE_INIT=loadTypes;
