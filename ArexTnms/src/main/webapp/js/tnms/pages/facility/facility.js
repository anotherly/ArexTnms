(function (global) {
  'use strict';

  const PAGE_KEY = (global.TNMS_CONFIG || {}).pageKey || 'systems';
  const CONFIGS = {
    systems:   {linkSysCd:'EMS_TX',   name:'전송설비',             shortName:'전송',   eqpmntSeCd:'TRANSMISSION'},
    equipment: {linkSysCd:'EMS_PIDS', name:'행선안내설비',         shortName:'행선안내', eqpmntSeCd:'PIDS'},
    scada:     {linkSysCd:'SCADA_SEC',name:'SCADA 출입보안설비',   shortName:'SCADA',  eqpmntSeCd:'SCADA'},
    switch:    {linkSysCd:'PBX',      name:'전화교환설비',          shortName:'교환기',  eqpmntSeCd:'PBX'},
    cctv:      {linkSysCd:'VMS',      name:'영상감시설비(CCTV)',   shortName:'CCTV',   eqpmntSeCd:'CCTV'}
  };
  const config = CONFIGS[PAGE_KEY] || CONFIGS.systems;
  let PAGE_SIZE = 20;
  let currentStation = '';
  let currentData = {stations:[], equipments:[], summary:{}, statusCodes:[], lseCandidates:[], equipmentLinks:[], scadaEvents:[], equipmentClassifications:[]};
  let currentPage = 1;
  let pidsArea = 'ALL'; // 분류 미확정 장비를 첫 화면에서 숨기지 않음
  let facilityStatus = '';
  let facilityKeyword = '';

  function n(value) { return Number(value || 0); }
  function safe(value, fallback) { return global.escapeHtml(value == null || value === '' ? (fallback == null ? '-' : fallback) : value); }
  function normalizeStatusCode(code) {
    code = String(code || 'UNKNOWN').toUpperCase();
    if (code === 'WARNING') return 'CAUTION';
    if (code === 'NO_DATA') return 'UNKNOWN';
    return code;
  }
  function statusType(code) {
    code = normalizeStatusCode(code);
    if (code === 'CRITICAL') return 'bad';
    if (code === 'CAUTION') return 'warn';
    if (code === 'OFFLINE' || code === 'UNKNOWN') return 'off';
    return 'normal';
  }
  function codeLabel(code) {
    const normalized = normalizeStatusCode(code);
    const item = (currentData.statusCodes || []).find(x => normalizeStatusCode(x.comCd) === normalized);
    if (item && item.comCdNm) return item.comCdNm;
    return {NORMAL:'정상', CAUTION:'주의', CRITICAL:'장애', OFFLINE:'PING 실패', UNKNOWN:'상태 미확인'}[normalized] || normalized;
  }
  function statusLabel(item) { return (item && item.sttsNm) || codeLabel(item && item.sttsCd); }
  function stationName() {
    if (!currentStation) return '전체 역사';
    const station = (currentData.stations || []).find(x => x.stnCd === currentStation);
    return station ? station.stnNm : currentStation;
  }
  function currentStationData() {
    return (currentData.stations || []).find(x => x.stnCd === currentStation) || null;
  }
  function summaryStatus() {
    const s = currentData.summary || {};
    if (n(s.criticalNocs) > 0) return 'CRITICAL';
    if (n(s.cautionNocs) > 0) return 'CAUTION';
    if (n(s.offlineNocs)>0) return 'OFFLINE';
    if (n(s.unknownNocs)>0) return 'UNKNOWN';
    if (n(s.normalNocs) > 0) return 'NORMAL';
    return 'UNKNOWN';
  }
  function percent(part, total) { return total ? Math.round((part / total) * 1000) / 10 : 0; }
  function avgPing(list) {
    const values = (list || []).filter(x=>x.pingRspnsMs!=null && x.pingRspnsMs!=='').map(x=>Number(x.pingRspnsMs)).filter(x => Number.isFinite(x) && x >= 0);
    if (!values.length) return null;
    return Math.round(values.reduce((a,b) => a+b, 0) / values.length);
  }
  function jsonArg(value) { return JSON.stringify(String(value == null ? '' : value)); }

  function stationNode(station) {
    const unmanned = station.mnlsStnYn === 'Y';
    const type = unmanned ? 'unmanned' : statusType(station.sttsCd);
    const selected = currentStation === station.stnCd ? ' selected' : '';
    const normalized = normalizeStatusCode(station.sttsCd);
    const badge = selected && !unmanned && normalized !== 'NORMAL'
      ? `<em class="station-alert-badge ${type}">${safe(codeLabel(normalized))}</em>` : '';
    const title = station.stnNm + ' · ' + (unmanned ? '무인국사' : codeLabel(station.sttsCd));
    return `<button type="button" class="planner-station ${type}${selected}" title="${safe(title,'')}" onclick='selectFacilityStation(${jsonArg(station.stnCd)})'>${badge}<i></i><span>${safe(station.stnNm)}</span></button>`;
  }
  function stationRail() {
    const stations = currentData.stations || [];
    const main = stations.filter(x => x.mnlsStnYn !== 'Y');
    const unmanned = stations.filter(x => x.mnlsStnYn === 'Y');
    return `<section class="planner-card station-status-card">
      <div class="planner-card-head station-card-title"><h3>역사 현황</h3></div>
      <div class="station-rail-row main"><button type="button" class="planner-station all ${!currentStation?'selected':''}" onclick="selectFacilityStation('')"><i></i><span>전체</span></button>${main.map(stationNode).join('')}</div>
      ${unmanned.length ? `<div class="station-rail-caption">무인국사 / 지도 외 감시지점</div><div class="station-rail-row unmanned-row">${unmanned.map(stationNode).join('')}</div>` : ''}
      <div class="planner-status-legend station-legend-bottom"><span class="normal">정상</span><span class="warn">주의</span><span class="bad">장애</span><span class="off">PING 실패 / 미확인</span><span class="unmanned">무인국사</span></div>
    </section>`;
  }
  function selectedBar() {
    const station = currentStationData();
    const status = station ? station.sttsCd : summaryStatus();
    const s = currentData.summary || {};
    const critical = n(s.criticalNocs), caution = n(s.cautionNocs), unknown = n(s.unknownNocs)+n(s.offlineNocs);
    const alertParts = [];
    if (critical) alertParts.push(`장애 ${critical}건`);
    if (caution) alertParts.push(`주의 ${caution}건`);
    if (n(s.offlineNocs)) alertParts.push(`PING 실패 ${n(s.offlineNocs)}대`);
    if (n(s.unknownNocs)) alertParts.push(`미확인·수집 지연 ${n(s.unknownNocs)}대`);
    const alertMarkup = alertParts.length
      ? `<span class="facility-alert-pill ${critical?'bad':caution?'warn':'off'}">${safe(alertParts.join(' · '))}</span>`
      : `<span class="facility-alert-pill normal">정상</span>`;
    return `<section class="facility-selected-bar facility-selected-summary"><div class="facility-selected-title"><strong>${safe(stationName())}</strong>${alertMarkup}</div><small>등록장비 ${n(s.totalNocs)}대</small></section>`;
  }
  function metricIcon(type){
    return {fault:'!',link:'↔',perf:'↗'}[type] || '•';
  }
  function metricPanel(title, iconType, body, foot){
    return `<section class="planner-card metric-panel metric-${iconType}"><div class="metric-panel-head"><span class="metric-icon">${metricIcon(iconType)}</span><h3>${safe(title)}</h3></div><div class="metric-panel-body">${body}</div>${foot?`<div class="metric-panel-foot">${foot}</div>`:''}</section>`;
  }
  function overviewLegendItem(cls,label,value){
    return `<span class="metric-list-item ${cls}"><i></i><label>${label}</label><b>${value}</b></span>`;
  }
  function topologyNodeInfo(e){
    const code = normalizeStatusCode(e.sttsCd);
    if (code === 'CRITICAL') return {cls:'bad', label:'장애'};
    if (code === 'CAUTION') return {cls:'warn', label:'주의'};
    if (code === 'OFFLINE') return {cls:'off', label:'PING 실패'};
    if (code === 'UNKNOWN') return {cls:'off', label:'미확인'};
    return {cls:'normal', label:'정상'};
  }
  function compactDate(value){
    if(!value) return '-';
    return String(value).replace('T',' ').slice(0,16);
  }
  function firstEquipment(filter){
    return (currentData.equipments||[]).find(filter) || null;
  }
  function calcStateCount(list, code){ return (list||[]).filter(x=>normalizeStatusCode(x.sttsCd)===code).length; }
  function zoneHealthText(list){
    const total=(list||[]).length, bad=(list||[]).filter(x=>normalizeStatusCode(x.sttsCd)!=='NORMAL').length;
    if(!total) return '장비 수량 및 장애 여부는 연동 정보 기준으로 표시';
    return bad ? `이상 ${bad}대 · 정상 ${Math.max(0,total-bad)}대` : `연결상태 수신 가능`;
  }
  function metricInlineStat(label, value, cls){
    return `<span class="metric-inline-stat ${cls||''}"><label>${label}</label><b>${safe(value)}</b></span>`;
  }
  function metricCard(title, value, sub, type) {
    return `<article class="facility-metric-card ${type||''}"><span>${safe(title)}</span><strong>${safe(value)}</strong><small>${safe(sub || '')}</small></article>`;
  }
  function commonSummaryCards() {
    const s = currentData.summary || {};
    const list = currentData.equipments || [];
    const total = n(s.totalNocs);
    const normal = n(s.normalNocs);
    const ping = avgPing(list);
    return `<div class="facility-summary-grid">
      ${metricCard('장비 운영 상태', `${normal} / ${total}`, `정상 ${normal} · 주의 ${n(s.cautionNocs)} · 장애 ${n(s.criticalNocs)}`, statusType(summaryStatus()))}
      ${metricCard('PING 상태', `${normal} / ${total}`, `PING 실패 ${n(s.offlineNocs)} · 미확인 ${n(s.unknownNocs)}`, n(s.offlineNocs)+n(s.unknownNocs)?'off':'normal')}
      ${metricCard('정상 장비 비율', `${percent(normal,total)}%`, '장비 상태 기준 · 전송 성공률이 아님', percent(normal,total) >= 90?'normal':'warn')}
    </div>`;
  }
  function statusCountsMarkup() {
    const s = currentData.summary || {};
    return `<div class="status-summary-lines">
      <div><span class="dot normal"></span><label>정상</label><b>${n(s.normalNocs)}</b></div>
      <div><span class="dot warn"></span><label>주의</label><b>${n(s.cautionNocs)}</b></div>
      <div><span class="dot bad"></span><label>장애</label><b>${n(s.criticalNocs)}</b></div>
      <div><span class="dot off"></span><label>통신단절</label><b>${n(s.unknownNocs)+n(s.offlineNocs)}</b></div>
    </div>`;
  }
  function topologyNodes(limit) {
    // 게이트웨이 com_device_info에는 실제 포트·장비 연결관계가 없음.
    // 임의로 선택한 장비를 선으로 연결하면 물리 구성도처럼 오인될 수 있어 목록만 보여준다.
    const list=(currentData.equipments||[]).slice(0,limit||5);
    if (!list.length) return '<div class="planner-empty compact">표시할 장비가 없습니다.</div>';
    return `<div class="facility-topology facility-topology-tx">
      <div class="tx-child-row tx-count-${list.length}">${list.map(function(e){
        const st=topologyNodeInfo(e);
        return `<button type="button" class="tx-child-node ${st.cls}" onclick="openEquipmentDetail('${safe(e.eqpmntSn)}')">
          <span class="tx-rack-icon"></span><b>${safe(e.eqpmntNm||'전송장비')}</b>
          <small>${safe(e.eqpmntMdlNm||'-')}</small><em>${safe(st.label)}</em></button>`;
      }).join('')}</div>
    </div>`;
  }
  function transmissionOverview() {
    const s=currentData.summary||{}, list=currentData.equipments||[];
    const total=n(s.totalNocs), normal=n(s.normalNocs), off=n(s.offlineNocs), unknown=n(s.unknownNocs);
    const freshPerf=list.filter(x=>x.usageFreshYn==='Y').length;
    const cpu=s.cpuUsgrt==null?null:Number(s.cpuUsgrt), mmry=s.mmryUsgrt==null?null:Number(s.mmryUsgrt);
    const faultBody=`<div class="metric-big"><strong>${n(s.criticalNocs)+n(s.cautionNocs)}</strong><small>대</small></div>
      <div class="metric-split-tags"><span class="mini-tag ok">정상 ${normal}대</span><span class="mini-tag bad">장애 ${n(s.criticalNocs)}대</span><span class="mini-tag warn">주의 ${n(s.cautionNocs)}대</span></div>`;
    const pingBody=`<div class="metric-big blue"><strong>${normal+n(s.criticalNocs)+n(s.cautionNocs)}</strong><small>/ ${total}</small></div>
      <div class="metric-legend-col">${overviewLegendItem('normal','최근 PING 성공', (normal+n(s.criticalNocs)+n(s.cautionNocs))+'대')}
      ${overviewLegendItem('bad','최근 PING 실패',off+'대')}${overviewLegendItem('warn','미확인·수집지연',unknown+'대')}</div>`;
    const perfBody=`<div class="metric-percent"><strong>${freshPerf}<small> / ${total}대</small></strong><small>최근 5분 성능 수집 장비</small></div>
      <div class="metric-list">${metricInlineStat('CPU 평균 (최근)',cpu==null?'-':cpu.toFixed(1)+' %')}
      ${metricInlineStat('메모리 평균 (최근)',mmry==null?'-':mmry.toFixed(1)+' %')}
      ${metricInlineStat('수집값 0%', '실제 0% 또는 수집 실패 여부 확인 필요')}</div>`;
    return `<div class="facility-overview-grid tx-overview">${metricPanel('장비 장애 상태','fault',faultBody)}
      ${metricPanel('PING 상태','link',pingBody)}${metricPanel('성능 수집 현황','perf',perfBody)}
      <section class="planner-card topology-card-wide tx-topology-card"><div class="planner-card-head">
      <h3>전송 장비 목록 (상위 5대)</h3><small>장비 간 실제 연결관계 미수신 · 논리 구성도 아님</small></div>
      ${topologyNodes(5)}</section></div>`;
  }
  function pidsAreaOf(e) {
    const type=String((e&&e.eqpmntSeCd)||'').toUpperCase();
    if(type==='HSE' || type==='LSE') return 'CONTROL';
    const text = String((e.instlPlcNm || '') + ' ' + (e.eqpmntNm || '')).toLowerCase();
    if (text.indexOf('승강장') >= 0 || text.indexOf('platform') >= 0) return 'PLATFORM';
    if (text.indexOf('대합실') >= 0 || text.indexOf('lobby') >= 0) return 'LOBBY';
    return 'ETC';
  }
  function pidsOverview() {
    const list=currentData.equipments||[];
    const hse=list.filter(x=>String(x.eqpmntSeCd||'').toUpperCase()==='HSE'||/HSE/i.test((x.eqpmntNm||'')+' '+(x.eqpmntClsfNm||'')));
    const hseMain=hse.find(x=>/MAIN/i.test((x.eqpmntNm||'')+' '+(x.emsId||'')+' '+(x.eqpmntMdlNm||''))) || hse[0] || null;
    const hseSub=hse.find(x=>/SUB/i.test((x.eqpmntNm||'')+' '+(x.emsId||'')+' '+(x.eqpmntMdlNm||''))) || hse.find(x=>x!==hseMain) || null;
    const lse=list.filter(x=>String(x.eqpmntSeCd||'').toUpperCase()==='LSE'||/LSE/i.test((x.eqpmntNm||'')+' '+(x.eqpmntClsfNm||'')));
    const platform=list.filter(x=>pidsAreaOf(x)==='PLATFORM');
    const lobby=list.filter(x=>pidsAreaOf(x)==='LOBBY');
    const alarms=(currentData.gatewayFaults||[]).slice(0,4);
    const lseItem=lse[0] || null;
    function zone(name,items,cls){
      const abnormal=items.filter(x=>normalizeStatusCode(x.sttsCd)!=='NORMAL').length;
      return `<div class="pids-zone js-pids-zone ${cls}"><h4>${name}</h4><div class="pids-zone-chips"><span class="chip muted">게이트웨이 장비 등록 기준</span><span class="chip muted">실제 장비 연결관계 미확정</span></div><small>${items.length?`장비 ${items.length}대 · ${abnormal?`비정상·미확인 ${abnormal}대`:'정상'}`:'연동 정보 확인 후 표시'}</small></div>`;
    }
    return `<div class="pids-overview-grid">
      <section class="planner-card pids-architecture-card"><div class="planner-card-head"><h3>행선안내설비 구성도 (참고)</h3><small>실제 연결관계 미수신 · 임의 매칭 없음</small></div>
        <div class="facility-topology facility-topology-pids js-topology" data-topology="pids"><svg class="facility-connector-layer" aria-hidden="true"></svg>
          <div class="pids-hse-row"><div class="pids-hse-node js-pids-hse"><span class="tx-rack-icon"></span><b>HSE Main</b><em>${hseMain?'등록':'미확인'}</em></div><div class="pids-hse-node js-pids-hse ${hseSub?'':'waiting'}"><span class="tx-rack-icon"></span><b>HSE Sub</b><em>${hseSub?'등록':'미확인'}</em></div></div>
          <div class="pids-lse-node js-pids-lse ${lseItem?statusType(lseItem.sttsCd):'off'}"><span class="tx-rack-icon"></span><b>LSE</b><strong>${safe(lseItem?lseItem.eqpmntNm:(stationName()+' 행선안내설비'))}</strong><em>${safe(lseItem?codeLabel(lseItem.sttsCd):'미확인')}</em></div>
          <div class="pids-zone-row">${zone('승강장 표시장치',platform,'platform')}${zone('대합실 표시장치',lobby,'lobby')}</div>
        </div>
        <div class="pids-dependency"><b>하부 연동 시스템</b><span>CCTV <small>연동대상</small></span><span>시계 <small>연동대상</small></span><span>화재정보 <small>연동대상</small></span><span>열차진입정보 <small>연동대상</small></span><span>방송시스템 <small>별도 연동대상</small></span></div>
      </section>
      <section class="planner-card realtime-alarm-card"><div class="planner-card-head"><h3>게이트웨이 장애 메시지 (저장된 발생 중 장애)</h3></div>${alarms.length?alarms.map(function(x){return `<div class="pids-live-fault"><span class="alarm-bullet bad"></span><b>${safe(compactDate(x.dsbltyOcrnDt))}</b><small>${safe((x.eqpmntNm||x.souEqpmntId||'장비 미매핑')+' / '+(x.dsbltyOcrnCn||'-'))}</small></div>`;}).join(''):'<div class="planner-empty compact">현재 게이트웨이의 발생 중 장애가 없습니다. (별도 PING 상태와 구분)</div>'}</section>
    </div>`;
  }
  function scadaOverview() {
    const s=currentData.summary||{}, list=currentData.equipments||[], bad=list.filter(x=>normalizeStatusCode(x.sttsCd)==='CRITICAL'), warn=list.filter(x=>normalizeStatusCode(x.sttsCd)==='CAUTION');
    const total=list.length;
    return `<div class="scada-overview-grid"><section class="planner-card scada-status-card"><div class="planner-card-head"><h3>SCADA 운영 상태</h3></div><div class="status-tile-row"><div class="status-tile primary"><span>관제 장비</span><b>${total? total+'대':'DB 확인'}</b></div><div class="status-tile normal"><span>정상</span><b>${n(s.normalNocs)}대</b></div><div class="status-tile warn"><span>주의</span><b>${n(s.cautionNocs)}대</b></div><div class="status-tile bad"><span>장애</span><b>${n(s.criticalNocs)}대</b></div></div><div class="ems-strip"><b>SCADA EMS</b><span>EMS ID <strong>${safe((list[0]&&list[0].emsId)||'16')}</strong></span><span>장애정보 <strong>${n(s.criticalNocs)}</strong></span><span>연동 <strong>${n(s.unknownNocs)?'확인':'연결'}</strong></span><span>성능 수집 <strong>${list.length?'5분':'-'}</strong></span><span>구성 동기화 <strong>${list.length?'1일 1회':'-'}</strong></span></div><small class="card-note">실제 현재 연동 정상 여부는 수신상태 확인 후 표시</small></section><section class="planner-card scada-perf-card"><div class="planner-card-head"><h3>성능 현황</h3><p>EMS에서 CPU / MEMORY 5분 간격 수집</p></div><div class="perf-box-grid"><div><span>CPU 평균</span><b>${s.cpuUsgrt==null?'수신값':Number(s.cpuUsgrt).toFixed(1)+'%'}</b></div><div><span>Memory 평균</span><b>${s.mmryUsgrt==null?'수신값':Number(s.mmryUsgrt).toFixed(1)+'%'}</b></div><div class="warn-box"><span>CPU 이상 장비</span><b>${bad.length?'DB 확인':'DB 확인'}</b></div><div class="warn-box"><span>Memory 이상 장비</span><b>${warn.length?'DB 확인':'DB 확인'}</b></div></div><small class="card-note">실제 EMS 성능데이터 연동 후 표출</small></section><section class="planner-card event-placeholder"><div class="planner-card-head"><h3>최근 출입 이벤트</h3></div>${(currentData.scadaEvents||[]).length?(currentData.scadaEvents||[]).slice(0,4).map(function(x){return `<div class="event-line verbose"><b>${safe(x.stnNm||x.eqpmntNm)}</b><small>${safe(x.evntNm)} · ${safe(compactDate(x.enexDt))}</small></div>`;}).join(''):'<div class="placeholder-copy"><b>연동자료 확인 후 표시</b><span>기능 영역 유지 · 제공 항목 및 연동 가능 여부 확인 필요</span></div>'}</section><section class="planner-card event-placeholder"><div class="planner-card-head"><h3>비정상 개방 알람</h3></div>${bad.concat(warn).length?bad.concat(warn).slice(0,4).map(function(x){return `<div class="event-line verbose"><b>${safe(x.eqpmntNm)}</b><small>${safe(x.sttsExpln)}</small></div>`;}).join(''):'<div class="placeholder-copy"><b>연동자료 확인 후 표시</b><span>기능 영역 유지 · 제공 항목 및 연동 가능 여부 확인 필요</span></div>'}</section></div>`;
  }
  
  function commonInlinePerformance() {
    const list=currentData.equipments||[], s=currentData.summary||{};
    const ping=avgPing(list), total=n(s.totalNocs), normal=n(s.normalNocs);
    const cpu=s.cpuUsgrt==null?null:Number(s.cpuUsgrt), mmry=s.mmryUsgrt==null?null:Number(s.mmryUsgrt);
    return `<div class="inline-performance"><div><strong>${percent(normal,total)}%</strong><span>정상 운영률</span></div><div><strong>${ping==null?'-':ping+'ms'}</strong><span>평균 응답</span></div><div><strong>${cpu==null?'-':cpu.toFixed(1)+'%'}</strong><span>CPU 평균</span></div><div><strong>${mmry==null?'-':mmry.toFixed(1)+'%'}</strong><span>Memory 평균</span></div></div>`;
  }
  function pbxOverview() {
    const list=currentData.equipments||[];
    const phones=list.filter(x=>/전화|phone/i.test((x.cmpntNm||'')+' '+(x.eqpmntClsfNm||''))).length;
    const gateways=list.filter(x=>/gateway|게이트웨이|MG/i.test((x.cmpntNm||'')+' '+(x.eqpmntClsfNm||''))).length;
    const switches=list.filter(x=>/switch|스위치|IP 전화/i.test((x.cmpntNm||'')+' '+(x.eqpmntClsfNm||''))).length;
    const s=currentData.summary||{};
    return `<div class="pbx-overview-grid"><section class="planner-card scada-status-card"><div class="planner-card-head"><h3>전화교환설비 운영 현황</h3></div><div class="status-tile-row"><div class="status-tile primary"><span>관제 장비</span><b>${list.length? list.length+'대':'DB 확인'}</b></div><div class="status-tile normal"><span>정상</span><b>${n(s.normalNocs)}대</b></div><div class="status-tile warn"><span>주의</span><b>${n(s.cautionNocs)}대</b></div><div class="status-tile bad"><span>장애</span><b>${n(s.criticalNocs)}대</b></div></div><div class="ems-strip"><b>교환설비 EMS</b><span>EMS ID <strong>${safe((list[0]&&list[0].emsId)||'16')}</strong></span><span>장애정보 <strong>${n(s.criticalNocs)}</strong></span><span>연동 <strong>${n(s.unknownNocs)?'확인':'연결'}</strong></span><span>성능 수집 <strong>${list.length?'5분':'-'}</strong></span><span>구성 동기화 <strong>${list.length?'1일 1회':'-'}</strong></span></div><small class="card-note">실제 현재 연동 정상 여부는 수신상태 확인 후 표시</small></section><section class="planner-card scada-perf-card"><div class="planner-card-head"><h3>성능 현황</h3><p>EMS에서 CPU / MEMORY 5분 간격 수집</p></div><div class="perf-box-grid"><div><span>CPU 평균</span><b>${s.cpuUsgrt==null?'수신값':Number(s.cpuUsgrt).toFixed(1)+'%'}</b></div><div><span>Memory 평균</span><b>${s.mmryUsgrt==null?'수신값':Number(s.mmryUsgrt).toFixed(1)+'%'}</b></div><div class="warn-box"><span>CPU 이상 장비</span><b>DB 확인</b></div><div class="warn-box"><span>Memory 이상 장비</span><b>DB 확인</b></div></div><small class="card-note">실제 EMS 성능데이터 연동 후 표출</small></section><section class="planner-card subscriber-card subscriber-full"><div class="planner-card-head"><h3>가입자·회선 현황</h3><small>기존 상세설계 반영 · EMS 제공 항목 확인 후 표시</small></div><div class="subscriber-wide-grid"><div><span>가입자 정보</span><b>${phones? phones+'건':'연동자료 확인'}</b></div><div><span>가입자 회선 정보</span><b>${gateways? gateways+'건':'연동자료 확인'}</b></div><div><span>회선 감시 상태</span><b>${switches? switches+'건':'연동자료 확인'}</b></div></div></section></div>`;
  }
  
  function cctvOverview() {
    const list=currentData.equipments||[], groups={};
    list.forEach(function(x){ const key=x.flrNm||'기타'; if(!groups[key]) groups[key]={total:0,bad:0,items:[]}; groups[key].total+=(n(x.cmraQty)||1); if(normalizeStatusCode(x.sttsCd)!=='NORMAL') groups[key].bad++; groups[key].items.push(x); });
    const entries=Object.keys(groups).slice(0,4);
    const totalCam=list.reduce(function(sum,x){ return sum+(n(x.cmraQty)||1); },0);
    return `<div class="cctv-overview-grid"><section class="planner-card cctv-area-card"><div class="planner-card-head"><div><h3>영상감시설비 운영 현황</h3><p>층 &gt; 설치구역 &gt; 카메라 목록으로 단계적으로 종합 확인</p></div><div class="summary-pills"><span class="mini-tag bad">현재 이상 카메라 ${calcStateCount(list,'CRITICAL')}대</span><span class="mini-tag neutral">총 ${totalCam} · 정상 ${n((currentData.summary||{}).normalNocs)} · 주의 ${n((currentData.summary||{}).cautionNocs)} · 장애 ${n((currentData.summary||{}).criticalNocs)}</span></div></div><div class="cctv-floor-grid">${entries.length?entries.map(function(k){ const g=groups[k]; return `<button type="button" class="cctv-floor-card ${g.bad?'bad-outline':''}"><h4>${safe(k)}</h4><span>전체 ${g.total}대</span><b class="${g.bad?'bad-text':'ok-text'}">${g.bad?('이상 '+g.bad):'이상 0'}</b></button>`; }).join(''):'<div class="planner-empty compact">등록된 CCTV가 없습니다.</div>'}</div><div class="cctv-subarea-grid">${entries.length?entries.flatMap(function(k){ return groups[k].items.slice(0,1).map(function(item){ const st=statusType(item.sttsCd); return `<div class="subarea-card ${st}"><strong>${safe((item.instlPlcNm||k).split('/')[0])}</strong><span>${safe(item.cmraQty||1)}대</span><em>${safe(codeLabel(item.sttsCd))}</em></div>`; }); }).join(''):''}</div></section><section class="planner-card cctv-health-card"><div class="planner-card-head"><h3>CCTV 시스템 Health</h3><p>카메라 장애와 별개로 VMS / 저장계 / Network 운영상태를 보조 확인</p></div><div class="health-list"><div><b>VMS 서버</b><span>상태 정상 · CPU / Memory / HDD 수신</span><em>현재 영향 0대</em></div><div><b>NVR / 저장계</b><span>상태 정상 / 저장값 수신</span><em>현재 영향 0대</em></div><div><b>CCTV Network</b><span>시스템 구간 정상 / 개별 카메라 이상은 목록에서 확인</span><em>현재 영향 0대</em></div></div></section></div>`;
  }
  
  function overviewMarkup() {
    if (PAGE_KEY === 'systems') return transmissionOverview();
    if (PAGE_KEY === 'equipment') return pidsOverview();
    if (PAGE_KEY === 'scada') return scadaOverview();
    if (PAGE_KEY === 'switch') return pbxOverview();
    return cctvOverview();
  }

  function filteredEquipment() {
    let list=(currentData.equipments||[]).slice();
    if (facilityStatus) list=list.filter(x=>normalizeStatusCode(x.sttsCd)===facilityStatus);
    if (PAGE_KEY==='equipment' && pidsArea!=='ALL') list=list.filter(x=>pidsAreaOf(x)===pidsArea);
    return list;
  }
  function tableColumns() {
    if (PAGE_KEY==='systems') return ['선택','NO.','상태','역사/위치','장비명','장비구분','IP','CPU','Memory','Disk','현재 알람','메모','관리'];
    if (PAGE_KEY==='equipment') return ['선택','NO.','상태','위치구분','장비명','장비구분','IP/연동주소','발생시간','연동정보','현재 알림','처리상태','관리'];
    if (PAGE_KEY==='scada') return ['선택','NO.','상태','위치구분','장비ID','장비명','장비종류','IP','발생위치','현재 장애','CPU','Memory','발생시간','관리'];
    if (PAGE_KEY==='switch') return ['선택','NO.','상태','역사','장비 ID','장비명','장비종류','IP','감시방식','발생위치','현재 장애','CPU','Memory','관리'];
    if (PAGE_KEY==='cctv') return ['선택','NO.','상태','역사/VMS 명','저장방식','이름','모델','CCTV IP','CCTV MAC','층명','수량','관리'];
    return ['선택','NO.','상태','역사/위치','장비종류','장비ID','장비명','IP','현재 장애','CPU','Memory','마지막 확인','메모','관리'];
  }
  
  function equipmentRow(e, idx) {
    const canEdit=global.hasPermission(PAGE_KEY,'mdfcnAuthrtYn');
    const status=`<span class="planner-status ${statusType(e.sttsCd)}"><i></i>${safe(statusLabel(e))}</span>`;
    const place=PAGE_KEY==='cctv' ? [e.stnNm,e.flrNm||e.instlPlcNm].filter(Boolean).join(' / ') : PAGE_KEY==='systems' ? [e.stnNm,e.instlPlcNm].filter(Boolean).join(' / ') : safe(e.instlPlcNm||e.stnNm);
    const commonManage=`<button class="btn sm" type="button" onclick="openEquipmentDetail('${safe(e.eqpmntSn)}')">상세</button>${canEdit?` <button class="btn sm" type="button" onclick="openEquipmentModal(${e.eqpmntSn})">수정</button>`:''}`;
    if (PAGE_KEY==='systems') {
      return `<tr><td class="center"><input type="checkbox" class="facility-row-check" value="${e.eqpmntSn}" ></td><td>${idx}</td><td>${status}</td><td title="${safe(place)}">${safe(place)}</td><td class="equipment-name"><button type="button" onclick="openEquipmentDetail('${safe(e.eqpmntSn)}')">${safe(e.eqpmntNm)}</button><small>${safe(e.eqpmntMngNo)}</small></td><td>${safe(e.eqpmntClsfNm||e.eqpmntSeCd)}</td><td>${safe(e.eqpmntIpAddr)}</td><td>${e.cpuUsgrt==null?'-':safe(Number(e.cpuUsgrt).toFixed(1))}</td><td>${e.mmryUsgrt==null?'-':safe(Number(e.mmryUsgrt).toFixed(1))+'%'}</td><td>${e.diskUsgrt==null?'-':safe(Number(e.diskUsgrt).toFixed(1))+'%'}</td><td class="alarm-text ${normalizeStatusCode(e.sttsCd)!=='NORMAL'?'active':''}">${safe(e.sttsExpln||'-')}</td><td title="${safe(e.eqpmntExpln||'-','')}">${safe(e.eqpmntExpln||'-')}</td><td>${commonManage}</td></tr>`;
    }
    if (PAGE_KEY==='equipment') {
      return `<tr><td class="center"><input type="checkbox" class="facility-row-check" value="${e.eqpmntSn}" ></td><td>${idx}</td><td>${status}</td><td>${safe(pidsAreaOf(e)==='PLATFORM'?'승강장':pidsAreaOf(e)==='LOBBY'?'대합실':pidsAreaOf(e)==='CONTROL'?String(e.eqpmntSeCd||'HSE/LSE'):'기타')}</td><td class="equipment-name"><button type="button" onclick="openEquipmentDetail('${safe(e.eqpmntSn)}')">${safe(e.eqpmntNm)}</button></td><td>${safe(e.eqpmntClsfNm||e.eqpmntSeCd)}</td><td>${safe(e.eqpmntIpAddr)}</td><td>${safe(compactDate(e.lastRspnsDt||e.clctDt))}</td><td title="${safe(e.lseEqpmntNms||'연동정보 미확인','')}">${safe(e.lseEqpmntNms||'연동정보 미확인')}</td><td class="alarm-text ${normalizeStatusCode(e.sttsCd)!=='NORMAL'?'active':''}">${safe(e.sttsExpln||'-')}</td><td>${normalizeStatusCode(e.sttsCd)==='NORMAL'?'정상':'확인중'}</td><td>${commonManage}</td></tr>`;
    }
    if (PAGE_KEY==='scada') {
      return `<tr><td class="center"><input type="checkbox" class="facility-row-check" value="${e.eqpmntSn}" ></td><td>${idx}</td><td>${status}</td><td>${safe(e.instlPlcNm||'DB확인')}</td><td>${safe(e.eqpmntMngNo||e.eqpmntSn)}</td><td>${safe(e.eqpmntNm)}</td><td>${safe(e.eqpmntClsfNm||e.eqpmntSeCd)}</td><td>${safe(e.eqpmntIpAddr)}</td><td>${safe(e.cmpntNm||'COMM')}</td><td class="alarm-text ${normalizeStatusCode(e.sttsCd)!=='NORMAL'?'active':''}">${safe(e.sttsExpln||'-')}</td><td>${e.cpuUsgrt==null?'-':safe(Number(e.cpuUsgrt).toFixed(1))}</td><td>${e.mmryUsgrt==null?'-':safe(Number(e.mmryUsgrt).toFixed(1))}</td><td>${safe(compactDate(e.lastRspnsDt||e.clctDt))}</td><td>${commonManage}</td></tr>`;
    }
    if (PAGE_KEY==='switch') {
      return `<tr><td class="center"><input type="checkbox" class="facility-row-check" value="${e.eqpmntSn}" ></td><td>${idx}</td><td>${status}</td><td>${safe(e.stnNm)}</td><td>${safe(e.eqpmntMngNo||e.eqpmntSn)}</td><td>${safe(e.eqpmntNm)}</td><td>${safe(e.pbxEqpmNm||e.cmpntNm||e.eqpmntClsfNm)}</td><td>${safe(e.eqpmntIpAddr)}</td><td>${safe(e.pingAlive===1?'PING 성공':e.pingAlive===-1?'PING 실패':'미확인')}</td><td>${safe(e.instlPlcNm||'DB 확인')}</td><td class="alarm-text ${normalizeStatusCode(e.sttsCd)!=='NORMAL'?'active':''}">${safe(e.sttsExpln||'-')}</td><td>${e.cpuUsgrt==null?'-':safe(Number(e.cpuUsgrt).toFixed(1))}</td><td>${e.mmryUsgrt==null?'-':safe(Number(e.mmryUsgrt).toFixed(1))}</td><td>${commonManage}</td></tr>`;
    }
    if (PAGE_KEY==='cctv') {
      const vmsPlace=[e.stnNm,e.vmsNm].filter(Boolean).join(' / ');
      return `<tr><td class="center"><input type="checkbox" class="facility-row-check" value="${e.eqpmntSn}" ></td><td>${idx}</td><td>${status}</td><td title="${safe(vmsPlace,'')}">${safe(vmsPlace||'-')}</td><td>${safe(e.strgMthNm||'-')}</td><td class="equipment-name cctv-name-cell" title="${safe(e.cctvNm||e.eqpmntNm,'')}"><button type="button" onclick="openEquipmentDetail('${safe(e.eqpmntSn)}')">${safe(e.cctvNm||e.eqpmntNm)}</button><small>${safe(e.eqpmntMngNo)}</small></td><td title="${safe(e.cctvMdlNm||e.eqpmntMdlNm||'-','')}">${safe(e.cctvMdlNm||e.eqpmntMdlNm||'-')}</td><td>${safe(e.cctvIpAddr||e.eqpmntIpAddr||'-')}</td><td>${safe(e.cctvMacAddr||e.macAddr||'-')}</td><td>${safe(e.flrNm||'-')}</td><td>${safe(e.cmraQty||1)}</td><td class="cctv-manage-cell">${commonManage}</td></tr>`;
    }
    return `<tr><td class="center"><input type="checkbox" class="facility-row-check" value="${e.eqpmntSn}" ></td><td>${idx}</td><td>${status}</td><td title="${safe(place)}">${safe(place)}</td><td>${safe(e.eqpmntClsfNm||e.eqpmntSeCd)}</td><td>${safe(e.eqpmntMngNo)}</td><td class="equipment-name"><button type="button" onclick="openEquipmentDetail('${safe(e.eqpmntSn)}')">${safe(e.eqpmntNm)}</button></td><td>${safe(e.eqpmntIpAddr)}</td><td class="alarm-text ${normalizeStatusCode(e.sttsCd)!=='NORMAL'?'active':''}">${safe(e.sttsExpln||'-')}</td><td>${e.cpuUsgrt==null?'-':safe(Number(e.cpuUsgrt).toFixed(1))}</td><td>${e.mmryUsgrt==null?'-':safe(Number(e.mmryUsgrt).toFixed(1))}</td><td>${safe(compactDate(e.lastRspnsDt||e.clctDt))}</td><td title="${safe(e.eqpmntExpln||'등록 메모 확인 영역','')}">${safe(e.eqpmntExpln||'등록 메모 확인 영역')}</td><td>${commonManage}</td></tr>`;
  }
  
  function pagination(total) {
    const pages=Math.max(1,Math.ceil(total/PAGE_SIZE));
    if (currentPage>pages) currentPage=pages;
    const start=Math.max(1,currentPage-2), end=Math.min(pages,start+4);
    let buttons=`<button ${currentPage===1?'disabled':''} onclick="changeFacilityPage(${currentPage-1})">‹</button>`;
    for(let i=start;i<=end;i++) buttons+=`<button class="${i===currentPage?'on':''}" onclick="changeFacilityPage(${i})">${i}</button>`;
    buttons+=`<button ${currentPage===pages?'disabled':''} onclick="changeFacilityPage(${currentPage+1})">›</button>`;
    return `<div class="planner-pager">${buttons}</div>`;
  }
  function equipmentTable() {
    const list=filteredEquipment(), start=(currentPage-1)*PAGE_SIZE, rows=list.slice(start,start+PAGE_SIZE);
    const pidsTabs=PAGE_KEY==='equipment'?`<div class="facility-subtabs"><button class="${pidsArea==='ALL'?'active':''}" onclick="setPidsArea('ALL')">전체 장비</button><button class="${pidsArea==='PLATFORM'?'active':''}" onclick="setPidsArea('PLATFORM')">승강장 표시장치</button><button class="${pidsArea==='LOBBY'?'active':''}" onclick="setPidsArea('LOBBY')">대합실 표시장치</button><button class="${pidsArea==='CONTROL'?'active':''}" onclick="setPidsArea('CONTROL')">HSE / LSE</button><button class="${pidsArea==='ETC'?'active':''}" onclick="setPidsArea('ETC')">분류 미확정</button></div>`:'<div></div>';
    const addBtn=global.hasPermission(PAGE_KEY,'regAuthrtYn')?`<button class="btn primary" onclick="openEquipmentModal()">+ 장비 등록</button>`:'';
    const delBtn=global.hasPermission(PAGE_KEY,'delAuthrtYn')?`<button class="btn" onclick="deleteSelectedEquipment()">선택 삭제</button>`:'';
    const typeFilter = (PAGE_KEY==='scada'||PAGE_KEY==='switch'||PAGE_KEY==='cctv') ? '<select class="input compact"><option value="">장비별 전체</option></select>' : '';
    return `<section class="planner-card facility-list-card">
      <div class="planner-card-head list-title-row"><div><h3>상세목록</h3></div></div>
      <div class="facility-list-toolbar">${pidsTabs}<div class="list-filter-inline">${typeFilter}<select id="facilityStatusFilter" class="input compact" onchange="applyFacilityFilters()"><option value="">상태 전체</option><option value="NORMAL" ${facilityStatus==='NORMAL'?'selected':''}>정상</option><option value="CAUTION" ${facilityStatus==='CAUTION'?'selected':''}>주의</option><option value="CRITICAL" ${facilityStatus==='CRITICAL'?'selected':''}>장애</option><option value="OFFLINE" ${facilityStatus==='OFFLINE'?'selected':''}>PING 실패</option><option value="UNKNOWN" ${facilityStatus==='UNKNOWN'?'selected':''}>미확인·수집지연</option></select><input id="facilityKeyword" class="input search-input" placeholder="검색어를 입력해 주세요" value="${safe(facilityKeyword,'')}"><button class="btn primary search-btn" onclick="loadFacility()">검색</button></div></div>
      <div class="planner-table-meta"><span>총 <b>${list.length}</b>건</span><span class="table-sort-hint">최신순⌄</span></div>
      <div class="table-scroll"><table class="planner-table facility-table ${PAGE_KEY==='cctv'?'cctv-data-table':''}"><thead><tr>${tableColumns().map((c,i)=>`<th class="${i===0?'center':''}">${i===0?'—':safe(c)}</th>`).join('')}</tr></thead><tbody>${rows.length?rows.map((item,idx)=>equipmentRow(item,start+idx+1)).join(''):`<tr><td colspan="${tableColumns().length}" class="empty-row">조회된 장비가 없습니다.</td></tr>`}</tbody></table></div>
      <div class="facility-bottom-bar"><div class="facility-list-actions">${addBtn}${delBtn}</div>${pagination(list.length)}</div>
    </section>`;
  }
  function svgLine(svg,x1,y1,x2,y2){
    const ns='http://www.w3.org/2000/svg';
    const line=document.createElementNS(ns,'line');
    line.setAttribute('x1',x1); line.setAttribute('y1',y1); line.setAttribute('x2',x2); line.setAttribute('y2',y2);
    line.setAttribute('vector-effect','non-scaling-stroke'); svg.appendChild(line);
  }
  function localPoint(container,el,edge){
    const c=container.getBoundingClientRect(), r=el.getBoundingClientRect();
    return {x:r.left-c.left+r.width/2,y:(edge==='top'?r.top:r.bottom)-c.top};
  }
  function drawTopology(container){
    const svg=container.querySelector('.facility-connector-layer'); if(!svg)return;
    while(svg.firstChild)svg.removeChild(svg.firstChild);
    svg.setAttribute('viewBox',`0 0 ${container.clientWidth} ${container.clientHeight}`);
    svg.setAttribute('width',container.clientWidth); svg.setAttribute('height',container.clientHeight);
    if(container.dataset.topology==='tx'){
      const parent=container.querySelector('.js-tx-parent'), children=[...container.querySelectorAll('.js-tx-child')]; if(!parent||!children.length)return;
      const p=localPoint(container,parent,'bottom'), cps=children.map(ch=>localPoint(container,ch,'top'));
      const trunkY=Math.round((p.y+Math.min.apply(null,cps.map(v=>v.y)))/2);
      svgLine(svg,p.x,p.y,p.x,trunkY); svgLine(svg,cps[0].x,trunkY,cps[cps.length-1].x,trunkY); cps.forEach(cp=>svgLine(svg,cp.x,trunkY,cp.x,cp.y));
    } else if(container.dataset.topology==='pids'){
      const hs=[...container.querySelectorAll('.js-pids-hse')], lse=container.querySelector('.js-pids-lse'), zones=[...container.querySelectorAll('.js-pids-zone')]; if(!lse)return;
      const lt=localPoint(container,lse,'top'), lb=localPoint(container,lse,'bottom');
      hs.forEach(h=>{const hp=localPoint(container,h,'bottom'); const my=Math.round((hp.y+lt.y)/2); svgLine(svg,hp.x,hp.y,hp.x,my); svgLine(svg,hp.x,my,lt.x,my); svgLine(svg,lt.x,my,lt.x,lt.y);});
      if(zones.length){const zp=zones.map(z=>localPoint(container,z,'top')), my=Math.round((lb.y+Math.min.apply(null,zp.map(v=>v.y)))/2); svgLine(svg,lb.x,lb.y,lb.x,my); svgLine(svg,zp[0].x,my,zp[zp.length-1].x,my); zp.forEach(v=>svgLine(svg,v.x,my,v.x,v.y));}
    }
  }
  function drawAllTopologies(){document.querySelectorAll('.js-topology').forEach(drawTopology);}
  let topologyResizeTimer=null;
  function bindTopologyResize(){
    if(global.__facilityTopologyResizeBound)return; global.__facilityTopologyResizeBound=true;
    global.addEventListener('resize',function(){clearTimeout(topologyResizeTimer);topologyResizeTimer=setTimeout(drawAllTopologies,80);});
  }
  function render() {
    const body=document.getElementById('pageBody');
    if (!body) return;
    body.innerHTML=`<div class="facility-planner-page">${stationRail()}${selectedBar()}${overviewMarkup()}${equipmentTable()}</div>`;
    global.enhanceTables(body);
    bindTopologyResize();
    requestAnimationFrame(function(){ requestAnimationFrame(drawAllTopologies); });
    const keyword=document.getElementById('facilityKeyword');
    if(keyword) keyword.addEventListener('keydown',e=>{if(e.key==='Enter')loadFacility();});
  }

  global.applyFacilityFilters=function(){const status=document.getElementById('facilityStatusFilter');facilityStatus=status?status.value:'';currentPage=1;render();};
  global.changeFacilityPage=function(page){const total=filteredEquipment().length,pages=Math.max(1,Math.ceil(total/PAGE_SIZE));currentPage=Math.max(1,Math.min(pages,page));render();};
  global.setPidsArea=function(area){pidsArea=area;currentPage=1;render();};
  global.toggleFacilityChecks=function(checked){document.querySelectorAll('.facility-row-check').forEach(x=>x.checked=checked);};
  global.selectFacilityStation=async function(stnCd){currentStation=stnCd||'';currentPage=1;await loadFacility();};

  global.loadFacility=async function(){
    try{
      const params=new URLSearchParams({linkSysCd:config.linkSysCd});
      if(currentStation) params.set('stnCd',currentStation);
      const keyword=document.getElementById('facilityKeyword');
      if(keyword)facilityKeyword=keyword.value.trim();
      if(facilityKeyword)params.set('searchKeyword',facilityKeyword);
      currentData=await global.api('/facility/data.ajax?'+params.toString());
      currentData.stations=currentData.stations||[];currentData.equipments=currentData.equipments||[];currentData.summary=currentData.summary||{};currentData.statusCodes=currentData.statusCodes||[];currentData.lseCandidates=currentData.lseCandidates||[];currentData.equipmentLinks=currentData.equipmentLinks||[];currentData.scadaEvents=currentData.scadaEvents||[];currentData.gatewayFaults=currentData.gatewayFaults||[];
      render();
      const next=document.getElementById('facilityKeyword'); if(next)next.value=facilityKeyword;
    }catch(e){global.showToast(e.message,true);}
  };

  function detailPair(label, value, cls){ return `<div class="detail-pair ${cls||''}"><span>${safe(label)}</span><b>${value}</b></div>`; }
  function formField(label, control, required, extraCls){ return `<div class="planner-form-field ${extraCls||''}"><label>${safe(label)}${required?' <em>*</em>':''}</label>${control}</div>`; }
  function inputControl(name, value, placeholder, attrs){ return `<input class="form-control" name="${name}" value="${safe(value||'','')}" placeholder="${safe(placeholder||'','')}" ${attrs||''}>`; }
  function selectControl(name, options, attrs){ return `<select class="form-control" name="${name}" ${attrs||''}>${options}</select>`; }

  global.openEquipmentDetail=async function(eqpmntSn){
    try{
      const live=(currentData.equipments||[]).find(x=>String(x.eqpmntSn)===String(eqpmntSn) && x.gatewayManaged==='Y');
      const detailUrl=live
        ? '/facility/gateway-detail.ajax?emsId='+encodeURIComponent(live.emsId)+'&deviceId='+encodeURIComponent(live.gatewayDeviceId)
        : '/facility/detail.ajax?eqpmntSn='+encodeURIComponent(eqpmntSn);
      const e=await global.api(detailUrl);
      const items=[];
      if(PAGE_KEY==='cctv'){
        items.push(detailPair('설비', safe(config.name)));
        items.push(detailPair('역사', safe(e.stnNm||'-')));
        items.push(detailPair('역사_VMS 명', safe(e.vmsNm||'-')));
        items.push(detailPair('저장방식', safe(e.strgMthNm||'-')));
        items.push(detailPair('이름', safe(e.cctvNm||e.eqpmntNm||'-'),'span-2'));
        items.push(detailPair('수요자', safe(e.cnsmrNm||'-')));
        items.push(detailPair('모델', safe(e.cctvMdlNm||e.eqpmntMdlNm||'-')));
        items.push(detailPair('펌웨어', safe(e.frmwrVerNo||'-')));
        items.push(detailPair('CCTV IP', safe(e.cctvIpAddr||e.eqpmntIpAddr||'-')));
        items.push(detailPair('CCTV MAC 주소', safe(e.cctvMacAddr||e.macAddr||'-')));
        items.push(detailPair('계정', safe(e.acntNm||'-')));
        items.push(detailPair('VMS 서버 IP', safe(e.vmsSrvrIpAddr||'-')));
        items.push(detailPair('층명', safe(e.flrNm||'-')));
        items.push(detailPair('카메라 수량', safe(e.cmraQty||1)));
        items.push(detailPair('현재 장애', `<span class="detail-alarm ${normalizeStatusCode(e.sttsCd)!=='NORMAL'?'active':''}">${safe(e.sttsExpln||'-')}</span>`,'span-2'));
        global.showModal(`<div class="modal-head planner-modal-head"><div><h2>${safe(config.name)} 장비 상세</h2></div><button class="modal-close" onclick="closeModal()">×</button></div><div class="equipment-detail-hero"><div><strong>${safe(e.cctvNm||e.eqpmntNm)}</strong><span>${safe([e.stnNm,e.vmsNm].filter(Boolean).join(' / '))}</span></div><span class="planner-status ${statusType(e.sttsCd)}"><i></i>${safe(statusLabel(e))}</span></div><div class="equipment-detail-grid">${items.join('')}</div><div class="equipment-memo-block"><label>관리 메모</label><div>${safe(e.eqpmntExpln||'등록된 관리 메모가 없습니다.')}</div></div><div class="modal-actions planner-modal-actions">${global.hasPermission(PAGE_KEY,'mdfcnAuthrtYn')?`<button class="btn primary" onclick="closeModal();openEquipmentModal(${e.eqpmntSn})">수정</button>`:''}<button class="btn" onclick="closeModal()">닫기</button></div>`);
        return;
      }
      const perfText=(e.cpuUsgrt==null?'-':Number(e.cpuUsgrt).toFixed(1)+'%')+' / '+(e.mmryUsgrt==null?'-':Number(e.mmryUsgrt).toFixed(1)+'%');
      items.push(detailPair('설비', safe(config.name)));
      items.push(detailPair('역사 / 위치', safe([e.stnNm,e.instlPlcNm].filter(Boolean).join(' / '))));
      items.push(detailPair('장비명', safe(e.eqpmntNm)));
      items.push(detailPair('장비구분', safe(e.eqpmntClsfNm||e.eqpmntSeCd)));
      items.push(detailPair('IP', safe(e.eqpmntIpAddr)));
      if(e.serverIp)items.push(detailPair('서버 IP',safe(e.serverIp)));
      items.push(detailPair('CPU / Memory', safe(perfText)));
      if(PAGE_KEY==='systems') items.push(detailPair('DISK',e.diskUsgrt==null?'-':safe(Number(e.diskUsgrt).toFixed(1)+'%')));
      if(PAGE_KEY==='equipment') items.push(detailPair('연결 LSE', safe(e.lseEqpmntNms)));
      if(PAGE_KEY==='switch') items.push(detailPair('설비 / 구성품', safe((e.pbxEqpmNm||'-')+' / '+(e.cmpntNm||'-'))));
      items.push(detailPair('현재 장애', `<span class="detail-alarm ${normalizeStatusCode(e.sttsCd)!=='NORMAL'?'active':''}">${safe(e.sttsExpln||'-')}</span>`));
      global.showModal(`<div class="modal-head planner-modal-head"><div><h2>${safe(config.name)} 장비 상세</h2></div><button class="modal-close" onclick="closeModal()">×</button></div><div class="equipment-detail-hero"><div><strong>${safe(e.eqpmntNm)}</strong><span>${safe([e.stnNm,e.eqpmntClsfNm||e.eqpmntSeCd].filter(Boolean).join(' / '))}</span></div><span class="planner-status ${statusType(e.sttsCd)}"><i></i>${safe(statusLabel(e))}</span></div><div class="equipment-detail-grid">${items.join('')}</div><div class="equipment-memo-block"><label>관리 메모</label><div>${safe(e.eqpmntExpln||'등록된 관리 메모가 없습니다.')}</div></div><div class="modal-actions planner-modal-actions">${global.hasPermission(PAGE_KEY,'mdfcnAuthrtYn')?`<button class="btn primary" onclick="closeModal();openEquipmentModal(${e.eqpmntSn})">수정</button>`:''}<button class="btn" onclick="closeModal()">닫기</button></div>`);
    }catch(e){global.showToast(e.message,true);}
  };

  // Registry UI: (ems_id, device_id) is the only device identity. No legacy EQPMNT_SN writes.
  global.openEquipmentModal=async function(eqpmntSn){
    try {
      const e=eqpmntSn == null ? null :(currentData.equipments||[]).find(x=>String(x.eqpmntSn)===String(eqpmntSn));
      if(eqpmntSn!=null&&!e)throw new Error('장비를 찾을 수 없습니다.');
      const obj=e||{},edit=!!e;
      const sysStations=currentData.stations||[];
      const stnOpts='<option value="Unknown">역사 미확인</option>'+sysStations.map(x=>`<option value="${safe(x.stnCd,'')}" ${String(x.stnCd)===String(obj.stnCd)?'selected':''}>${safe(x.stnNm,'')}</option>`).join('');
      const selectedCheck=String(obj.deviceCheck==null?'0':obj.deviceCheck);
      const checkOpts=[[0,'미대상'],[1,'SNMP v1'],[2,'SNMP v2'],[3,'SNMP v3'],[10,'PING'],[11,'Socket'],[12,'API']].map(x=>`<option value="${x[0]}" ${selectedCheck===String(x[0])?'selected':''}>${x[1]}</option>`).join('');
      const fields=[
        formField('장비 ID (게이트웨이 식별자)',inputControl('eqpmntMngNo',obj.gatewayDeviceId||obj.eqpmntMngNo,'장비 ID','required maxlength="50" '+(edit?'readonly':'')),true,'span-2'),
        formField('장비명',inputControl('eqpmntNm',obj.eqpmntNm,'장비명','required maxlength="200"'),true),
        formField('장비종류',inputControl('eqpmntSeCd',obj.eqpmntSeCd||config.eqpmntSeCd,'장비종류','required maxlength="50"'),true),
        formField('장비 IP',inputControl('eqpmntIpAddr',obj.eqpmntIpAddr,'IPv4 주소','required maxlength="20"'),true),
        formField('설치 역사',selectControl('stnCd',stnOpts),false),
        formField('설치장소',inputControl('instlPlcNm',obj.instlPlcNm||obj.stnNm,'설치장소','required maxlength="300"'),true,'span-2'),
        formField('제조사',inputControl('deviceMaker',obj.deviceMaker,'제조사','maxlength="100"'),false),
        formField('서버 IP',inputControl('serverIp',obj.serverIp,'서버 IP','maxlength="20"'),false),
        formField('모델명',inputControl('eqpmntMdlNm',obj.eqpmntMdlNm,'모델명','maxlength="100"'),false),
        formField('상태 점검방법',selectControl('deviceCheck',checkOpts),false),
        formField('테스트 장비',selectControl('testYn',`<option value="N" ${obj.testYn!=='Y'?'selected':''}>아니오</option><option value="Y" ${obj.testYn==='Y'?'selected':''}>예</option>`),false),
        formField('사용여부',selectControl('useYn',`<option value="Y" ${obj.useYn!=='N'?'selected':''}>사용</option><option value="N" ${obj.useYn==='N'?'selected':''}>미사용</option>`),false),
        formField('장비 설명',`<textarea class="form-control planner-memo" rows="3" name="eqpmntExpln">${safe(obj.eqpmntExpln||'','')}</textarea>`,false,'span-2')
      ];
      global.showModal(`<div class="modal-head planner-modal-head"><div><h2>${safe(config.name)} 장비 ${edit?'수정':'등록'}</h2><p>com_device_info 기본정보 저장 · PING/성능 수집값은 변경하지 않습니다.</p></div><button class="modal-close" onclick="closeModal()">×</button></div>
       <form id="equipmentForm"><input type="hidden" name="linkSysCd" value="${safe(config.linkSysCd,'')}">
       <input type="hidden" name="emsId" value="${safe(edit?obj.emsId:({EMS_TX:1,VMS:4,PBX:11,EMS_PIDS:13,SCADA_SEC:16}[config.linkSysCd]),'')}">
       ${edit?`<input type="hidden" name="gatewayDeviceId" value="${safe(obj.gatewayDeviceId,'')}">`:''}
       <div class="planner-form-grid">${fields.join('')}</div><div class="modal-actions planner-modal-actions"><button type="button" class="btn" onclick="closeModal()">취소</button><button type="submit" class="btn primary">${edit?'수정':'등록'}</button></div></form>`);
      document.getElementById('equipmentForm').addEventListener('submit',saveEquipment);
    }catch(e){global.showToast(e.message,true);}
  };
  async function saveEquipment(event){
    event.preventDefault();
    try{
      const body=new URLSearchParams(new FormData(event.target));
      await global.api('/facility/save.ajax',{method:'POST',body});
      global.closeModal();global.showToast(body.has('gatewayDeviceId')?'장비를 수정했습니다.':'장비를 등록했습니다.');await global.loadFacility();
    }catch(e){global.showToast(e.message,true);}
  }
  global.deleteSelectedEquipment=async function(){
    const ids=[...document.querySelectorAll('.facility-row-check:checked')].map(x=>x.value);
    if(!ids.length){global.showToast('삭제할 장비를 선택해 주세요.',true);return;}
    const rows=ids.map(id=>(currentData.equipments||[]).find(x=>String(x.eqpmntSn)===String(id)));
    if(rows.some(x=>!x||!x.gatewayDeviceId)){global.showToast('삭제할 장비 ID를 확인해 주세요.',true);return;}
    if(!confirm(`${rows.length}대의 장비를 com_device_info에서 삭제합니다. 원본 수집이력은 유지됩니다. 진행하시겠습니까?`))return;
    try{
      for(const e of rows) await global.api('/facility/gateway-delete.ajax',{method:'POST',body:new URLSearchParams({emsId:e.emsId,deviceId:e.gatewayDeviceId,linkSysCd:config.linkSysCd})});
      global.showToast(`${rows.length}대 삭제했습니다.`);await global.loadFacility();
    }catch(err){global.showToast(err.message,true);}
  };

  global.TNMS_PAGE_INIT=async function(){PAGE_SIZE=global.getListPageSize?global.getListPageSize():20;await global.loadFacility();
    // DB 수집 결과는 재조회 시 반영. 사용자가 모달을 보거나 검색 중이면 자동 갱신 보류.
    if(!global.TNMS_FACILITY_TIMER)global.TNMS_FACILITY_TIMER=global.setInterval(function(){
      const el=document.activeElement;
      if(document.hidden || document.querySelector('.modal-overlay, .modal-backdrop, [role=dialog]') || (el && el.matches('input,select,textarea')))return;
      if(global.TNMS_FACILITY_REFRESHING)return;
      global.TNMS_FACILITY_REFRESHING=true;
      Promise.resolve(global.loadFacility()).finally(function(){global.TNMS_FACILITY_REFRESHING=false;});
    },60000);
  };
})(window);
