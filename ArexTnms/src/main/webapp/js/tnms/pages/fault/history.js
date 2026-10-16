let HIST_DATA = {};
let HIST_PAGE = 1;
let HIST_PAGE_SIZE = 10;
let HIST_DETAIL_ACTIONS = [];

function historyCanModify(){return hasPermission('faultHistory','mdfcnAuthrtYn') || (window.CURRENT_USER && CURRENT_USER.authrtCd==='SYS_ADMIN');}
function historyJudgmentName(v){return v==='SERVICE'?'서비스장애':v==='STATUS'?'상태장애':v==='INFO'?'정보':'미판단';}
function historyProcessOptions(rows,selected){return '<option value="">전체 처리상태</option>'+mgmtOptions(rows,'code','name',selected);}
function historyActionName(v){return ({TEMP:'임시조치',COMPLETE:'완료조치',TRANSFER:'장애 이관',JUDGMENT:'장애판단',RECOVERY:'장애 복구'}[v]||v||'-');}
function historyStatusBadge(r){const c=r.prcsSttsCd;return mgmtBadge(r.prcsSttsNm||c||'-',c==='COMPLETED'?'':c==='TEMP_ACTN'?'info':c==='CONFIRMED'?'warn':'off');}
function historyFilters(){return {
  startDt:document.getElementById('histStart')?.value||mgmtToday(-30),
  endDt:document.getElementById('histEnd')?.value||mgmtToday(),
  linkSysCd:document.getElementById('histSystem')?.value||'',
  prcsSttsCd:document.getElementById('histStatus')?.value||'',
  keyword:document.getElementById('histKeyword')?.value||''
};}
function historyPager(total){const pages=Math.max(1,Math.ceil(total/HIST_PAGE_SIZE));if(HIST_PAGE>pages)HIST_PAGE=pages;let h='<div class="mgmt-pager">';
 h+='<button '+(HIST_PAGE<=1?'disabled':'')+' onclick="historyGoPage('+(HIST_PAGE-1)+')">‹</button>';
 const s=Math.max(1,HIST_PAGE-2),e=Math.min(pages,s+4);for(let i=s;i<=e;i++)h+='<button class="'+(i===HIST_PAGE?'active':'')+'" onclick="historyGoPage('+i+')">'+i+'</button>';
 h+='<button '+(HIST_PAGE>=pages?'disabled':'')+' onclick="historyGoPage('+(HIST_PAGE+1)+')">›</button></div>';return h;}
function historyGoPage(p){HIST_PAGE=Math.max(1,p);renderPage('faultHistory',historyScreen());}

function historyScreen(){
 const d=HIST_DATA,s=d.summary||{},can=historyCanModify(),all=d.faults||[];
 const start=(HIST_PAGE-1)*HIST_PAGE_SIZE, rows=all.slice(start,start+HIST_PAGE_SIZE);
 const prev=HIST_DATA._filters||{startDt:mgmtToday(-30),endDt:mgmtToday(),linkSysCd:'',prcsSttsCd:'',keyword:''};
 const body=rows.length?rows.map((r,i)=>`<tr>
  <td><input class="mgmt-checkbox histChk" type="checkbox" value="${mgmtE(r.dsbltyNo)}"></td>
  <td>${start+i+1}</td>
  <td>${mgmtBadge(mgmtGradeName(r.dsbltyGrdCd,r.dsbltyGrdNm),mgmtGradeClass(r.dsbltyGrdCd))}</td>
  <td>${mgmtE(historyJudgmentName(r.dsbltyJgmtCd))}</td>
  <td>${mgmtE(r.linkSysNm||'-')}</td><td>${mgmtE(r.stnNm||r.dsbltyOcrnPlcNm||'-')}</td>
  <td class="left">${mgmtE(r.eqpmntNm||'-')}</td><td>${mgmtE(r.ipAddr||'-')}</td>
  <td class="left fault-content-cell" title="${mgmtE(r.dsbltyOcrnCn||'')}">${mgmtE(r.dsbltyOcrnCn||'-')}</td>
  <td>${mgmtDt(r.dsbltyOcrnDt)}</td><td>${mgmtDt(r.dsbltyEndDt)}</td><td>${historyStatusBadge(r)}</td>
  <td><div class="fault-row-actions">${can?`<button class="btn sm" onclick="openHistoryEdit('${mgmtE(r.dsbltyNo)}')">수정</button>`:''}<button class="btn sm" onclick="openHistoryDetail('${mgmtE(r.dsbltyNo)}')">상세</button></div></td>
 </tr>`).join(''):'<tr><td colspan="13" class="center">조회 결과가 없습니다.</td></tr>';
 return `<div class="mgmt-page fault-history-page">
  <div class="mgmt-summary four">
   <div class="mgmt-stat"><div class="label">전체</div><strong>${mgmtNum(s.totalCount)}</strong><small>조회기간</small></div>
   <div class="mgmt-stat warn"><div class="label">미조치</div><strong>${mgmtNum(s.unconfirmedCount)}</strong><small>미확인</small></div>
   <div class="mgmt-stat"><div class="label">임시조치</div><strong>${mgmtNum(s.tempCount)}</strong><small>임시조치 등록</small></div>
   <div class="mgmt-stat good"><div class="label">완료조치</div><strong>${mgmtNum(s.completedCount)}</strong><small>완료</small></div>
  </div>
  <section class="mgmt-card">
   <div class="mgmt-filter">
    <input id="histStart" class="input" type="date" value="${mgmtE(prev.startDt)}"><span>~</span><input id="histEnd" class="input" type="date" value="${mgmtE(prev.endDt)}">
    <select id="histSystem" class="input"><option value="">전체 설비</option>${mgmtOptions(d.systems,'linkSysCd','linkSysNm',prev.linkSysCd)}</select>
    <select id="histStatus" class="input">${historyProcessOptions(d.processCodes,prev.prcsSttsCd)}</select>
    <input id="histKeyword" class="input wide" value="${mgmtE(prev.keyword||'')}" placeholder="장애번호 / 장비명 / 장애내용" onkeydown="if(event.key==='Enter')loadHistory()">
    <div class="spacer"></div><button class="btn primary" onclick="loadHistory()">검색</button><button class="btn" onclick="downloadHistoryExcel()">Excel</button>
   </div>
   <div class="mgmt-card-head"><div><h3>장애 이력 목록</h3><small>총 ${all.length.toLocaleString()}건 · 최신순</small></div></div>
   <div class="mgmt-table-wrap"><table class="mgmt-table history-table"><thead><tr>
    <th><input class="mgmt-checkbox" type="checkbox" onchange="document.querySelectorAll('.histChk').forEach(x=>x.checked=this.checked)"></th>
    <th>NO.</th><th>등급</th><th>장애판단</th><th>설비</th><th>역사/시설</th><th>장비명</th><th>IP</th><th>장애내용</th><th>발생일시</th><th>복구일시</th><th>조치상태</th><th>관리</th>
   </tr></thead><tbody>${body}</tbody></table></div>
   ${historyPager(all.length)}
  </section>
 </div>`;
}

async function loadHistory(){
 try{const p=historyFilters();HIST_DATA=await mgmtGet('/fault/history-data.ajax',p);HIST_DATA._filters=p;HIST_PAGE=1;renderPage('faultHistory',historyScreen());}
 catch(e){showToast(e.message,true);}
}

function historyBasicGrid(r){return `<div class="history-basic-grid">
 <div><span>장애 ID</span><b>${mgmtE(r.dsbltyNo||'-')}</b></div><div><span>등급</span><b>${mgmtBadge(mgmtGradeName(r.dsbltyGrdCd,r.dsbltyGrdNm),mgmtGradeClass(r.dsbltyGrdCd))}</b></div>
 <div><span>장애판단</span><b>${mgmtE(historyJudgmentName(r.dsbltyJgmtCd))}</b></div><div><span>설비</span><b>${mgmtE(r.linkSysNm||'-')}</b></div>
 <div><span>역사/시설</span><b>${mgmtE(r.stnNm||r.dsbltyOcrnPlcNm||'-')}</b></div><div><span>장비명</span><b>${mgmtE(r.eqpmntNm||'-')}</b></div>
 <div><span>IP</span><b>${mgmtE(r.ipAddr||'-')}</b></div><div><span>발생일시</span><b>${mgmtDt(r.dsbltyOcrnDt)}</b></div>
 <div><span>복구일시</span><b>${mgmtDt(r.dsbltyEndDt)}</b></div><div class="wide"><span>장애내용</span><b>${mgmtE(r.dsbltyOcrnCn||'-')}</b></div>
 </div>`;}
function latestAction(actions,type){for(let i=actions.length-1;i>=0;i--)if(actions[i].actnSeCd===type)return actions[i];return null;}
function historyActionTimeline(r,actions){let items=[`<div class="history-timeline-item"><i></i><b>장애 발생</b><span>${mgmtDt(r.dsbltyOcrnDt)}</span><p>${mgmtE(r.dsbltyOcrnCn||'')}</p></div>`];
 actions.forEach((a,i)=>items.push(`<button class="history-timeline-item action" onclick="showHistoryAction(${i})"><i></i><b>${mgmtE(historyActionName(a.actnSeCd))}</b><span>${mgmtDt(a.actnDt)}</span><p>${mgmtE(a.actnCn||'')}</p></button>`));
 if(r.dsbltyEndDt)items.push(`<div class="history-timeline-item"><i></i><b>장애 복구</b><span>${mgmtDt(r.dsbltyEndDt)}</span></div>`);return items.join('');}
function historyActionRows(actions){return actions.length?actions.map((a,i)=>`<tr onclick="showHistoryAction(${i})" style="cursor:pointer"><td>${i+1}</td><td>${mgmtE(historyActionName(a.actnSeCd))}</td><td>${mgmtDt(a.actnDt)}</td><td>${mgmtE(a.actorName||a.actorId||'-')}</td><td class="left">${mgmtE(a.actnCn||'-')}</td></tr>`).join(''):'<tr><td colspan="5" class="center">등록된 처리·조치 이력이 없습니다.</td></tr>';}
function historyActionDetailHtml(a){if(!a)return '<div class="mgmt-empty">처리·조치 이력을 선택해 주세요.</div>';return `<div class="history-action-detail-grid">
 <div><span>구분 / 조치일시</span><b>${mgmtE(historyActionName(a.actnSeCd))} / ${mgmtDt(a.actnDt)}</b></div><div><span>조치자</span><b>${mgmtE(a.actorName||a.actorId||'-')}</b></div>
 <div><span>장애현상</span><b>${mgmtE(a.symptom||'-')}</b></div><div><span>장애원인</span><b>${mgmtE(a.reason||'-')}</b></div>
 <div class="wide"><span>조치내용</span><b>${mgmtE(a.actnCn||'-')}</b></div><div><span>조치결과</span><b>${mgmtE(a.result||'-')}</b></div><div><span>향후대책</span><b>${mgmtE(a.plan||'-')}</b></div>
 </div>`;}
function showHistoryAction(idx){const el=document.getElementById('historyActionDetail');if(el)el.innerHTML=historyActionDetailHtml(HIST_DETAIL_ACTIONS[idx]);}

async function openHistoryDetail(no){
 try{const d=await mgmtGet('/fault/detail.ajax',{dsbltyNo:no}),r=d.fault,a=d.actions||[];HIST_DETAIL_ACTIONS=a;
 showModal(`<div class="history-detail-modal">
  <div class="mgmt-modal-title"><h2>장애이력 상세</h2><p>장애 발생부터 복구·조치까지 전체 처리 이력을 확인합니다.</p></div>
  <h3 class="fault-section-title">기본정보</h3>${historyBasicGrid(r)}
  <div class="history-detail-split"><div><h3 class="fault-section-title">처리 Timeline</h3><div class="history-timeline">${historyActionTimeline(r,a)}</div></div>
  <div><h3 class="fault-section-title">처리·조치 이력</h3><div class="mgmt-table-wrap"><table class="mgmt-table compact"><thead><tr><th>NO.</th><th>이력구분</th><th>변경일시</th><th>변경자</th><th>변경내용</th></tr></thead><tbody>${historyActionRows(a)}</tbody></table></div>
  <h3 class="fault-section-title">선택 조치 상세</h3><div id="historyActionDetail">${historyActionDetailHtml(a.length?a[a.length-1]:null)}</div></div></div>
  <h3 class="fault-section-title">관리메모</h3><div class="mgmt-readonly fault-memo">${mgmtE(r.mgmtMemoCn||'-')}</div>
  <div class="mgmt-modal-actions">${historyCanModify()?`<button class="btn primary" onclick="closeModal();openHistoryEdit('${mgmtE(no)}')">조치 수정</button>`:''}<button class="btn" onclick="closeModal()">닫기</button></div>
 </div>`);
 }catch(e){showToast(e.message,true);}
}

async function openHistoryEdit(no){
 try{const d=await mgmtGet('/fault/detail.ajax',{dsbltyNo:no}),r=d.fault,a=d.actions||[],temp=latestAction(a,'TEMP'),done=latestAction(a,'COMPLETE');
 const proc=(HIST_DATA.processCodes||[]).filter(x=>x.code!=='CONFIRMED');
 showModal(`<div class="history-edit-modal">
  <div class="mgmt-modal-title"><h2>장애 조치 수정</h2><p>장애 판단과 조치 정보를 수정합니다. 장애 ID·발생/복구 정보는 변경할 수 없습니다.</p></div>
  <form id="historyEditForm"><input type="hidden" name="dsbltyNo" value="${mgmtE(no)}">
   <h3 class="fault-section-title">기본정보</h3><div class="history-edit-basic">
    <div><label>장애 ID</label><span>${mgmtE(r.dsbltyNo)}</span></div><div><label>등급</label><span>${mgmtBadge(mgmtGradeName(r.dsbltyGrdCd,r.dsbltyGrdNm),mgmtGradeClass(r.dsbltyGrdCd))}</span></div>
    <div><label>장애판단</label><select name="dsbltyJgmtCd" class="input"><option value="">미판단</option><option value="SERVICE" ${r.dsbltyJgmtCd==='SERVICE'?'selected':''}>서비스장애</option><option value="STATUS" ${r.dsbltyJgmtCd==='STATUS'?'selected':''}>상태장애</option><option value="INFO" ${r.dsbltyJgmtCd==='INFO'?'selected':''}>정보</option></select></div>
    <div><label>설비</label><span>${mgmtE(r.linkSysNm||'-')}</span></div><div><label>역사/시설</label><span>${mgmtE(r.stnNm||r.dsbltyOcrnPlcNm||'-')}</span></div><div><label>장비명</label><span>${mgmtE(r.eqpmntNm||'-')}</span></div>
    <div><label>IP</label><span>${mgmtE(r.ipAddr||'-')}</span></div><div><label>발생일시</label><span>${mgmtDt(r.dsbltyOcrnDt)}</span></div><div><label>복구일시</label><span>${mgmtDt(r.dsbltyEndDt)}</span></div><div class="wide"><label>장애내용</label><span>${mgmtE(r.dsbltyOcrnCn||'-')}</span></div>
   </div>
   <h3 class="fault-section-title">조치정보</h3><div class="mgmt-form history-action-form">
    <div class="mgmt-field full"><label>현상</label><textarea name="symptom" placeholder="장애 현상을 입력해 주세요.">${mgmtE(temp?.symptom||done?.symptom||'')}</textarea></div>
    <div class="mgmt-field full"><label>추정 원인</label><textarea name="actionReason" placeholder="추정 원인을 입력해 주세요.">${mgmtE(temp?.reason||done?.reason||r.dsbltyRsn||'')}</textarea></div>
    <div class="mgmt-field full"><label>임시조치 내용</label><textarea name="tempActionCn" placeholder="임시조치 내용을 입력해 주세요.">${mgmtE(temp?.actnCn||'')}</textarea></div>
    <div class="mgmt-field full"><label>완료조치 내용</label><textarea name="completeActionCn" placeholder="완료조치 내용을 입력해 주세요.">${mgmtE(done?.actnCn||'')}</textarea></div>
    <div class="mgmt-field"><label>조치상태</label><select name="prcsSttsCd" class="input">${mgmtOptions(proc,'code','name',r.prcsSttsCd)}</select></div>
    <div class="mgmt-field"><label>조치자</label><div class="mgmt-readonly">${mgmtE((window.CURRENT_USER&&(CURRENT_USER.userNm||CURRENT_USER.userId))||done?.actorName||temp?.actorName||'-')}</div></div>
    <div class="mgmt-field"><label>최종 조치일시</label><div class="mgmt-readonly">${mgmtDt((a.length?a[a.length-1].actnDt:null))}</div></div>
    <div class="mgmt-field full"><label>관리메모</label><input class="input" name="mgmtMemoCn" value="${mgmtE(r.mgmtMemoCn||'')}" placeholder="관리메모를 입력해 주세요."></div>
    <div class="mgmt-field full"><label>향후대책</label><textarea name="plan" placeholder="완료조치 시 필요한 향후대책을 입력해 주세요.">${mgmtE(done?.plan||'')}</textarea></div>
    <div class="mgmt-field full"><label>조치결과</label><textarea name="result" placeholder="완료조치 결과를 입력해 주세요.">${mgmtE(done?.result||'')}</textarea></div>
   </div>
  </form>
  <div class="mgmt-note">장애 ID와 발생·복구 데이터는 원천 연동정보이므로 수정하지 않습니다.</div>
  <div class="mgmt-modal-actions"><button class="btn" onclick="closeModal()">취소</button><button class="btn primary" onclick="saveHistoryEdit()">변경 저장</button></div>
 </div>`);
 }catch(e){showToast(e.message,true);}
}
async function saveHistoryEdit(){const f=document.getElementById('historyEditForm');if(!f)return;try{await mgmtPost('/fault/save.ajax',Object.fromEntries(new FormData(f).entries()));closeModal();showToast('장애 조치 정보를 저장했습니다.');loadHistory();}catch(e){showToast(e.message,true);}}
async function downloadHistoryExcel(){try{const p=HIST_DATA._filters||historyFilters(),q=new URLSearchParams();Object.keys(p).forEach(k=>{if(p[k])q.append(k,p[k]);});const res=await fetch(CONTEXT_PATH+'/fault/history-excel.do?'+q.toString(),{credentials:'same-origin'});if(!res.ok)throw new Error('Excel 다운로드에 실패했습니다.');const blob=await res.blob(),a=document.createElement('a');a.href=URL.createObjectURL(blob);a.download='TNMS_장애이력조치.xlsx';document.body.appendChild(a);a.click();a.remove();setTimeout(()=>URL.revokeObjectURL(a.href),500);showToast('Excel 다운로드가 완료되었습니다.');}catch(e){showToast(e.message,true);}}
window.TNMS_PAGE_INIT=loadHistory;
