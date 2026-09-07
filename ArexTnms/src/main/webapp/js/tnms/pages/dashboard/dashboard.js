
const DASHBOARD_ASSET_VERSION = '20260904.1';

function dashboardAsset(path) {
  return CONTEXT_PATH + path + '?v=' + DASHBOARD_ASSET_VERSION;
}

function prepareDashboardFrame(frame) {
  try {
    const doc = frame.contentDocument || (frame.contentWindow && frame.contentWindow.document);
    if (!doc || !doc.body) return;
    doc.body.classList.add('embedded-dashboard');
    if (!doc.getElementById('tnms-embed-guard')) {
      const guard = doc.createElement('style');
      guard.id = 'tnms-embed-guard';
      guard.textContent = 'html,body{width:100%;height:100%;min-height:0}body>.app-shell{height:100%;min-height:0;padding:0!important}body .sidebar,body .topbar{display:none!important}';
      doc.head.appendChild(guard);
    }
  } catch (error) {
    console.warn('대시보드 본문 모드 적용 실패', error);
  }
}

function setDashboardSlide(index) {
  const frame = document.getElementById('plannerDashboardFrame');
  if (frame) frame.src = dashboardAsset(index === 0
    ? '/css/tnms/planner-dashboard-map/index.html'
    : '/css/tnms/planner-dashboard-system/index.html');
}

window.addEventListener('message', function (event) {
  if (event.origin !== location.origin || !event.data || event.data.source !== 'tnms-planner') return;
  if (event.data.type === 'dashboard-slide') setDashboardSlide(Number(event.data.index) || 0);
  if (event.data.type === 'navigate' && event.data.key && window.TNMS_PAGE_URLS[event.data.key]) {
    location.href = CONTEXT_PATH + window.TNMS_PAGE_URLS[event.data.key];
  }
});

window.TNMS_PAGE_INIT = function () {
  const html = '<div class="dashboard-embed-shell">'
    + '<iframe id="plannerDashboardFrame" class="planner-dashboard-frame" '
    + 'src="' + dashboardAsset('/css/tnms/planner-dashboard-map/index.html') + '" '
    + 'title="TNMS 통합 대시보드"></iframe></div>';
  renderPage('dashboard', html);
  const frame = document.getElementById('plannerDashboardFrame');
  if (frame) frame.addEventListener('load', function () { prepareDashboardFrame(frame); });
};
