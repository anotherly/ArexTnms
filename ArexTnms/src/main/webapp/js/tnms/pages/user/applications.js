const APPLICATION_STATUS_LABELS={WAITING:'승인대기',APPROVED:'승인완료',REJECTED:'반려'};
const APPLICATION_USER_TYPE_LABELS={INTERNAL:'내부',EXTERNAL:'외부'};
window.APPLICATION_AUTH_LIST=window.APPLICATION_AUTH_LIST||[];

function applicationsScreen(){
  return `<section class="planner-card account-section application-section">
    <div class="planner-card-head"><div><h3>계정 신청 목록</h3><p>신규 계정 신청을 확인하고 권한을 지정하여 승인 또는 반려합니다.</p></div><small id="applicationCount">조회 중</small></div>
    <div class="planner-filter-row account-filter"><select id="applicationStatusFilter" class="input"><option value="">전체 상태</option><option value="WAITING" selected>승인 대기</option><option value="APPROVED">승인 완료</option><option value="REJECTED">반려</option></select><input id="applicationKeyword" class="input wide" placeholder="사용자명 / 아이디 / 소속"><button class="btn primary" type="button" onclick="loadApplications()">검색</button></div>
    <div class="table-scroll"><table class="planner-table account-table"><thead><tr><th>No.</th><th>상태</th><th>사용자 아이디</th><th>사용자명</th><th>소속</th><th>부서</th><th>전화번호</th><th>이메일</th><th>신청일자</th><th>권한</th><th>처리</th></tr></thead><tbody id="applicationRows"><tr><td colspan="11" class="empty-row">조회 중입니다.</td></tr></tbody></table></div>
  </section>`;
}
function applicationAffiliation(a){
  if(a.userSeCd==='INTERNAL') return a.ogdpBzentyNm||'공항철도';
  return a.ogdpBzentyNm||'-';
}
function applicationStatusChip(code){
  const label=APPLICATION_STATUS_LABELS[code]||code||'-';
  if(code==='WAITING')return `<span class="planner-state waiting">${escapeHtml(label)}</span>`;
  if(code==='REJECTED')return `<span class="planner-state rejected">${escapeHtml(label)}</span>`;
  return `<span class="planner-state approved">${escapeHtml(label)}</span>`;
}
function applicationActionNo(aplyNo){return JSON.stringify(String(aplyNo||''));}
function applicationAuthSelect(a){
  const list=(window.APPLICATION_AUTH_LIST||[]);
  if(a.aplySttsCd!=='WAITING')return escapeHtml(a.dmndAuthrtNm||a.dmndAuthrtCd||'-');
  const options=list.length?list:[{authrtCd:a.dmndAuthrtCd,authrtNm:a.dmndAuthrtNm||a.dmndAuthrtCd}];
  return `<select class="input application-auth-select" id="applicationAuth_${escapeHtml(a.aplyNo)}">${options.map(x=>`<option value="${escapeHtml(x.authrtCd)}" ${String(x.authrtCd)===String(a.dmndAuthrtCd)?'selected':''}>${escapeHtml(x.authrtNm)}</option>`).join('')}</select>`;
}
function applicationProcessButtons(a){
  const no=applicationActionNo(a.aplyNo);
  if(a.aplySttsCd==='WAITING'&&hasPermission('applications','mdfcnAuthrtYn')){
    return `<div class="row-actions"><button class="btn sm danger-outline" type="button" onclick='openRejectApplicationModal(${no})'>반려</button><button class="btn sm primary" type="button" onclick='approveApplication(${no})'>승인</button></div>`;
  }
  return hasPermission('applications','dtlAuthrtYn')?`<button class="btn sm" type="button" onclick='openApplicationDetail(${no})'>상세</button>`:'-';
}
async function loadApplications(){
  try{
    const params=new URLSearchParams(),status=document.getElementById('applicationStatusFilter'),keyword=document.getElementById('applicationKeyword');
    if(status&&status.value)params.set('aplySttsCd',status.value);
    if(keyword&&keyword.value.trim())params.set('searchKeyword',keyword.value.trim());
    const list=await api('/user/applications/list.ajax?'+params.toString());
    const count=document.getElementById('applicationCount'),rows=document.getElementById('applicationRows');
    if(count)count.textContent=`총 ${list.length}건`;
    if(!rows)return;
    rows.innerHTML=list.length?list.map((a,index)=>`<tr><td>${index+1}</td><td>${applicationStatusChip(a.aplySttsCd)}</td><td><button class="table-link" onclick='openApplicationDetail(${applicationActionNo(a.aplyNo)})'>${escapeHtml(a.userId)}</button></td><td>${escapeHtml(a.userNm)}</td><td>${escapeHtml(applicationAffiliation(a))}</td><td>${escapeHtml(a.deptNm||'-')}</td><td>${escapeHtml(a.mobileNo||a.telno||'-')}</td><td>${escapeHtml(a.emlAddr||'-')}</td><td>${formatDate(a.aplyDt)}</td><td>${applicationAuthSelect(a)}</td><td>${applicationProcessButtons(a)}</td></tr>`).join(''):'<tr><td class="empty-row" colspan="11">조회 결과가 없습니다.</td></tr>';
  }catch(error){const rows=document.getElementById('applicationRows');if(rows)rows.innerHTML='<tr><td class="empty-row" colspan="11">계정 신청 목록을 불러오지 못했습니다.</td></tr>';showToast(error.message,true);}
}
async function openApplicationDetail(aplyNo){
  try{
    const a=await api('/user/applications/detail.ajax?aplyNo='+encodeURIComponent(aplyNo));
    const pending=a.aplySttsCd==='WAITING';
    const no=applicationActionNo(a.aplyNo);
    const actions=pending&&hasPermission('applications','mdfcnAuthrtYn')?`<button type="button" class="btn danger-outline" onclick='closeModal();openRejectApplicationModal(${no})'>반려</button><button type="button" class="btn primary" onclick='closeModal();approveApplication(${no})'>승인</button>`:'';
    showModal(`<div class="modal-head"><div><h2>계정 신청 상세</h2><p>${escapeHtml(a.aplyNo||'')}</p></div><button class="modal-close" onclick="closeModal()">×</button></div><div class="planner-detail-grid"><label>신청상태</label><div>${applicationStatusChip(a.aplySttsCd)}</div><label>사용자 아이디</label><div>${escapeHtml(a.userId||'-')}</div><label>사용자명</label><div>${escapeHtml(a.userNm||'-')}</div><label>사용자 구분</label><div>${escapeHtml(APPLICATION_USER_TYPE_LABELS[a.userSeCd]||a.userSeCd||'-')}</div><label>소속 / 부서</label><div>${escapeHtml(applicationAffiliation(a))} / ${escapeHtml(a.deptNm||'-')}</div><label>휴대전화</label><div>${escapeHtml(a.mobileNo||'-')}</div><label>전화번호</label><div>${escapeHtml(a.telno||'-')}</div><label>이메일</label><div>${escapeHtml(a.emlAddr||'-')}</div><label>요청권한</label><div>${escapeHtml(a.dmndAuthrtNm||a.dmndAuthrtCd||'-')}</div><label>신청일시</label><div>${formatDate(a.aplyDt)}</div><label>신청사유</label><div>${escapeHtml(a.aplyRsn||'-')}</div>${a.aplySttsCd==='APPROVED'?`<label>승인일시</label><div>${formatDate(a.aprvDt)}</div>`:''}${a.aplySttsCd==='REJECTED'?`<label>반려사유</label><div>${escapeHtml(a.rfslRsn||'-')}</div>`:''}</div><div class="modal-actions"><button type="button" class="btn" onclick="closeModal()">닫기</button>${actions}</div>`);
  }catch(error){showToast(error.message,true);}
}
async function approveApplication(aplyNo){
  const select=document.getElementById('applicationAuth_'+aplyNo);
  const authrtCd=select?select.value:'';
  const authName=select&&select.selectedOptions.length?select.selectedOptions[0].textContent:'신청 권한';
  if(!confirm(`선택한 계정 신청을 승인하시겠습니까?\n승인 권한: ${authName}\n승인 즉시 사용자 계정이 생성됩니다.`))return;
  try{
    const body=new URLSearchParams({aplyNo:String(aplyNo)});if(authrtCd)body.set('authrtCd',authrtCd);
    await api('/user/applications/approve.ajax',{method:'POST',body:body});showToast('계정 신청을 승인했습니다.');await Promise.all([loadApplications(),typeof loadUsers==='function'?loadUsers():Promise.resolve()]);
  }catch(error){showToast(error.message,true);}
}
function openRejectApplicationModal(aplyNo){
  showModal(`<div class="modal-head"><div><h2>계정 신청 반려</h2><p>반려 사유는 신청 이력에 저장됩니다.</p></div><button class="modal-close" onclick="closeModal()">×</button></div><form id="applicationRejectForm"><div class="planner-form-stack"><label>반려 사유 *</label><textarea id="rfslRsn" name="rfslRsn" class="form-control textarea" maxlength="4000" rows="6" placeholder="반려 사유를 입력해 주세요." required></textarea></div><div class="modal-actions"><button type="button" class="btn" onclick="closeModal()">취소</button><button type="submit" class="btn danger">반려</button></div></form>`);
  document.getElementById('applicationRejectForm').addEventListener('submit',async function(event){event.preventDefault();const reason=document.getElementById('rfslRsn').value.trim();if(!reason){showToast('반려 사유를 입력해 주세요.',true);return;}try{await api('/user/applications/reject.ajax',{method:'POST',body:new URLSearchParams({aplyNo:String(aplyNo),rfslRsn:reason})});closeModal();showToast('계정 신청을 반려했습니다.');await loadApplications();}catch(error){showToast(error.message,true);}});
}
