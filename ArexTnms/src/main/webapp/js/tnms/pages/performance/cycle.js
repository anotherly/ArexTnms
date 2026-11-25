let CYCLE_DATA={}, CYCLE_FILTER={linkSysCd:'',dataSeCd:''};
const CYCLE_SYSTEM_ORDER=['EMS_TX','EMS_PIDS','SCADA_SEC','PBX','VMS'];
function cycleSec(v){v=Number(v)||0;if(!v)return '미사용';if(v%3600===0&&v>=3600)return v/3600+'시간';if(v%60===0&&v>=60)return v/60+'분';return v+'초';}
function cycleStatusClass(s){return (s==='NORMAL'||s==='RECEIVED')?'normal':'nodata';}
function cycleStatusName(s){return (s==='NORMAL'||s==='RECEIVED')?'수신기록 있음':'수신기록 없음';}
function cycleHeatmap(d){const map={};(d.heatmap||[]).forEach(x=>{const dt=String(x.hourBucket||x.hourLabel||'');const h=dt.length>2?dt.slice(-2):String(dt).padStart(2,'0');map[x.linkSysCd+'_'+h]=x;});const sysMap={};(d.systems||[]).forEach(x=>sysMap[x.linkSysCd]=x);const systems=CYCLE_SYSTEM_ORDER.map(k=>sysMap[k]).filter(Boolean);const heads=Array.from({length:24},(_,i)=>`<span>${String(i).padStart(2,'0')}</span>`).join('');const rows=systems.map(sys=>`<div class="cycle-hm-row"><b>${mgmtE(sys.linkSysNm)}</b><div class="cycle-hm-cells">${Array.from({length:24},(_,i)=>{const h=String(i).padStart(2,'0'),x=map[sys.linkSysCd+'_'+h],st=x?x.execSttsCd:'NO_DATA';return `<i class="${cycleStatusClass(st)}" title="${mgmtE(sys.linkSysNm)} ${h}:00 / ${cycleStatusName(st)}"></i>`;}).join('')}</div></div>`).join('');return `<div class="cycle-heatmap"><div class="cycle-hm-head"><span>시스템 / 시간</span><div>${heads}</div></div>${rows}<div class="mgmt-legend"><span><i class="normal"></i>수신기록 있음</span><span><i class="nodata"></i>수신기록 없음(장애 단정 불가)</span></div></div>`;}
function cycleScreen(){const d=CYCLE_DATA,can=hasPermission('cycle','mdfcnAuthrtYn'),canReg=hasPermission('cycle','regAuthrtYn'),canDel=hasPermission('cycle','delAuthrtYn');return `<div class="mgmt-page"><section class="mgmt-card"><div class="mgmt-card-head"><div><h3>관리 목록</h3><small>총 ${(d.cycles||[]).length}건</small></div>${canReg?`<button type="button" class="btn primary" onclick="openCycle()">+ 등록</button>`:""}</div><div class="mgmt-filter"><select id="cycleSystem" class="input"><option value="">전체시스템</option>${mgmtOptions(d.systems,'linkSysCd','linkSysNm',CYCLE_FILTER.linkSysCd)}</select><select id="cycleDataSe" class="input"><option value="">전체 데이터 구분</option><option value="P" ${CYCLE_FILTER.dataSeCd==='P'?'selected':''}>성능·상태</option><option value="C" ${CYCLE_FILTER.dataSeCd==='C'?'selected':''}>구성</option><option value="F" ${CYCLE_FILTER.dataSeCd==='F'?'selected':''}>장애·상태</option><option value="S" ${CYCLE_FILTER.dataSeCd==='S'?'selected':''}>보안</option></select><div class="spacer"></div><button class="btn primary" onclick="loadCycles(true)">검색</button></div><div class="mgmt-table-wrap"><table class="mgmt-table"><thead><tr><th>시스템명</th><th>데이터 구분</th><th>프로토콜</th><th>성능 수집주기</th><th>PING 폴링주기</th><th>최근 수신</th><th>다음 수집</th><th>사용여부</th><th>관리</th></tr></thead><tbody>${(d.cycles||[]).length?d.cycles.map(r=>`<tr><td><b>${mgmtE(r.linkSysNm)}</b></td><td>${mgmtE(r.dataSeNm)}</td><td>${mgmtE(r.performanceProtocol||'-')}${r.pingMntrUseYn==='Y'?' / ICMP':''}</td><td>${r.perfClctUseYn==='Y'?cycleSec(r.clctCycleSec):'<span class="muted">미사용</span>'}</td><td>${r.pingMntrUseYn==='Y'?cycleSec(r.sttsMntrCycleSec):'<span class="muted">미사용</span>'}</td><td>${mgmtDt(r.lastExcnDt)}</td><td>${mgmtDt(r.nextExcnDt)}</td><td>${mgmtYN(r.useYn)}</td><td>${can||canDel?`${can?`<button class="btn sm" onclick="openCycle(${Number(r.emsId)},'${mgmtE(r.dataSeCd)}')">수정</button>`:''}${canDel?` <button class="btn sm danger-outline" onclick="deleteCycle(${Number(r.emsId)},'${mgmtE(r.dataSeCd)}')">삭제</button>`:''}`:'-'}</td></tr>`).join(''):'<tr><td colspan="9" class="center">조회 결과가 없습니다.</td></tr>'}</tbody></table></div></section><section class="mgmt-card"><div class="mgmt-card-head"><div><h3>수집 실행 현황</h3><small>오늘 00~23시 · 실제 PING·성능 수신 이력 (정상·실패 판정과 구분)</small></div></div>${cycleHeatmap(d)}</section></div>`;}
async function loadCycles(read){try{if(read&&document.getElementById('cycleSystem'))CYCLE_FILTER={linkSysCd:document.getElementById('cycleSystem').value,dataSeCd:document.getElementById('cycleDataSe').value};CYCLE_DATA=await mgmtGet('/performance/ping-cycle-data.ajax',CYCLE_FILTER);renderPage('cycle',cycleScreen());}catch(e){showToast(e.message,true);}}
function cycleToggleRow(){const perf=document.querySelector('[name=perfClctUseYn]')?.checked,ping=document.querySelector('[name=pingMntrUseYn]')?.checked;document.querySelectorAll('.perf-setting').forEach(x=>x.classList.toggle('disabled',!perf));document.querySelectorAll('.ping-setting').forEach(x=>x.classList.toggle('disabled',!ping));cycleTotal();}
function cycleTotal(){const poll=Number(document.querySelector('[name=sttsMntrCycleSec]')?.value||0),timeout=Number(document.querySelector('[name=timeoutSec]')?.value||0),retry=Number(document.querySelector('[name=rtryNocs]')?.value||0);const total=poll+(timeout*retry);const el=document.getElementById('cycleTotalJgmt');if(el)el.textContent=total+'초';}
function cycleSystemChoices(selected){
  return (CYCLE_DATA.systems||[]).map(x=>`<option value="${Number(x.emsId)}" ${String(x.emsId)===String(selected)?'selected':''}>${mgmtE(x.linkSysNm)}</option>`).join('');
}
function cycleKindChoices(selected){
  return [['P','성능·상태'],['C','구성'],['F','장애·상태'],['S','보안']].map(x=>`<option value="${x[0]}" ${x[0]===selected?'selected':''}>${x[1]}</option>`).join('');
}
async function openCycle(emsId,dataSeCd){
  try{
    const edit=emsId!==undefined && dataSeCd!==undefined;
    const r=edit?await mgmtGet('/performance/ping-cycle-detail.ajax',{emsId:emsId,dataSeCd:dataSeCd}):{
      emsId:(CYCLE_DATA.systems||[])[0]?.emsId,dataSeCd:'P',
      perfClctUseYn:'Y',pingMntrUseYn:'Y',clctCycleSec:300,sttsMntrCycleSec:30,
      timeoutSec:10,rtryNocs:3,timeoutPollSec:1,useYn:'Y',excnTm:'',cycleCrtrCn:''
    };
    if(!r.emsId){showToast('등록 가능한 시스템이 없습니다.',true);return;}
    const sys=edit?`<div class="mgmt-readonly">${mgmtE(r.linkSysNm||'')}</div><input type="hidden" name="emsId" value="${Number(r.emsId)}">`
      :`<select class="input" name="emsId" required>${cycleSystemChoices(r.emsId)}</select>`;
    const cat=edit?`<div class="mgmt-readonly">${mgmtE(r.dataSeNm||r.dataSeCd)}</div><input type="hidden" name="dataSeCd" value="${mgmtE(r.dataSeCd)}">`
      :`<select class="input" name="dataSeCd" required>${cycleKindChoices(r.dataSeCd)}</select>`;
    showModal(`<div class="mgmt-modal-title"><h2>수집주기 ${edit?'수정':'등록'}</h2><p>수집주기와 PING 상태감시 설정을 각각 관리합니다. 설정은 com_ping_info에 저장됩니다.</p></div>
      <form id="cycleForm" class="mgmt-form cycle-edit-form"><input type="hidden" name="mode" value="${edit?'UPDATE':'CREATE'}">
      <div class="mgmt-field"><label>시스템명</label>${sys}</div>
      <div class="mgmt-field"><label>데이터구분</label>${cat}</div>
      <div class="mgmt-field"><label>성능수집 프로토콜</label><div class="mgmt-readonly">${mgmtE(r.performanceProtocol||'게이트웨이 담당 설정')}</div></div>
      <div class="mgmt-field"><label>상태감시 프로토콜</label><div class="mgmt-readonly">ICMP</div></div>
      <div class="mgmt-field full cycle-switch-row"><label>성능 수집</label><label class="mgmt-switch"><input type="checkbox" name="perfClctUseYn" value="Y" ${r.perfClctUseYn!=='N'?'checked':''} onchange="cycleToggleRow()"><i></i><span>사용</span></label><small>Gateway가 com_ping_info를 참조하여 수집에 적용</small></div>
      <div class="mgmt-field perf-setting"><label>수집주기(초)</label><input class="input" type="number" min="60" max="31536000" name="clctCycleSec" value="${Number(r.clctCycleSec||300)}" required></div>
      <div class="mgmt-field perf-setting"><label>대상 장비</label><div class="mgmt-readonly">${Number(r.targetEqpmntCount||0).toLocaleString()}대 (com_device_info)</div></div>
      <div class="mgmt-field full cycle-switch-row"><label>PING 상태감시</label><label class="mgmt-switch"><input type="checkbox" name="pingMntrUseYn" value="Y" ${r.pingMntrUseYn!=='N'?'checked':''} onchange="cycleToggleRow()"><i></i><span>사용</span></label><small>Gateway가 com_ping_info를 참조하여 수집에 적용</small></div>
      <div class="mgmt-field ping-setting"><label>PING 폴링주기(초)</label><input class="input" type="number" min="1" max="30" name="sttsMntrCycleSec" value="${Number(r.sttsMntrCycleSec||30)}" oninput="cycleTotal()" required></div>
      <div class="mgmt-field ping-setting"><label>타임아웃 시간(초)</label><input class="input" type="number" min="1" max="3600" name="timeoutSec" value="${Number(r.timeoutSec||10)}" oninput="cycleTotal()" required></div>
      <div class="mgmt-field ping-setting"><label>타임아웃 횟수</label><input class="input" type="number" min="1" max="100" name="rtryNocs" value="${Number(r.rtryNocs||3)}" oninput="cycleTotal()" required></div>
      <div class="mgmt-field ping-setting"><label>타임아웃 재확인 주기(초)</label><input class="input" type="number" min="1" max="3600" name="timeoutPollSec" value="${Number(r.timeoutPollSec||1)}" required></div>
      <div class="mgmt-field"><label>설정 사용여부</label><select class="input" name="useYn"><option value="Y" ${r.useYn!=='N'?'selected':''}>사용</option><option value="N" ${r.useYn==='N'?'selected':''}>미사용</option></select></div>
      <div class="mgmt-field"><label>일일 실행시각 (선택)</label><input class="input" type="time" name="excnTm" value="${mgmtE(String(r.excnTm||'').slice(0,5))}"></div>
      <div class="mgmt-field full"><label>주기 설정 근거 / 비고 (선택)</label><input class="input" type="text" maxlength="1000" name="cycleCrtrCn" value="${mgmtE(r.cycleCrtrCn||'')}"></div>
      <div class="mgmt-field full"><label>총 판단시간</label><div class="mgmt-readonly"><b id="cycleTotalJgmt">-</b><span class="muted">폴링주기 + (타임아웃 시간 × 횟수)</span></div></div>
      </form><div class="mgmt-modal-actions"><button class="btn" onclick="closeModal()">취소</button><button class="btn primary" onclick="saveCycle()">${edit?'수정':'등록'}</button></div>`,'wide');
    cycleToggleRow();
  }catch(e){showToast(e.message,true);}
}
async function saveCycle(){
  const f=document.getElementById('cycleForm');if(!f||!f.reportValidity())return;
  const o=Object.fromEntries(new FormData(f).entries());
  o.perfClctUseYn=f.querySelector('[name=perfClctUseYn]').checked?'Y':'N';
  o.pingMntrUseYn=f.querySelector('[name=pingMntrUseYn]').checked?'Y':'N';
  try{
    await mgmtPost('/performance/ping-cycle-save.ajax',o);
    closeModal();showToast('com_ping_info 수집주기 설정을 저장했습니다.');await loadCycles(false);
  }catch(e){showToast(e.message,true);}
}
async function deleteCycle(emsId,dataSeCd){
  if(!window.confirm('선택한 수집주기 설정을 삭제하시겠습니까? 원천 수집 로그에는 영향이 없습니다.'))return;
  try{await mgmtPost('/performance/ping-cycle-delete.ajax',{emsId,dataSeCd});showToast('설정을 삭제했습니다.');await loadCycles(false);}
  catch(e){showToast(e.message,true);}
}
console.info('[TNMS CYCLE] com_ping_info CRUD r2 loaded');
window.TNMS_PAGE_INIT=()=>loadCycles(false);
