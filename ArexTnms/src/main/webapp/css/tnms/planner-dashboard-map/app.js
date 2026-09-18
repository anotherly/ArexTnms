const mapWrap = document.getElementById('routeMap');
const panel = document.getElementById('detailPanel');
const closeButton = document.getElementById('closePanel');
const detailTitle = document.getElementById('detailTitle');
const detailSummary = document.getElementById('detailSummary');

const stationButtons = [...document.querySelectorAll('.station-select')];
const nodeHotspots = [...document.querySelectorAll('.node-hotspot')];
const watchButtons = [...document.querySelectorAll('.watch-chip')];
const routeNodes = [...document.querySelectorAll('.route-node')];

let selectedLocation = '김포공항';
let selectedControl = null;
let openTimer = null;
let pulseTimer = null;

const watchPoints = new Set(['기지SS','차량기지','운서SSP','SIG2','청라SSP','통신통제실','계양SS']);

function titleFor(name) {
  if (watchPoints.has(name)) return name;
  return name.endsWith('역') ? name : `${name}역`;
}

function summaryFor(name) {
  const station = (window.TNMS_DASHBOARD_DATA && window.TNMS_DASHBOARD_DATA.stations || []).find(item => item.stnNm === name);
  if (!station) return '전체 시스템 상태를 조회 중입니다.';
  return `등록장비 ${station.totalNocs || 0} · ${dashboardPalette.NORMAL.label} ${station.normalNocs || 0} · ${dashboardPalette.CAUTION.label} ${station.cautionNocs || 0} · ${dashboardPalette.CRITICAL.label} ${station.criticalNocs || 0} · ${dashboardPalette.UNKNOWN.label} ${station.unknownNocs || 0}`;
}

function setPanelContent(name) {
  detailTitle.textContent = titleFor(name);
  detailSummary.textContent = summaryFor(name);
}

function clearSelectionVisuals() {
  stationButtons.forEach(btn => btn.classList.remove('station-selected','active'));
  nodeHotspots.forEach(btn => btn.classList.remove('is-pulsing'));
  watchButtons.forEach(btn => btn.classList.remove('point-active'));
  routeNodes.forEach(node => node.classList.remove('selected-node'));
}

function markRouteNode(name) {
  routeNodes.forEach(node => {
    if (node.dataset.node === name) node.classList.add('selected-node');
  });
}

function pulseStation(name) {
  const station = stationButtons.find(btn => btn.dataset.location === name);
  const hotspot = nodeHotspots.find(btn => btn.dataset.location === name);
  if (station) station.classList.add('station-selected','active');
  if (hotspot) hotspot.classList.add('is-pulsing');
  markRouteNode(name);
}

function pulseWatchPoint(name) {
  const chip = watchButtons.find(btn => btn.dataset.location === name);
  if (chip) chip.classList.add('point-active');
}

function updateAria(open) {
  panel.setAttribute('aria-hidden', String(!open));
  [...stationButtons, ...nodeHotspots, ...watchButtons].forEach(control => {
    control.setAttribute('aria-expanded', String(open && control.dataset.location === selectedLocation));
    control.setAttribute('aria-controls', 'detailPanel');
  });
}

function openLocation(name, control) {
  clearTimeout(openTimer);
  clearTimeout(pulseTimer);

  selectedLocation = name;
  selectedControl = control || null;
  clearSelectionVisuals();
  panel.classList.remove('open');
  updateAria(false);
  setPanelContent(name);
  const station = (window.TNMS_DASHBOARD_DATA && window.TNMS_DASHBOARD_DATA.stations || []).find(item => item.stnNm === name);
  if (station && window.parent !== window) window.parent.postMessage({source:'tnms-planner',type:'station-detail',stnCd:station.stnCd}, location.origin);

  // 재클릭 시에도 CSS animation을 처음부터 재생한다.
  void mapWrap.offsetWidth;

  if (watchPoints.has(name)) pulseWatchPoint(name);
  else pulseStation(name);

  openTimer = window.setTimeout(() => {
    panel.classList.add('open');
    updateAria(true);
  }, 135);

  pulseTimer = window.setTimeout(() => {
    nodeHotspots.forEach(btn => btn.classList.remove('is-pulsing'));
    routeNodes.forEach(node => node.classList.remove('selected-node'));
  }, 930);
}

function closePanel({ returnFocus = false } = {}) {
  clearTimeout(openTimer);
  clearTimeout(pulseTimer);
  panel.classList.remove('open');
  clearSelectionVisuals();
  updateAria(false);

  if (returnFocus && selectedControl) selectedControl.focus();
}

stationButtons.forEach(button => {
  button.addEventListener('click', () => openLocation(button.dataset.location, button));
});
nodeHotspots.forEach(button => {
  button.addEventListener('click', () => openLocation(button.dataset.location, button));
});
watchButtons.forEach(button => {
  button.addEventListener('click', () => openLocation(button.dataset.location, button));
});

closeButton.addEventListener('click', () => closePanel({ returnFocus: true }));

document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && panel.classList.contains('open')) {
    closePanel({ returnFocus: true });
  }
});

updateAria(false);

/* V4: 지도 크기에 맞춰 우측 상세 패널 전체를 동일 비율로 축소한다.
   내부 텍스트/행 높이를 따로 줄이지 않기 때문에 원본 비율이 유지되고,
   map-wrap의 overflow:hidden에도 패널 하단이 잘리지 않는다. */
const watchStripForScale = document.querySelector('.watch-strip');

function fitDetailPanelToMap() {
  if (!mapWrap || !panel) return;

  // transform 적용 전 레이아웃 기준 크기
  const mapWidth = mapWrap.clientWidth;
  const mapHeight = mapWrap.clientHeight;
  const panelHeight = panel.offsetHeight;
  const watchHeight = watchStripForScale ? watchStripForScale.offsetHeight : 0;

  if (!mapWidth || !mapHeight || !panelHeight) return;

  // 원본 지도 1606px 기준 가로 스케일 + 하단 감시지점 영역을 제외한 세로 스케일 중 작은 값 사용
  const widthScale = mapWidth / 1606;
  const topGap = mapWidth <= 560 ? 6 : mapWidth <= 900 ? 8 : 10;
  const bottomReserve = Math.max(10, watchHeight + 12);
  const usableHeight = Math.max(1, mapHeight - topGap - bottomReserve);
  const heightScale = usableHeight / panelHeight;

  const scale = Math.max(0.28, Math.min(1, widthScale, heightScale));
  mapWrap.style.setProperty('--detail-scale', scale.toFixed(4));
}

fitDetailPanelToMap();
window.addEventListener('resize', fitDetailPanelToMap, { passive: true });
if ('ResizeObserver' in window) {
  const detailResizeObserver = new ResizeObserver(fitDetailPanelToMap);
  detailResizeObserver.observe(mapWrap);
  detailResizeObserver.observe(panel);
}

// 패널이 열리기 직전에도 최신 지도 크기로 다시 계산
const originalOpenLocationV4 = openLocation;
openLocation = function(name, control) {
  fitDetailPanelToMap();
  originalOpenLocationV4(name, control);
  requestAnimationFrame(fitDetailPanelToMap);
};
document.querySelectorAll('.nav-item').forEach(function(item){
  item.addEventListener('click',function(){
    const keyMap={'대시보드':'dashboard','설비관리':'systems','장애관리':'faults','성능관리':'performance','연동관리':'cycle','보고서':'reports','운영관리':'users','설정':'settings'};
    const label=(item.querySelector('span:last-child')||item).textContent.trim();
    parent.postMessage({source:'tnms-planner',type:'navigate',key:keyMap[label]||'dashboard'},location.origin);
  });
});

function dashboardStatusClass(code) {
  if (code === 'CRITICAL') return 'danger';
  if (code === 'CAUTION' || code === 'WARNING') return 'warn';
  if (code === 'OFFLINE' || code === 'UNKNOWN' || code === 'NO_DATA') return 'off';
  return 'success';
}
function normalizeStatusCode(code){
  if (code === 'WARNING') return 'CAUTION';
  if (code === 'OFFLINE' || code === 'NO_DATA') return 'UNKNOWN';
  return code;
}
function applyStatusClass(control, statusCode, fixedMnls){
  control.classList.remove('db-normal','db-warning','db-critical','db-offline','db-unknown','db-mnls');
  if (fixedMnls) {
    control.classList.add('db-mnls');
    return;
  }
  const code = normalizeStatusCode(statusCode);
  control.classList.add(code === 'CRITICAL' ? 'db-critical' : code === 'CAUTION' ? 'db-warning' : code === 'UNKNOWN' || code === 'NO_DATA' ? 'db-unknown' : 'db-normal');
}
function applyRouteStatus(name, statusCode){
  const code = normalizeStatusCode(statusCode);
  routeNodes.filter(node => node.dataset.node === name).forEach(function(node){
    node.classList.remove('db-normal','db-warning','db-critical','db-offline','db-unknown');
    node.classList.add(code === 'CRITICAL' ? 'db-critical' : code === 'CAUTION' ? 'db-warning' : code === 'UNKNOWN' || code === 'NO_DATA' ? 'db-unknown' : 'db-normal');
  });
}
const dashboardPalette={
  NORMAL:{label:'정상',color:'#10A05D'},CAUTION:{label:'주의',color:'#FF9418'},
  CRITICAL:{label:'장애',color:'#FF2B22'},UNKNOWN:{label:'통신단절',color:'#718096'}
};
function hexToRgba(hex,alpha){
  const value=String(hex||'').replace('#','');
  if(!/^[0-9a-f]{6}$/i.test(value))return `rgba(113,128,150,${alpha})`;
  const n=parseInt(value,16);
  return `rgba(${(n>>16)&255},${(n>>8)&255},${n&255},${alpha})`;
}
function setStatusSoftColors(root){
  [['normal','NORMAL'],['warning','CAUTION'],['critical','CRITICAL'],['unknown','UNKNOWN']].forEach(function(pair){
    const color=dashboardPalette[pair[1]].color;
    root.setProperty(`--${pair[0]}-color`,color);
    root.setProperty(`--${pair[0]}-soft`,hexToRgba(color,.07));
    root.setProperty(`--${pair[0]}-chip`,hexToRgba(color,.13));
    root.setProperty(`--${pair[0]}-border`,hexToRgba(color,.32));
  });
}
function applyDashboardPalette(items){
  const hasCaution=(items||[]).some(item=>item.comCd==='CAUTION');
  (items||[]).forEach(function(item){
    if(item.comCd==='WARNING' && hasCaution)return;
    const code=normalizeStatusCode(item.comCd);
    if(!dashboardPalette[code])return;
    if(/^#[0-9a-f]{6}$/i.test(item.ext1Cn||''))dashboardPalette[code].color=item.ext1Cn.toUpperCase();
    if(item.comCdNm)dashboardPalette[code].label=item.comCdNm;
  });
  const root=document.documentElement.style;
  root.setProperty('--green',dashboardPalette.NORMAL.color);
  root.setProperty('--orange',dashboardPalette.CAUTION.color);
  root.setProperty('--red',dashboardPalette.CRITICAL.color);
  root.setProperty('--unknown',dashboardPalette.UNKNOWN.color);
  setStatusSoftColors(root);
  const legend=document.querySelector('.legend');
  if(legend){
    const ordered=(items||[])
      .filter(x=>!(x.comCd==='WARNING' && hasCaution))
      .map(x=>normalizeStatusCode(x.comCd))
      .filter((code,index,list)=>dashboardPalette[code]&&list.indexOf(code)===index);
    const codes=ordered.length?ordered:['CRITICAL','CAUTION','NORMAL','UNKNOWN'];
    legend.innerHTML=codes.map(code=>`<span><i class="dot" style="background:${dashboardPalette[code].color}"></i>${dashboardPalette[code].label}</span>`).join('');
  }
}
function applyDashboardData(data) {
  window.TNMS_DASHBOARD_DATA = data || {systems:[],stations:[]};
  applyDashboardPalette(window.TNMS_DASHBOARD_DATA.statusCodes);
  (window.TNMS_DASHBOARD_DATA.systems || []).forEach(function(item){
    const card=document.querySelector('[data-system-code="'+item.linkSysCd+'"]');
    if (!card) return;
    const total=card.querySelector('strong'), urgent=card.querySelector('.urgent');
    if(total) total.textContent=String(item.totalNocs || 0).padStart(3,'0');
    if(urgent) urgent.textContent='긴급 '+String(item.criticalNocs || 0).padStart(2,'0');
  });
  (window.TNMS_DASHBOARD_DATA.stations || []).forEach(function(item){
    const controls=[...stationButtons,...watchButtons].filter(x=>x.dataset.location===item.stnNm);
    controls.forEach(function(control){
      const fixedMnls = item.mnlsStnYn === 'Y' && control.classList.contains('watch-chip');
      applyStatusClass(control, item.sttsCd, fixedMnls);
    });
    if (item.mnlsStnYn !== 'Y') applyRouteStatus(item.stnNm, item.sttsCd);
  });
}
function applyStationDetail(items) {
  const rows=[...document.querySelectorAll('.system-list .system-row')];
  const order=['EMS_TX','EMS_PIDS','SCADA_SEC','PBX','VMS'];
  rows.forEach(function(row,index){
    const item=(items||[]).find(x=>x.linkSysCd===order[index]);
    if(!item)return;
    row.classList.remove('danger','warn','success','off');
    row.classList.add(dashboardStatusClass(item.sttsCd));
    const small=row.querySelector('small'), em=row.querySelector('em');
    if(small)small.textContent='등록 '+(item.totalNocs||0)+' · '+dashboardPalette.NORMAL.label+' '+(item.normalNocs||0)+' · '+dashboardPalette.CAUTION.label+' '+(item.cautionNocs||0)+' · '+dashboardPalette.CRITICAL.label+' '+(item.criticalNocs||0)+' · '+dashboardPalette.UNKNOWN.label+' '+(item.unknownNocs||0);
    if(em){const code=normalizeStatusCode(item.sttsCd);em.textContent=(dashboardPalette[code]||dashboardPalette.NORMAL).label}
  });
}
window.addEventListener('message',function(event){
  if(event.origin!==location.origin||!event.data||event.data.source!=='tnms-shell')return;
  if(event.data.type==='dashboard-state'){
    document.body.classList.toggle('dashboard-expanded',event.data.mode==='expanded');
    if(event.data.data)applyDashboardData(event.data.data);
  }
  if(event.data.type==='station-detail')applyStationDetail(event.data.data);
});
