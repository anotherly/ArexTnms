function applicationsScreen(){
  return layout('applications',`<div class="card">
    <div class="filter">
      <select id="applicationStatusFilter" class="input">
        <option value="승인대기" selected>승인 대기</option>
        <option value="">전체 상태</option>
        <option value="승인완료">승인 완료</option>
        <option value="반려">반려</option>
      </select>
      <input id="applicationKeyword" class="input wide" placeholder="신청자명 / 아이디 / 소속">
      <div class="spacer"></div>
      <button class="btn primary" onclick="loadApplications()">검색</button>
    </div>
    <div class="card-title">계정 신청 목록 <small id="applicationCount">조회 중</small></div>
    <table>
      <thead><tr><th>신청번호</th><th>신청자</th><th>소속</th><th>요청권한</th><th>신청사유</th><th>신청일시</th><th>상태</th><th>처리</th></tr></thead>
      <tbody id="applicationRows"><tr><td class="empty-row" colspan="8">조회 중입니다.</td></tr></tbody>
    </table>
  </div>`);
}

function applicationAffiliation(application){
  if(application.userSeNm==='내부'){
    const parts=[];
    if(application.ogdpBzentyNm)parts.push(application.ogdpBzentyNm);
    if(application.deptNm)parts.push(application.deptNm);
    return parts.length?parts.join(' / '):'-';
  }
  return application.ogdpBzentyNm||application.deptNm||'-';
}

function applicationStatusChip(status){
  if(status==='승인대기')return chip(escapeHtml(status),'warn');
  if(status==='반려')return chip(escapeHtml(status),'bad');
  return chip(escapeHtml(status||'-'));
}

function applicationProcessButtons(application){
  if(application.aplySttsNm==='승인대기'&&hasPermission('applications','mdfcnAuthrtYn')){
    return `<button class="btn sm primary" onclick="approveApplication(${application.aplySn})">승인</button> <button class="btn sm danger" onclick="openRejectApplicationModal(${application.aplySn})">반려</button>`;
  }
  return hasPermission('applications','dtlAuthrtYn')?`<button class="btn sm" onclick="openApplicationDetail(${application.aplySn})">상세</button>`:'-';
}

async function loadApplications(){
  try{
    const params=new URLSearchParams();
    const status=document.getElementById('applicationStatusFilter');
    const keyword=document.getElementById('applicationKeyword');
    if(status&&status.value)params.set('aplySttsNm',status.value);
    if(keyword&&keyword.value.trim())params.set('searchKeyword',keyword.value.trim());
    const list=await api('/user/applications/list.ajax?'+params.toString());
    const count=document.getElementById('applicationCount');
    const rows=document.getElementById('applicationRows');
    if(count)count.textContent=`총 ${list.length}건`;
    if(!rows)return;
    rows.innerHTML=list.length?list.map(application=>`<tr>
      <td>${escapeHtml(application.aplyNo)}</td>
      <td>${escapeHtml(application.userNm)}<br><small>${escapeHtml(application.userId)}</small></td>
      <td>${escapeHtml(applicationAffiliation(application))}</td>
      <td>${escapeHtml(application.dmndAuthrtNm||'-')}</td>
      <td>${escapeHtml(application.aplyRsn||'-')}</td>
      <td>${formatDate(application.aplyDt)}</td>
      <td>${applicationStatusChip(application.aplySttsNm)}</td>
      <td>${applicationProcessButtons(application)}</td>
    </tr>`).join(''):'<tr><td class="empty-row" colspan="8">조회 결과가 없습니다.</td></tr>';
  }catch(error){
    const rows=document.getElementById('applicationRows');
    if(rows)rows.innerHTML='<tr><td class="empty-row" colspan="8">계정 신청 목록을 불러오지 못했습니다.</td></tr>';
    showToast(error.message,true);
  }
}

async function openApplicationDetail(aplySn){
  try{
    const application=await api('/user/applications/detail.ajax?aplySn='+encodeURIComponent(aplySn));
    const pending=application.aplySttsNm==='승인대기';
    const actionButtons=pending&&hasPermission('applications','mdfcnAuthrtYn')
      ? `<button type="button" class="btn danger" onclick="closeModal();openRejectApplicationModal(${application.aplySn})">반려</button><button type="button" class="btn primary" onclick="closeModal();approveApplication(${application.aplySn})">승인</button>`
      : '';
    showModal(`<div class="modal-head"><h2>계정 신청 상세</h2><button class="modal-close" onclick="closeModal()">×</button></div>
      <div class="edit-form">
        <label>신청번호</label><div>${escapeHtml(application.aplyNo||'-')}</div>
        <label>신청상태</label><div>${applicationStatusChip(application.aplySttsNm)}</div>
        <label>사용자 아이디</label><div>${escapeHtml(application.userId||'-')}</div>
        <label>이름</label><div>${escapeHtml(application.userNm||'-')}</div>
        <label>소속구분</label><div>${escapeHtml(application.userSeNm||'-')}</div>
        <label>소속</label><div>${escapeHtml(applicationAffiliation(application))}</div>
        <label>핸드폰번호</label><div>${escapeHtml(application.mobileNo||'-')}</div>
        <label>전화번호</label><div>${escapeHtml(application.telno||'-')}</div>
        <label>이메일</label><div>${escapeHtml(application.emlAddr||'-')}</div>
        <label>요청권한</label><div>${escapeHtml(application.dmndAuthrtNm||'-')}</div>
        <label>신청사유</label><div>${escapeHtml(application.aplyRsn||'-')}</div>
        <label>신청일시</label><div>${formatDate(application.aplyDt)}</div>
        ${application.aplySttsNm==='승인완료'?`<label>승인일시</label><div>${formatDate(application.aprvDt)}</div>`:''}
        ${application.aplySttsNm==='반려'?`<label>반려사유</label><div>${escapeHtml(application.rfslRsn||'-')}</div>`:''}
      </div>
      <div class="modal-actions"><button type="button" class="btn" onclick="closeModal()">닫기</button>${actionButtons}</div>`);
  }catch(error){showToast(error.message,true)}
}

async function approveApplication(aplySn){
  if(!confirm('선택한 계정 신청을 승인하시겠습니까?\n승인 시 사용자 계정이 생성되고 요청 권한이 부여됩니다.'))return;
  try{
    await api('/user/applications/approve.ajax',{method:'POST',body:new URLSearchParams({aplySn:String(aplySn)})});
    showToast('계정 신청을 승인했습니다.');
    await loadApplications();
  }catch(error){showToast(error.message,true)}
}

function openRejectApplicationModal(aplySn){
  showModal(`<div class="modal-head"><h2>계정 신청 반려</h2><button class="modal-close" onclick="closeModal()">×</button></div>
    <form id="applicationRejectForm">
      <div class="edit-form">
        <label for="rfslRsn">반려 사유 *</label>
        <div><textarea id="rfslRsn" name="rfslRsn" class="form-control" maxlength="4000" rows="6" style="height:120px;padding:10px;resize:vertical" placeholder="반려 사유를 입력해 주세요." required></textarea></div>
      </div>
      <div class="modal-actions"><button type="button" class="btn" onclick="closeModal()">취소</button><button type="submit" class="btn danger">반려</button></div>
    </form>`);
  document.getElementById('applicationRejectForm').addEventListener('submit',async function(event){
    event.preventDefault();
    const reason=document.getElementById('rfslRsn').value.trim();
    if(!reason){showToast('반려 사유를 입력해 주세요.',true);return}
    try{
      await api('/user/applications/reject.ajax',{method:'POST',body:new URLSearchParams({aplySn:String(aplySn),rfslRsn:reason})});
      closeModal();
      showToast('계정 신청을 반려했습니다.');
      await loadApplications();
    }catch(error){showToast(error.message,true)}
  });
}

window.TNMS_PAGE_INIT=async function(){
  renderPage('applications',applicationsScreen());
  const keyword=document.getElementById('applicationKeyword');
  if(keyword)keyword.addEventListener('keydown',function(event){if(event.key==='Enter')loadApplications()});
  await loadApplications();
};
