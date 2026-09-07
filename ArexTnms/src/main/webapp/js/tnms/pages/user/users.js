function usersScreen(){
  const actions=permissionButton('users','regAuthrtYn','사용자 등록','primary','openUserModal()');
  return layout('users',`<div class="card"><div class="filter"><select id="userAuthFilter" class="input"><option value="">전체 권한</option></select><select id="userStatusFilter" class="input"><option value="">전체 상태</option><option>정상</option><option>잠금</option><option>중지</option></select><input id="userKeyword" class="input wide" placeholder="아이디 / 사용자명 / 소속"><div class="spacer"></div><button class="btn primary" onclick="loadUsers()">검색</button></div><div class="card-title">사용자 목록 <small id="userCount">조회 중</small></div><table><thead><tr><th>사용자 아이디</th><th>사용자명</th><th>소속</th><th>부서</th><th>권한</th><th>전화번호</th><th>상태</th><th>최근 로그인</th><th>관리</th></tr></thead><tbody id="userRows"><tr><td class="empty-row" colspan="9">조회 중입니다.</td></tr></tbody></table></div>`,actions)
};

async function loadAuthOptions(){
  const list=await api('/auth/options.ajax');
  const select=document.getElementById('userAuthFilter');
  if(select){const current=select.value;select.innerHTML='<option value="">전체 권한</option>'+list.map(a=>`<option value="${a.authrtSn}">${escapeHtml(a.authrtNm)}</option>`).join('');select.value=current}
  return list;
}
async function loadUsers(){
  try{
    const params=new URLSearchParams();
    const auth=document.getElementById('userAuthFilter'),status=document.getElementById('userStatusFilter'),keyword=document.getElementById('userKeyword');
    if(auth&&auth.value)params.set('authrtSn',auth.value);if(status&&status.value)params.set('userSttsNm',status.value);if(keyword&&keyword.value.trim())params.set('searchKeyword',keyword.value.trim());
    const list=await api('/user/list.ajax?'+params.toString());
    document.getElementById('userCount').textContent=`총 ${list.length}건`;
    document.getElementById('userRows').innerHTML=list.length?list.map(u=>`<tr><td><b>${escapeHtml(u.userId)}</b></td><td>${escapeHtml(u.userNm)}</td><td>${escapeHtml(u.ogdpBzentyNm||'-')}</td><td>${escapeHtml(u.deptNm||'-')}</td><td>${escapeHtml(u.authrtNm||'-')}</td><td>${escapeHtml(u.telno||'-')}</td><td>${chip(escapeHtml(u.userSttsNm),u.userSttsNm==='잠금'?'bad':'')}</td><td>${formatDate(u.lastLgnDt)}</td><td>${hasPermission('users','mdfcnAuthrtYn')?`<button class="btn sm" onclick="openUserModal(${u.userSn})">수정</button> ${u.userSttsNm==='잠금'?`<button class="btn sm" onclick="unlockUser(${u.userSn})">잠금해제</button>`:''}`:''}</td></tr>`).join(''):'<tr><td class="empty-row" colspan="9">조회 결과가 없습니다.</td></tr>';
  }catch(e){showToast(e.message,true)}
}
async function openUserModal(userSn){
  try{
    USER_ID_CHECKED=false;
    const [authList,user]=await Promise.all([loadAuthOptions(),userSn?api('/user/detail.ajax?userSn='+userSn):Promise.resolve({useYn:'Y',userSttsNm:'정상'})]);
    const edit=!!userSn;
    showModal(`<div class="modal-head"><h2>${edit?'사용자 수정':'사용자 등록'}</h2><button class="modal-close" onclick="closeModal()">×</button></div><form id="userForm"><input type="hidden" name="userSn" value="${user.userSn||''}"><div class="edit-form"><label>사용자 아이디 *</label><div><input class="form-control" name="userId" id="modalUserId" value="${escapeHtml(user.userId||'')}" ${edit?'readonly':''} required>${edit?'':'<button type="button" class="btn sm" style="margin-top:6px" onclick="checkUserId()">중복 확인</button><span id="idCheckResult" class="form-help"></span>'}</div><label>사용자명 *</label><div><input class="form-control" name="userNm" value="${escapeHtml(user.userNm||'')}" required></div><label>소속업체</label><div><input class="form-control" name="ogdpBzentyNm" value="${escapeHtml(user.ogdpBzentyNm||'')}"></div><label>부서</label><div><input class="form-control" name="deptNm" value="${escapeHtml(user.deptNm||'')}"></div><label>전화번호</label><div><input class="form-control" name="telno" value="${escapeHtml(user.telno||'')}" placeholder="하이픈 없이 숫자만"></div><label>이메일</label><div><input class="form-control" name="emlAddr" type="email" value="${escapeHtml(user.emlAddr||'')}"></div><label>권한 *</label><div><select class="form-control" name="authrtSn" required>${authList.map(a=>`<option value="${a.authrtSn}" ${String(a.authrtSn)===String(user.authrtSn)?'selected':''}>${escapeHtml(a.authrtNm)}</option>`).join('')}</select></div><label>계정 상태</label><div><select class="form-control" name="userSttsNm">${['정상','잠금','중지'].map(s=>`<option ${s===user.userSttsNm?'selected':''}>${s}</option>`).join('')}</select><input type="hidden" name="useYn" value="${user.useYn||'Y'}"></div><label>${edit?'새 비밀번호':'초기 비밀번호 *'}</label><div><input class="form-control" name="password" type="password" ${edit?'':'required'}><span class="form-help">영문·숫자·특수문자 포함 8~20자</span></div><label>비밀번호 확인</label><div><input class="form-control" name="passwordConfirm" type="password" ${edit?'':'required'}></div></div><div class="modal-actions">${edit&&hasPermission('users','delAuthrtYn')?`<button type="button" class="btn danger" onclick="deleteUser(${userSn})">삭제</button>`:''}<button type="button" class="btn" onclick="closeModal()">취소</button><button type="submit" class="btn primary">저장</button></div></form>`);
    document.getElementById('userForm').addEventListener('submit',saveUser);
    if(!edit)document.getElementById('modalUserId').addEventListener('input',()=>{USER_ID_CHECKED=false;const result=document.getElementById('idCheckResult');if(result)result.textContent=''});
  }catch(e){showToast(e.message,true)}
}
let USER_ID_CHECKED=false;
async function checkUserId(){try{const id=document.getElementById('modalUserId').value.trim();const data=await api('/user/idCheck.ajax?userId='+encodeURIComponent(id));USER_ID_CHECKED=data.available;document.getElementById('idCheckResult').textContent=data.available?'사용 가능한 아이디입니다.':'이미 사용 중인 아이디입니다.'}catch(e){showToast(e.message,true)}}
async function saveUser(e){e.preventDefault();const form=e.target,edit=!!form.querySelector('[name=userSn]').value;if(!edit&&!USER_ID_CHECKED){showToast('아이디 중복 확인을 해주세요.',true);return}try{await api(edit?'/user/update.ajax':'/user/insert.ajax',{method:'POST',body:new URLSearchParams(new FormData(form))});closeModal();showToast(edit?'사용자 정보를 수정했습니다.':'사용자를 등록했습니다.');await loadUsers()}catch(error){showToast(error.message,true)}}
async function deleteUser(userSn){if(!confirm('선택한 사용자를 삭제하시겠습니까?'))return;try{await api('/user/delete.ajax',{method:'POST',body:new URLSearchParams({userSn})});closeModal();showToast('사용자를 삭제했습니다.');await loadUsers()}catch(e){showToast(e.message,true)}}
async function unlockUser(userSn){if(!confirm('계정 잠금을 해제하시겠습니까?'))return;try{await api('/user/unlock.ajax',{method:'POST',body:new URLSearchParams({userSn})});showToast('계정 잠금을 해제했습니다.');await loadUsers()}catch(e){showToast(e.message,true)}}

window.TNMS_PAGE_INIT = async function () {
  renderPage('users', usersScreen());
  await loadAuthOptions();
  await loadUsers();
};
