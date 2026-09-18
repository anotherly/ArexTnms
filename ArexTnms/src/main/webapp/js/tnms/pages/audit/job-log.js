(function(){
  'use strict';
  let JOB_LOG_DATA=[];
  let JOB_LOG_PAGE=1;
  let JOB_LOG_PAGE_SIZE=20;
  function today(offset){const d=new Date();d.setDate(d.getDate()+(offset||0));return d.toISOString().slice(0,10);}
  function jobLabel(code){return {REG:'등록',MDFCN:'수정',DEL:'삭제',LIST:'조회',LOGIN:'로그인',CTRL:'제어'}[code]||code||'-';}
  function resultChip(code){return `<span class="planner-state ${code==='SUCCESS'?'approved':'rejected'}">${code==='SUCCESS'?'성공':'실패'}</span>`;}
  function screen(){
    const menuNames=['사용자 계정 설정','계정 신청 현황','권한 관리','공통코드·UI 설정','설비관리','장애관리','성능관리'];
    return layout('logs',`<div class="audit-planner-page"><section class="planner-card audit-section"><div class="planner-card-head"><div><h3>작업로그 목록</h3><p>사용자의 로그인 세션과 웹 화면 작업 이력을 조회합니다.</p></div><small id="jobLogCount">조회 중</small></div><div class="planner-filter-row audit-filter"><div class="date-range"><input id="logStart" class="input" type="date" value="${today(-30)}"><span>~</span><input id="logEnd" class="input" type="date" value="${today(0)}"></div><select id="logMenu" class="input"><option value="">전체 메뉴</option>${menuNames.map(x=>`<option value="${escapeHtml(x)}">${escapeHtml(x)}</option>`).join('')}</select><select id="logJob" class="input"><option value="">전체 작업</option><option value="LIST">조회</option><option value="REG">등록</option><option value="MDFCN">수정</option><option value="DEL">삭제</option><option value="LOGIN">로그인</option><option value="CTRL">제어</option></select><input id="logKeyword" class="input wide" placeholder="사용자명 / ID / IP / 대상"><button class="btn primary" onclick="loadJobLogs()">검색</button><button class="btn excel" onclick="exportJobLogs()">Excel</button></div><div class="table-scroll"><table class="planner-table audit-table"><thead><tr><th>No.</th><th>로그일련번호</th><th>사용자</th><th>접속IP</th><th>메뉴</th><th>작업구분</th><th>대상</th><th>로그인일시</th><th>작업일시</th><th>결과</th><th>상세</th></tr></thead><tbody id="jobLogRows"><tr><td colspan="11" class="empty-row">조회 중입니다.</td></tr></tbody></table></div><div id="jobLogPager" class="planner-pager account-pager"></div></section></div>`);
  }
  function renderJobLogPager(){
    const pager=document.getElementById('jobLogPager');if(!pager)return;const pages=Math.max(1,Math.ceil(JOB_LOG_DATA.length/JOB_LOG_PAGE_SIZE));JOB_LOG_PAGE=Math.min(JOB_LOG_PAGE,pages);if(pages<=1){pager.innerHTML='';return;}let html=`<button ${JOB_LOG_PAGE===1?'disabled':''} onclick="changeJobLogPage(${JOB_LOG_PAGE-1})">‹</button>`;const start=Math.max(1,JOB_LOG_PAGE-2),end=Math.min(pages,start+4);for(let i=start;i<=end;i++)html+=`<button class="${i===JOB_LOG_PAGE?'on':''}" onclick="changeJobLogPage(${i})">${i}</button>`;html+=`<button ${JOB_LOG_PAGE===pages?'disabled':''} onclick="changeJobLogPage(${JOB_LOG_PAGE+1})">›</button>`;pager.innerHTML=html;
  }
  function renderJobLogs(){
    const rows=document.getElementById('jobLogRows');if(!rows)return;const start=(JOB_LOG_PAGE-1)*JOB_LOG_PAGE_SIZE,list=JOB_LOG_DATA.slice(start,start+JOB_LOG_PAGE_SIZE);rows.innerHTML=list.length?list.map((x,index)=>`<tr><td>${start+index+1}</td><td>LOG-${String(x.jobLogSn).padStart(6,'0')}</td><td>${escapeHtml(x.userNm||x.userId||'-')}<small class="cell-sub">${escapeHtml(x.userId||'')}</small></td><td>${escapeHtml(x.userIpAddr||'-')}</td><td>${escapeHtml(x.cntnMenuNm||'-')}</td><td>${escapeHtml(jobLabel(x.jobSeCd))}</td><td>${escapeHtml(x.trgtKeyVal||'-')}</td><td>${formatDate(x.lgnDt)}</td><td>${formatDate(x.logCrtDt)}</td><td>${resultChip(x.jobRsltCd)}</td><td><button class="btn sm" onclick="openJobLog(${x.jobLogSn})">보기</button></td></tr>`).join(''):'<tr><td colspan="11" class="empty-row">조회 결과가 없습니다.</td></tr>';renderJobLogPager();
  }
  window.changeJobLogPage=function(page){JOB_LOG_PAGE=Math.max(1,page);renderJobLogs();};
  window.loadJobLogs=async function(){
    try{const p=new URLSearchParams();[['startDate','logStart'],['endDate','logEnd'],['cntnMenuNm','logMenu'],['jobSeCd','logJob'],['searchKeyword','logKeyword']].forEach(x=>{const e=document.getElementById(x[1]);if(e&&String(e.value).trim())p.set(x[0],String(e.value).trim());});const list=await api('/audit/job-log/list.ajax?'+p.toString());JOB_LOG_DATA=list||[];JOB_LOG_PAGE=1;JOB_LOG_PAGE_SIZE=getListPageSize();document.getElementById('jobLogCount').textContent='총 '+JOB_LOG_DATA.length+'건';renderJobLogs();}catch(e){showToast(e.message,true);}
  };
  window.openJobLog=async function(sn){
    try{const x=await api('/audit/job-log/detail.ajax?jobLogSn='+encodeURIComponent(sn));showModal(`<div class="modal-head"><div><h2>작업로그 상세</h2><p>LOG-${String(x.jobLogSn).padStart(6,'0')}</p></div><button class="modal-close" onclick="closeModal()">×</button></div><div class="planner-detail-grid"><label>사용자</label><div>${escapeHtml(x.userNm||x.userId||'-')} (${escapeHtml(x.userId||'-')})</div><label>접속 IP</label><div>${escapeHtml(x.userIpAddr||'-')}</div><label>로그인일시</label><div>${formatDate(x.lgnDt)}</div><label>작업일시</label><div>${formatDate(x.logCrtDt)}</div><label>메뉴</label><div>${escapeHtml(x.cntnMenuNm||'-')}</div><label>작업구분</label><div>${escapeHtml(jobLabel(x.jobSeCd))}</div><label>대상</label><div>${escapeHtml(x.trgtKeyVal||'-')}</div><label>결과</label><div>${resultChip(x.jobRsltCd)}</div><label>처리내용</label><div>${escapeHtml(x.logCn||'-')}</div><label>변경 전</label><div>${escapeHtml(x.chgBfrCn||'-')}</div><label>변경 후</label><div>${escapeHtml(x.chgAftrCn||'-')}</div></div><div class="modal-actions"><button class="btn primary" onclick="closeModal()">확인</button></div>`);}catch(e){showToast(e.message,true);}
  };
  window.exportJobLogs=function(){
    if(!JOB_LOG_DATA.length){showToast('엑셀로 내보낼 조회 결과가 없습니다.',true);return;}
    const headers=['No.','로그일련번호','사용자ID','사용자명','접속IP','메뉴','작업구분','대상','로그인일시','작업일시','결과','내용'];
    const rows=JOB_LOG_DATA.map((x,i)=>[i+1,'LOG-'+String(x.jobLogSn).padStart(6,'0'),x.userId||'',x.userNm||'',x.userIpAddr||'',x.cntnMenuNm||'',jobLabel(x.jobSeCd),x.trgtKeyVal||'',x.lgnDt||'',x.logCrtDt||'',x.jobRsltCd||'',String(x.logCn||'').replace(/[\t\r\n]+/g,' ')]);
    const text='\ufeff'+[headers].concat(rows).map(row=>row.map(v=>String(v).replace(/\t/g,' ')).join('\t')).join('\r\n');
    const blob=new Blob([text],{type:'application/vnd.ms-excel;charset=utf-8'}),url=URL.createObjectURL(blob),a=document.createElement('a');a.href=url;a.download='TNMS_작업로그_'+today(0)+'.xls';document.body.appendChild(a);a.click();a.remove();URL.revokeObjectURL(url);
  };
  window.TNMS_PAGE_INIT=async function(){renderPage('logs',screen());const keyword=document.getElementById('logKeyword');if(keyword)keyword.addEventListener('keydown',e=>{if(e.key==='Enter')loadJobLogs();});await window.loadJobLogs();};
}());
