const REMOVED_MENU_NAMES = new Set(['역사·선로 현황','CCTV 영상관리','알림·SMS 설정']);
const SYSTEM_ADMIN_AUTHRT_CD = 'SYS_ADMIN';
function auth(){
  const actions=permissionButton('auth','regAuthrtYn','권한 추가','primary','openAuthModal()');
  return layout('auth',`<div class="split"><div class="card"><div class="card-title">권한 목록</div><div class="tree" id="authRows"><div class="row">조회 중입니다.</div></div></div><div class="card" id="authDetail"><div class="empty-row">왼쪽에서 권한을 선택해 주세요.</div></div></div>`,actions)
};
let CURRENT_AUTH_CD=null;
let CURRENT_AUTH_DATA=null;
function authActionCode(code){return JSON.stringify(String(code||''));}
async function loadAuths(selected){
  try{
    const list=await api('/auth/list.ajax');
    const target=selected||CURRENT_AUTH_CD||(list[0]&&list[0].authrtCd);
    document.getElementById('authRows').innerHTML=list.length?list.map(a=>{const code=authActionCode(a.authrtCd);return `<div class="row clickable ${String(a.authrtCd)===String(target)?'sel':''}" data-authrt-cd="${escapeHtml(a.authrtCd)}" onclick='loadAuthDetail(${code})'>${escapeHtml(a.authrtNm)} <span class="count">${a.userNocs||0}명</span></div>`}).join(''):'<div class="row">등록된 권한이 없습니다.</div>';
    if(target)await loadAuthDetail(target,false)
  }catch(e){showToast(e.message,true)}
}
async function loadAuthDetail(authrtCd,reloadList=true){
  try{
    CURRENT_AUTH_CD=authrtCd;
    const a=await api('/auth/detail.ajax?authrtCd='+encodeURIComponent(authrtCd));
    const visibleMenuAuth=(a.menuAuthList||[]).filter(m=>!REMOVED_MENU_NAMES.has(m.menuNm));
    CURRENT_AUTH_DATA={authrtCd:a.authrtCd,authrtNm:a.authrtNm,authrtExpln:a.authrtExpln||''};
    if(reloadList){document.querySelectorAll('#authRows .row').forEach(x=>x.classList.toggle('sel',x.dataset.authrtCd===String(authrtCd)))}
    const protectedAuth=a.authrtCd===SYSTEM_ADMIN_AUTHRT_CD;
    document.getElementById('authDetail').innerHTML=`<div class="card-title">메뉴·기능 권한 <small>${escapeHtml(a.authrtNm)} / ${escapeHtml(a.authrtCd)}</small></div><div style="display:flex;gap:8px;margin-bottom:12px">${hasPermission('auth','mdfcnAuthrtYn')?`<button class="btn" onclick="openAuthModal(CURRENT_AUTH_DATA)">권한명 수정</button>`:''}${hasPermission('auth','delAuthrtYn')&&!protectedAuth?`<button class="btn danger" onclick='deleteAuth(${authActionCode(a.authrtCd)})'>권한 삭제</button>`:''}</div><table class="matrix table-wide-xl"><thead><tr><th>메뉴</th><th>목록</th><th>상세</th><th>등록</th><th>수정</th><th>삭제</th><th>제어</th></tr></thead><tbody>${visibleMenuAuth.map(m=>`<tr data-menu-sn="${m.menuSn}"><td>${escapeHtml(m.menuNm)}</td>${['listAuthrtYn','dtlAuthrtYn','regAuthrtYn','mdfcnAuthrtYn','delAuthrtYn','ctrlAuthrtYn'].map(k=>`<td><input class="perm-check" type="checkbox" data-key="${k}" ${m[k]==='Y'?'checked':''} ${!hasPermission('auth','mdfcnAuthrtYn')||protectedAuth?'disabled':''}></td>`).join('')}</tr>`).join('')}</tbody></table><div class="callout" style="margin-top:14px">상세·등록·수정·삭제·제어 권한을 선택하면 목록 권한이 자동으로 포함됩니다. 시스템 관리자 권한은 보호됩니다.</div>${hasPermission('auth','mdfcnAuthrtYn')&&!protectedAuth?'<div class="modal-actions"><button class="btn primary" onclick="savePermissions()">권한 저장</button></div>':''}`;
    enhanceTables(document.getElementById('authDetail'));
  }catch(e){showToast(e.message,true)}
}
function openAuthModal(authData){
  const a=authData||{},edit=!!a.authrtCd;
  showModal(`<div class="modal-head"><h2>${edit?'권한 수정':'권한 등록'}</h2><button class="modal-close" onclick="closeModal()">×</button></div><form id="authForm"><div class="edit-form"><label>권한코드 *</label><div class="full"><input class="form-control" name="authrtCd" value="${escapeHtml(a.authrtCd||'')}" maxlength="30" pattern="[A-Z][A-Z0-9_]{2,29}" ${edit?'readonly':''} placeholder="예: FACILITY_MANAGER" required><span class="form-help">등록 후 변경할 수 없습니다.</span></div><label>권한명 *</label><div class="full"><input class="form-control" name="authrtNm" value="${escapeHtml(a.authrtNm||'')}" maxlength="100" required></div><label>권한 설명</label><div class="full"><input class="form-control" name="authrtExpln" value="${escapeHtml(a.authrtExpln||'')}" maxlength="4000"></div></div><input type="hidden" name="useYn" value="Y"><div class="modal-actions"><button type="button" class="btn" onclick="closeModal()">취소</button><button class="btn primary" type="submit">저장</button></div></form>`);
  document.getElementById('authForm').addEventListener('submit',saveAuth)
}
async function saveAuth(e){e.preventDefault();const authrtCd=e.target.querySelector('[name=authrtCd]').value.trim().toUpperCase(),edit=!!CURRENT_AUTH_DATA&&CURRENT_AUTH_DATA.authrtCd===authrtCd;try{const data=await api(edit?'/auth/update.ajax':'/auth/insert.ajax',{method:'POST',body:new URLSearchParams(new FormData(e.target))});closeModal();showToast(edit?'권한을 수정했습니다.':'권한을 등록했습니다.');await loadAuths(edit?authrtCd:data.authrtCd)}catch(error){showToast(error.message,true)}}
async function deleteAuth(authrtCd){if(!confirm('선택한 권한을 삭제하시겠습니까?\n기존 계정신청 이력 때문에 권한 행은 미사용 처리됩니다.'))return;try{await api('/auth/delete.ajax',{method:'POST',body:new URLSearchParams({authrtCd})});CURRENT_AUTH_CD=null;CURRENT_AUTH_DATA=null;showToast('권한을 삭제했습니다.');await loadAuths()}catch(e){showToast(e.message,true)}}
async function savePermissions(){const rows=[...document.querySelectorAll('#authDetail tbody tr')];const menuAuthList=rows.map(row=>{const item={menuSn:Number(row.dataset.menuSn)};row.querySelectorAll('input[data-key]').forEach(input=>item[input.dataset.key]=input.checked?'Y':'N');return item});try{await api('/auth/savePermissions.ajax',{method:'POST',headers:{'Content-Type':'application/json;charset=UTF-8'},body:JSON.stringify({authrtCd:CURRENT_AUTH_CD,menuAuthList})});showToast('메뉴·기능 권한을 저장했습니다.');await bootstrapPermissions(false);await loadAuthDetail(CURRENT_AUTH_CD)}catch(e){showToast(e.message,true)}}
window.TNMS_PAGE_INIT=async function(){renderPage('auth',auth());await loadAuths();};
