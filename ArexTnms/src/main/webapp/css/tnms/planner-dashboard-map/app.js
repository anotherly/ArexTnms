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
  return '전체 시스템 5 · 정상 3 · 주의 1 · 장애 1';
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
