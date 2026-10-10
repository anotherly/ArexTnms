(function(){
  function today(offset){const d=new Date();d.setDate(d.getDate()+(offset||0));return d.toISOString().slice(0,10)}
  function n(v){return Number(v||0)}
  function gradeName(v){return {EMERGENCY:'긴급',HIGH:'높음',LOW:'낮음',WARNING:'경고',INFO:'정보',CLEAR:'해제',CRITICAL:'긴급',CAUTION:'경고'}[v]||v||'-'}
  function statusName(v){return {UNCONFIRMED:'미확인',TEMPORARY:'임시조치',COMPLETED:'완료조치'}[v]||v||'-'}
  function gradeCell(x){return `<span class="mgmt-grade grade-${String(x||'').toLowerCase()}">${escapeHtml(gradeName(x))}</span>`}
  function summaryTable(rows,labelKey,labelName){return `<table class="report-mini-table"><thead><tr><th>${labelName}</th><th>긴급</th><th>높음</th><th>낮음</th><th>경고</th><th>정보</th><th>합계</th></tr></thead><tbody>${(rows||[]).map(x=>`<tr><td>${escapeHtml(x[labelKey]||'-')}</td><td>${n(x.emergencyNocs)}</td><td>${n(x.highNocs)}</td><td>${n(x.lowNocs)}</td><td>${n(x.warningNocs)}</td><td>${n(x.infoNocs)}</td><td><b>${n(x.totalNocs)}</b></td></tr>`).join('')||'<tr><td colspan="7" class="empty">조회 결과가 없습니다.</td></tr>'}</tbody></table>`}
  function lineSvg(rows){
    if(!rows||!rows.length)return '<div class="report-empty-chart">조회 기간 장애 데이터가 없습니다.</div>';
    const w=560,h=160,p=24,max=Math.max(1,...rows.map(x=>n(x.totalNocs))),step=(w-p*2)/Math.max(1,rows.length-1);
    const pts=rows.map((x,i)=>`${p+i*step},${h-p-(n(x.totalNocs)/max)*(h-p*2)}`).join(' ');
    const labels=rows.map((x,i)=>i===0||i===rows.length-1||i%Math.max(1,Math.floor(rows.length/5))===0?`<text x="${p+i*step}" y="${h-5}" text-anchor="middle">${escapeHtml(String(x.reportDate||'').slice(5))}</text>`:'').join('');
    return `<svg class="report-line-svg" viewBox="0 0 ${w} ${h}" preserveAspectRatio="none"><line x1="${p}" y1="${h-p}" x2="${w-p}" y2="${h-p}"/><polyline points="${pts}"/><g>${labels}</g></svg>`;
  }
  function params(){const p=new URLSearchParams({startDate:document.getElementById('reportStart').value,endDate:document.getElementById('reportEnd').value});const s=document.getElementById('reportSystem').value;if(s)p.set('linkSysCd',s);return p}
  window.exportReportExcel=function(){location.href=CONTEXT_PATH+'/report/fault-performance/excel.do?'+params().toString()}
  window.loadReport=async function(){
    try{
      const d=await api('/report/fault-performance/data.ajax?'+params().toString()),s=d.summary||{};
      const daily=d.daily||[],systems=d.systems||[],stations=d.stations||[],details=d.details||[];
      document.getElementById('reportResult').innerHTML=`
        <div class="report-kpis">
          <div><span>발생 장애</span><b>${n(s.totalNocs)}</b></div><div><span>심각 그룹</span><b class="c-red">${n(s.criticalNocs)}</b></div>
          <div><span>서비스 장애</span><b>${n(s.serviceNocs)}</b></div><div><span>조치 완료율</span><b class="c-green">${Number(s.completeRate||0).toFixed(1)}%</b></div>
        </div>
        <div class="report-top-grid">
          <section class="card report-block"><div class="report-block-head"><b>일별 장애현황</b><span>${escapeHtml(d.condition.startDate)} ~ ${escapeHtml(d.condition.endDate)}</span></div>
            <div class="report-daily-wrap">${summaryTable(daily,'reportDate','일자')}<div class="report-line">${lineSvg(daily)}</div></div></section>
        </div>
        <div class="report-two-grid">
          <section class="card report-block"><div class="report-block-head"><b>시스템별 장애현황</b></div>${summaryTable(systems,'linkSysNm','시스템')}</section>
          <section class="card report-block"><div class="report-block-head"><b>역사별 장애현황</b></div>${summaryTable(stations,'stnNm','역사')}</section>
        </div>
        <section class="card report-block"><div class="report-block-head"><b>장애 상세</b><span>최대 200건</span></div>
          <table class="report-detail"><thead><tr><th>발생일시</th><th>시스템</th><th>역사</th><th>장비명</th><th>등급</th><th>장애내용</th><th>처리상태</th><th>종료일시</th></tr></thead><tbody>
          ${details.map(x=>`<tr><td>${escapeHtml(x.ocrnDt||'-')}</td><td>${escapeHtml(x.linkSysNm||'-')}</td><td>${escapeHtml(x.stnNm||'-')}</td><td>${escapeHtml(x.eqpmntNm||'-')}</td><td>${gradeCell(x.gradeCd)}</td><td class="left">${escapeHtml(x.faultCn||'-')}</td><td>${escapeHtml(statusName(x.prcsSttsCd))}</td><td>${escapeHtml(x.endDt||'-')}</td></tr>`).join('')||'<tr><td colspan="8" class="empty">조회 결과가 없습니다.</td></tr>'}
          </tbody></table></section>`;
      enhanceTables(document.getElementById('reportResult'));
    }catch(e){showToast(e.message,true)}
  };
  window.TNMS_PAGE_INIT=async function(){
    renderPage('reports',`<div class="card report-search"><div class="field"><label>조회기간</label><input id="reportStart" type="date" value="${today(-6)}"></div><span>~</span><div class="field"><label>&nbsp;</label><input id="reportEnd" type="date" value="${today(0)}"></div><div class="field"><label>시스템</label><select id="reportSystem"><option value="">전체 시스템</option><option value="VMS">영상감시</option><option value="PBX">전화교환</option><option value="SCADA_SEC">SCADA</option><option value="EMS_PIDS">행선안내</option><option value="EMS_TX">전송</option></select></div><button class="btn primary" onclick="loadReport()">조회</button><button class="btn" onclick="exportReportExcel()">Excel</button></div><div id="reportResult"></div>`);
    await loadReport();
  };
})();
