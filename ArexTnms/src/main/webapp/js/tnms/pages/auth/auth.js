const REMOVED_MENU_NAMES = new Set(['통합 대시보드','역사·선로 현황','CCTV 영상관리','알림·SMS 설정']);
const SYSTEM_ADMIN_AUTHRT_CD = 'SYS_ADMIN';
const AUTH_COLUMNS=[['listAuthrtYn','목록'],['dtlAuthrtYn','상세'],['regAuthrtYn','등록'],['mdfcnAuthrtYn','수정'],['delAuthrtYn','삭제']];
const MENU_CAPABILITIES={
  systems:['listAuthrtYn','dtlAuthrtYn','regAuthrtYn','mdfcnAuthrtYn','delAuthrtYn'],
  equipment:['listAuthrtYn','dtlAuthrtYn','regAuthrtYn','mdfcnAuthrtYn','delAuthrtYn'],
  scada:['listAuthrtYn','dtlAuthrtYn','regAuthrtYn','mdfcnAuthrtYn','delAuthrtYn'],
  switch:['listAuthrtYn','dtlAuthrtYn','regAuthrtYn','mdfcnAuthrtYn','delAuthrtYn'],
  cctv:['listAuthrtYn','dtlAuthrtYn','regAuthrtYn','mdfcnAuthrtYn','delAuthrtYn'],
  users:['listAuthrtYn','dtlAuthrtYn','regAuthrtYn','mdfcnAuthrtYn','delAuthrtYn'],
  auth:['listAuthrtYn','dtlAuthrtYn','regAuthrtYn','mdfcnAuthrtYn','delAuthrtYn'],
  settings:['listAuthrtYn','regAuthrtYn','mdfcnAuthrtYn'],
  logs:['listAuthrtYn','dtlAuthrtYn'],
  performance:['listAuthrtYn'],cycle:['listAuthrtYn'],threshold:['listAuthrtYn'],raw:['listAuthrtYn'],
  faults:['listAuthrtYn'],faultHistory:['listAuthrtYn'],exceptions:['listAuthrtYn'],faultTypes:['listAuthrtYn'],reports:['listAuthrtYn']
};
function menuCapabilities(menu){return MENU_CAPABILITIES[menu.screenKey]||['listAuthrtYn'];}
function permissionCell(menu,key,protectedAuth){
  if(menuCapabilities(menu).indexOf(key)<0)return '<td class="perm-na">-</td>';
  return `<td><input class="perm-check" type="checkbox" data-key="${key}" ${menu[key]==='Y'?'checked':''} ${!hasPermission('auth','mdfcnAuthrtYn')||protectedAuth?'disabled':''}></td>`;
}
let CURRENT_AUTH_CD=null;
let CURRENT_AUTH_DATA=null;
let AUTH_DIRTY=false;

function auth(){
  return layout('auth',`<div class="auth-planner-page"><div class="auth-layout"><section class="planner-card auth-list-card"><div class="planner-card-head"><div><h3>권한 목록</h3><p>권한을 선택하여 메뉴·기능 권한을 설정합니다.</p></div></div><div class="auth-list" id="authRows"><div class="planner-empty compact">조회 중입니다.</div></div>${hasPermission('auth','regAuthrtYn')?'<button class="auth-add-button" type="button" onclick="openAuthModal()">+ 권한 추가</button>':''}</section><section class="planner-card auth-detail-card" id="authDetail"><div class="planner-empty">왼쪽에서 권한을 선택해 주세요.</div></section></div></div>`);
}
function authActionCode(code){return JSON.stringify(String(code||''));}
function setDirty(value){AUTH_DIRTY=!!value;document.body.classList.toggle('auth-dirty',AUTH_DIRTY);const save=document.getElementById('authSaveButton');if(save)save.classList.toggle('dirty',AUTH_DIRTY);}
function setSaveAction(protectedAuth){
  const area=document.getElementById('pageActions');if(!area)return;
  area.innerHTML=hasPermission('auth','mdfcnAuthrtYn')&&!protectedAuth?'<button id="authSaveButton" class="btn primary auth-save-button" type="button" onclick="savePermissions()">권한 저장</button>':'';
}
function confirmDiscard(){return !AUTH_DIRTY || confirm('수정한 권한 내용을 저장하지 않고 이동하시겠습니까?');}
async function loadAuths(selected){
  try{
    const list=await api('/auth/list.ajax');const target=selected||CURRENT_AUTH_CD||(list[0]&&list[0].authrtCd);
    document.getElementById('authRows').innerHTML=list.length?list.map(a=>`<button type="button" class="auth-list-row ${String(a.authrtCd)===String(target)?'selected':''}" data-authrt-cd="${escapeHtml(a.authrtCd)}" onclick='loadAuthDetail(${authActionCode(a.authrtCd)})'><span><b>${escapeHtml(a.authrtNm)}</b><small>${escapeHtml(a.authrtCd)}</small></span><em>${a.userNocs||0}명</em></button>`).join(''):'<div class="planner-empty compact">등록된 권한이 없습니다.</div>';
    if(target)await loadAuthDetail(target,false,true);
  }catch(e){showToast(e.message,true);}
}
async function loadAuthDetail(authrtCd,reloadList=true,skipConfirm=false){
  if(!skipConfirm&&String(authrtCd)!==String(CURRENT_AUTH_CD)&&!confirmDiscard())return;
  try{
    const a=await api('/auth/detail.ajax?authrtCd='+encodeURIComponent(authrtCd));
    CURRENT_AUTH_CD=authrtCd;CURRENT_AUTH_DATA={authrtCd:a.authrtCd,authrtNm:a.authrtNm,authrtExpln:a.authrtExpln||''};setDirty(false);
    if(reloadList)document.querySelectorAll('#authRows .auth-list-row').forEach(x=>x.classList.toggle('selected',x.dataset.authrtCd===String(authrtCd)));
    const visible=(a.menuAuthList||[]).filter(m=>!REMOVED_MENU_NAMES.has(m.menuNm));const protectedAuth=a.authrtCd===SYSTEM_ADMIN_AUTHRT_CD;setSaveAction(protectedAuth);
    document.getElementById('authDetail').innerHTML=`<div class="planner-card-head auth-detail-head"><div><h3>메뉴·기능 권한</h3><p><b>${escapeHtml(a.authrtNm)}</b> · ${escapeHtml(a.authrtCd)}</p></div><div class="row-actions">${hasPermission('auth','mdfcnAuthrtYn')?`<button class="btn" type="button" onclick="openAuthModal(CURRENT_AUTH_DATA)">권한명 수정</button>`:''}${hasPermission('auth','delAuthrtYn')&&!protectedAuth?`<button class="btn danger-outline" type="button" onclick='deleteAuth(${authActionCode(a.authrtCd)})'>권한 삭제</button>`:''}</div></div><div class="permission-note">각 화면에 실제 구현된 기능만 권한으로 표시합니다. 상세·등록·수정·삭제 권한을 선택하면 목록 권한이 자동 포함됩니다. 대시보드는 모든 로그인 사용자가 조회하므로 권한 대상에서 제외합니다.${protectedAuth?' 시스템 관리자 권한은 보호되어 직접 수정할 수 없습니다.':''}</div><div class="table-scroll"><table class="planner-table permission-table"><thead><tr><th>메뉴</th>${AUTH_COLUMNS.map(c=>`<th>${c[1]}</th>`).join('')}</tr></thead><tbody>${visible.map(m=>`<tr data-menu-sn="${m.menuSn}" data-screen-key="${escapeHtml(m.screenKey||'')}"><td><b>${escapeHtml(m.menuNm)}</b></td>${AUTH_COLUMNS.map(c=>permissionCell(m,c[0],protectedAuth)).join('')}</tr>`).join('')}</tbody></table></div>`;
    enhanceTables(document.getElementById('authDetail'));
    document.querySelectorAll('#authDetail .perm-check:not(:disabled)').forEach(input=>input.addEventListener('change',function(){const row=input.closest('tr');if(input.dataset.key!=='listAuthrtYn'&&input.checked){const list=row.querySelector('[data-key="listAuthrtYn"]');if(list)list.checked=true;}if(input.dataset.key==='listAuthrtYn'&&!input.checked){row.querySelectorAll('.perm-check').forEach(x=>x.checked=false);}setDirty(true);}));
  }catch(e){showToast(e.message,true);}
}
function openAuthModal(authData){
  const a=authData||{},edit=!!a.authrtCd;
  showModal(`<div class="modal-head"><div><h2>${edit?'권한 수정':'권한 추가'}</h2><p>${edit?'권한명과 설명을 수정합니다.':'새로운 역할 권한을 추가합니다.'}</p></div><button class="modal-close" onclick="closeModal()">×</button></div><form id="authForm"><div class="edit-form planner-edit-form"><label>권한코드 *</label><div class="full"><input class="form-control" name="authrtCd" value="${escapeHtml(a.authrtCd||'')}" maxlength="30" pattern="[A-Z][A-Z0-9_]{2,29}" ${edit?'readonly':''} placeholder="예: FACILITY_MANAGER" required><span class="form-help">등록 후 권한코드는 변경할 수 없습니다.</span></div><label>권한명 *</label><div class="full"><input class="form-control" name="authrtNm" value="${escapeHtml(a.authrtNm||'')}" maxlength="100" required></div><label>권한 설명</label><div class="full"><textarea class="form-control textarea" name="authrtExpln" maxlength="4000">${escapeHtml(a.authrtExpln||'')}</textarea></div></div><input type="hidden" name="useYn" value="Y"><div class="modal-actions"><button type="button" class="btn" onclick="closeModal()">취소</button><button class="btn primary" type="submit">${edit?'수정':'추가'}</button></div></form>`);
  document.getElementById('authForm').addEventListener('submit',saveAuth);
}
async function saveAuth(e){e.preventDefault();const form=e.target,authrtCd=form.querySelector('[name=authrtCd]').value.trim().toUpperCase(),edit=!!CURRENT_AUTH_DATA&&CURRENT_AUTH_DATA.authrtCd===authrtCd;try{const data=await api(edit?'/auth/update.ajax':'/auth/insert.ajax',{method:'POST',body:new URLSearchParams(new FormData(form))});closeModal();showToast(edit?'권한을 수정했습니다.':'권한을 추가했습니다.');await loadAuths(edit?authrtCd:data.authrtCd);}catch(error){showToast(error.message,true);}}
async function deleteAuth(authrtCd){if(!confirm('선택한 권한을 삭제하시겠습니까?\n해당 권한은 미사용 처리됩니다.'))return;try{await api('/auth/delete.ajax',{method:'POST',body:new URLSearchParams({authrtCd})});CURRENT_AUTH_CD=null;CURRENT_AUTH_DATA=null;setDirty(false);showToast('권한을 삭제했습니다.');await loadAuths();}catch(e){showToast(e.message,true);}}
async function savePermissions(){
  if(!CURRENT_AUTH_CD)return;
  const rows=[...document.querySelectorAll('#authDetail tbody tr')];const menuAuthList=rows.map(row=>{const item={menuSn:Number(row.dataset.menuSn),screenKey:row.dataset.screenKey||'',ctrlAuthrtYn:'N'};AUTH_COLUMNS.forEach(c=>item[c[0]]='N');row.querySelectorAll('input[data-key]').forEach(input=>item[input.dataset.key]=input.checked?'Y':'N');return item;});
  try{await api('/auth/savePermissions.ajax',{method:'POST',headers:{'Content-Type':'application/json;charset=UTF-8'},body:JSON.stringify({authrtCd:CURRENT_AUTH_CD,menuAuthList})});setDirty(false);showToast('메뉴·기능 권한을 저장했습니다.');await bootstrapPermissions();await loadAuthDetail(CURRENT_AUTH_CD,false,true);}catch(e){showToast(e.message,true);}
}
function bindUnsavedGuard(){
  window.addEventListener('beforeunload',function(e){if(!AUTH_DIRTY)return;e.preventDefault();e.returnValue='';});
  document.querySelectorAll('.sidebar a').forEach(link=>link.addEventListener('click',function(e){if(!AUTH_DIRTY)return;if(!confirmDiscard())e.preventDefault();else setDirty(false);}));
}
window.TNMS_PAGE_INIT=async function(){renderPage('auth',auth());bindUnsavedGuard();await loadAuths();};
