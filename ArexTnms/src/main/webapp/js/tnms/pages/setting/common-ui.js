(function(){
  let data={uiSettings:[],codeGroups:[],codes:[],severityCodes:[],selectedGroupId:''};
  const settingOrder=['LIST_ROW_CNT','PSWD_CHG_NOTICE_DAY','DASHBOARD_REFRESH_SEC','ALRM_POPUP_GRD','ALRM_SOUND_GRD','DASHBOARD_55IN_USE_YN','DASHBOARD_OFFLINE_MIN'];
  const severityCodes=['NORMAL','CAUTION','CRITICAL','UNKNOWN'];
  const defaultStationPriority=['CRITICAL','CAUTION','UNKNOWN','NORMAL'];

  function option(value,label,current){return `<option value="${escapeHtml(value)}" ${String(value)===String(current)?'selected':''}>${escapeHtml(label)}</option>`}
  function selectControl(x,options){return `<select class="form-control ui-setting-value" data-code="${escapeHtml(x.uiStngCd)}">${options.map(v=>option(v[0],v[1],x.uiStngVl)).join('')}</select>`}
  function stationPriorityCodes(){
    const setting=(data.uiSettings||[]).find(x=>x.uiStngCd==='STATION_STATUS_PRIORITY');
    const values=String(setting&&setting.uiStngVl||'').split(',').map(v=>v.trim()).filter(v=>defaultStationPriority.includes(v));
    return values.length===defaultStationPriority.length&&new Set(values).size===defaultStationPriority.length?values:defaultStationPriority.slice();
  }
  function severityLabel(code){
    const item=(data.severityCodes||[]).find(x=>x.comCd===code);
    return item&&item.comCdNm ? item.comCdNm : code;
  }
  function syncPriorityFromDom(){
    const input=document.querySelector('.station-priority-value');
    const rows=[...document.querySelectorAll('.severity-settings tbody [data-severity-code]')];
    if(!input||!rows.length)return [];
    const values=rows.map(row=>row.dataset.severityCode).filter(code=>defaultStationPriority.includes(code));
    input.value=values.join(',');
    document.querySelectorAll('[data-priority-code]').forEach(cell=>{
      cell.querySelector('b').textContent=values.indexOf(cell.dataset.priorityCode)+1;
      const label=cell.querySelector('span');
      const row=document.querySelector(`[data-severity-code="${cell.dataset.priorityCode}"]`);
      const nameInput=row&&row.querySelector('.severity-name');
      if(label)label.textContent=(nameInput&&nameInput.value.trim())||severityLabel(cell.dataset.priorityCode);
    });
    return values;
  }
  function settingControl(x){
    if(x.uiStngCd==='LIST_ROW_CNT')return selectControl(x,[[10,'10개'],[20,'20개'],[50,'50개'],[100,'100개']]);
    if(x.uiStngCd==='PSWD_CHG_NOTICE_DAY')return selectControl(x,[[3,'3개월'],[6,'6개월'],[12,'12개월']]);
    if(x.uiStngCd==='DASHBOARD_REFRESH_SEC')return selectControl(x,[[5,'5초'],[10,'10초'],[30,'30초'],[60,'60초']]);
    if(x.uiStngCd==='DASHBOARD_OFFLINE_MIN')return selectControl(x,[[1,'1분'],[3,'3분'],[5,'5분'],[10,'10분']]);
    if(x.uiStngCd==='ALRM_POPUP_GRD'||x.uiStngCd==='ALRM_SOUND_GRD')return selectControl(x,[["CAUTION","주의 이상"],["CRITICAL","장애"]]);
    if(x.uiStngCd==='DASHBOARD_55IN_USE_YN')return selectControl(x,[["Y","사용"],["N","사용 안 함"]]);
    return `<input class="form-control ui-setting-value" data-code="${escapeHtml(x.uiStngCd)}" value="${escapeHtml(x.uiStngVl)}">`;
  }
  function uiRows(){
    const rows=(data.uiSettings||[]).filter(x=>!x.uiStngCd.startsWith('PUSH_')&&x.uiStngCd!=='STATION_STATUS_PRIORITY').sort((a,b)=>settingOrder.indexOf(a.uiStngCd)-settingOrder.indexOf(b.uiStngCd));
    return rows.map(x=>`<div class="label">${escapeHtml(x.uiStngNm)}</div><div class="field">${settingControl(x)}</div>`).join('');
  }
  function pushSettings(){
    return (data.uiSettings||[]).filter(x=>x.uiStngCd.startsWith('PUSH_')).map(x=>`<label class="push-toggle"><input type="checkbox" class="ui-setting-value" data-code="${escapeHtml(x.uiStngCd)}" value="Y" ${x.uiStngVl==='Y'?'checked':''}><span>${escapeHtml(x.uiStngNm)}</span></label>`).join('');
  }
  function codeRows(){
    return (data.codes||[]).length?(data.codes||[]).map(x=>`<tr data-code-row="${escapeHtml(x.comCd)}"><td>${escapeHtml(x.comCd)}</td><td><input class="input code-name" value="${escapeHtml(x.comCdNm)}"></td><td><input class="input code-seq" type="number" min="1" value="${x.comCdSeq||1}"></td><td><select class="form-control code-use"><option value="Y" ${x.comCdUseYn!=='N'?'selected':''}>Y</option><option value="N" ${x.comCdUseYn==='N'?'selected':''}>N</option></select></td><td>${permissionButton('settings','mdfcnAuthrtYn','수정','sm',"openCodeModal('"+x.comCd.replace(/'/g,"\\'")+"')")}</td></tr>`).join(''):'<tr><td colspan="5" class="empty-row">등록된 코드가 없습니다.</td></tr>';
  }
  function priorityCell(code,priority){
    if(!defaultStationPriority.includes(code))return '-';
    const rank=priority.indexOf(code)+1;
    return `<div class="severity-priority" data-priority-code="${code}"><b>${rank}</b><span>${escapeHtml(severityLabel(code))}</span><button type="button" class="priority-move" onclick="moveSeverityPriority('${code}',-1)" aria-label="위로 이동">↑</button><button type="button" class="priority-move" onclick="moveSeverityPriority('${code}',1)" aria-label="아래로 이동">↓</button></div>`;
  }
  function severityRows(){
    const defaults={NORMAL:'#45DF9A',CAUTION:'#FFCC66',CRITICAL:'#FF7389',UNKNOWN:'#8290A6'};
    const priority=stationPriorityCodes();
    return (data.severityCodes||[]).filter(x=>severityCodes.includes(x.comCd)).sort((a,b)=>priority.indexOf(a.comCd)-priority.indexOf(b.comCd)).map(x=>{
      const color=/^#[0-9a-f]{6}$/i.test(x.ext1Cn||'')?x.ext1Cn:defaults[x.comCd];
      return `<tr data-severity-code="${escapeHtml(x.comCd)}"><td><input class="input severity-name" value="${escapeHtml(x.comCdNm)}"></td><td><code>${escapeHtml(x.comCd)}</code></td><td><input type="color" class="severity-color" value="${color}"><input class="input severity-hex" value="${color}" maxlength="7"></td><td>${priorityCell(x.comCd,priority)}</td></tr>`;
    }).join('');
  }
  function render(){
    const uiSave=permissionButton('settings','mdfcnAuthrtYn','저장','primary','saveUiSection()');
    const codeAdd=permissionButton('settings','regAuthrtYn','상세코드 추가','','openCodeModal()');
    const codeSave=permissionButton('settings','mdfcnAuthrtYn','저장','primary','saveCommonCodeSection()');
    const severitySave=permissionButton('settings','mdfcnAuthrtYn','저장','primary','saveSeveritySection()');
    renderPage('settings',`<div class="settings-layout"><div class="grid cols-2"><div class="card"><div class="card-title">운영 · UI 설정</div><div class="form-grid">${uiRows()}</div><div class="push-settings"><b>푸시 알림 기능</b>${pushSettings()}</div><div class="card-actions">${uiSave}</div></div><div class="card"><div class="card-title">공통코드 관리</div><div class="split" style="grid-template-columns:260px 1fr"><div class="tree">${(data.codeGroups||[]).map(g=>`<button class="row ${g.comCdGroupId===data.selectedGroupId?'sel':''}" onclick='loadSettings(${JSON.stringify(g.comCdGroupId)})'>${escapeHtml(g.comCdGroupNm)} <span class="count">${g.codeNocs}</span></button>`).join('')}</div><div><table><thead><tr><th>코드</th><th>코드명</th><th>순서</th><th>사용</th><th>관리</th></tr></thead><tbody>${codeRows()}</tbody></table><div class="card-actions">${codeAdd}${codeSave}</div></div></div></div></div><div class="card severity-settings"><div class="card-title">이벤트 등급 · 컬러 관리 <small>표 순서가 메인 역사 대표색 판정 우선순위와 범례 순서로 적용됩니다.</small></div><input type="hidden" class="station-priority-value" value="${stationPriorityCodes().join(',')}"><table><thead><tr><th>표시명</th><th>코드</th><th>색상 선택 / HEX</th><th>역사 대표색 순위</th></tr></thead><tbody>${severityRows()}</tbody></table><div class="card-actions">${severitySave}</div></div></div>`,'');
    document.querySelectorAll('.severity-color').forEach(el=>el.addEventListener('input',()=>{el.parentElement.querySelector('.severity-hex').value=el.value.toUpperCase()}));
    document.querySelectorAll('.severity-hex').forEach(el=>el.addEventListener('input',()=>{if(/^#[0-9a-f]{6}$/i.test(el.value))el.parentElement.querySelector('.severity-color').value=el.value}));
    document.querySelectorAll('.severity-name').forEach(el=>el.addEventListener('input',()=>{
      const row=el.closest('[data-severity-code]');
      const cell=row&&document.querySelector(`[data-priority-code="${row.dataset.severityCode}"] span`);
      if(cell)cell.textContent=el.value.trim()||row.dataset.severityCode;
    }));
  }
  window.loadSettings=async function(groupId){try{const p=groupId?'?groupId='+encodeURIComponent(groupId):'';data=await api('/setting/common-ui/data.ajax'+p);render()}catch(e){showToast(e.message,true)}};
  window.moveSeverityPriority=function(code,direction){
    const tbody=document.querySelector('.severity-settings tbody');
    if(!tbody)return;
    const rows=[...tbody.querySelectorAll('[data-severity-code]')];
    const index=rows.findIndex(row=>row.dataset.severityCode===code);
    const next=index+direction;
    if(index<0||next<0||next>=rows.length)return;
    const row=rows[index], target=rows[next];
    if(direction<0)tbody.insertBefore(row,target);
    else tbody.insertBefore(target,row);
    syncPriorityFromDom();
  };
  async function saveUiSettings(){
    const list=[...document.querySelectorAll('.ui-setting-value')].map(x=>({uiStngCd:x.dataset.code,uiStngVl:x.type==='checkbox'?(x.checked?'Y':'N'):x.value.trim()}));
    await api('/setting/common-ui/ui.ajax',{method:'POST',headers:{'Content-Type':'application/json;charset=UTF-8'},body:JSON.stringify(list)});
  }
  async function saveStationPriority(){
    const values=syncPriorityFromDom();
    if(values.length!==defaultStationPriority.length)throw new Error('역사 대표색 우선순위 값을 찾을 수 없습니다.');
    await api('/setting/common-ui/ui.ajax',{method:'POST',headers:{'Content-Type':'application/json;charset=UTF-8'},body:JSON.stringify([{uiStngCd:'STATION_STATUS_PRIORITY',uiStngVl:values.join(',')}])});
  }
  async function saveSeveritySettings(){
    const original={};(data.severityCodes||[]).forEach(x=>original[x.comCd]=x);
    const rows=[...document.querySelectorAll('[data-severity-code]')];
    for(let index=0;index<rows.length;index++){
      const row=rows[index];
      const x=original[row.dataset.severityCode]||{};
      const hex=row.querySelector('.severity-hex').value.trim().toUpperCase();
      if(!/^#[0-9A-F]{6}$/.test(hex))throw new Error(`${row.dataset.severityCode} 색상은 #RRGGBB 형식으로 입력해 주세요.`);
      await api('/setting/common-ui/code.ajax',{method:'POST',body:new URLSearchParams({_authAction:'MDFCN',comCdGroupId:'SYS_STTS',comCd:row.dataset.severityCode,comCdNm:row.querySelector('.severity-name').value.trim(),comCdExpln:x.comCdExpln||'',comCdSeq:String(index+1),comCdUseYn:'Y',ext1Cn:hex,ext2Cn:x.ext2Cn||''})});
    }
  }
  window.saveUiSection=async function(){try{await saveUiSettings();await bootstrapPermissions();showToast('운영 · UI 설정을 저장했습니다.');await window.loadSettings(data.selectedGroupId)}catch(e){showToast(e.message,true)}};
  window.saveCommonCodeSection=async function(){try{
    const original={};(data.codes||[]).forEach(x=>original[x.comCd]=x);
    const rows=[...document.querySelectorAll('[data-code-row]')];
    for(const row of rows){const x=original[row.dataset.codeRow]||{};await api('/setting/common-ui/code.ajax',{method:'POST',body:new URLSearchParams({_authAction:'MDFCN',comCdGroupId:data.selectedGroupId,comCd:row.dataset.codeRow,comCdNm:row.querySelector('.code-name').value.trim(),comCdExpln:x.comCdExpln||'',comCdSeq:row.querySelector('.code-seq').value,comCdUseYn:row.querySelector('.code-use').value,ext1Cn:x.ext1Cn||'',ext2Cn:x.ext2Cn||''})})}
    showToast('공통코드 관리 내용을 저장했습니다.');await window.loadSettings(data.selectedGroupId);
  }catch(e){showToast(e.message,true)}};
  window.saveSeveritySection=async function(){try{await saveSeveritySettings();await saveStationPriority();showToast('이벤트 등급·컬러와 역사 대표색 순위를 저장했습니다.');await window.loadSettings(data.selectedGroupId)}catch(e){showToast(e.message,true)}};
  window.openCodeModal=function(code){const x=(data.codes||[]).find(v=>v.comCd===code)||{comCdGroupId:data.selectedGroupId,comCdSeq:1,comCdUseYn:'Y'};showModal(`<div class="modal-head"><h2>공통코드 ${code?'수정':'등록'}</h2><button class="modal-close" onclick="closeModal()">×</button></div><form id="codeForm"><input type="hidden" name="comCdGroupId" value="${escapeHtml(x.comCdGroupId)}"><input type="hidden" name="ext1Cn" value="${escapeHtml(x.ext1Cn||'')}"><input type="hidden" name="ext2Cn" value="${escapeHtml(x.ext2Cn||'')}"><div class="edit-form"><label>코드 *</label><div><input class="form-control" name="comCd" maxlength="30" value="${escapeHtml(x.comCd||'')}" ${code?'readonly':''} required></div><label>코드명 *</label><div><input class="form-control" name="comCdNm" maxlength="100" value="${escapeHtml(x.comCdNm||'')}" required></div><label>설명</label><div><input class="form-control" name="comCdExpln" maxlength="4000" value="${escapeHtml(x.comCdExpln||'')}"></div><label>순서</label><div><input class="form-control" name="comCdSeq" type="number" min="1" value="${x.comCdSeq||1}"></div><label>사용여부</label><div><select class="form-control" name="comCdUseYn"><option value="Y" ${x.comCdUseYn!=='N'?'selected':''}>사용</option><option value="N" ${x.comCdUseYn==='N'?'selected':''}>미사용</option></select></div></div><div class="modal-actions"><button type="button" class="btn" onclick="closeModal()">취소</button><button class="btn primary">저장</button></div></form>`);document.getElementById('codeForm').addEventListener('submit',async function(e){e.preventDefault();try{const body=new URLSearchParams(new FormData(e.target));body.set('_authAction',code?'MDFCN':'REG');await api('/setting/common-ui/code.ajax',{method:'POST',body:body});closeModal();showToast('공통코드를 저장했습니다.');await window.loadSettings(data.selectedGroupId)}catch(err){showToast(err.message,true)}})};
  window.TNMS_PAGE_INIT=window.loadSettings;
}());
