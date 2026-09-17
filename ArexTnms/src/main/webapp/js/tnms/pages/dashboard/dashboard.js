const DASHBOARD_ASSET_VERSION = '20260917.1';
let DASHBOARD_DATA = null;
let DASHBOARD_MODE = localStorage.getItem('tnmsDashboardMode') === 'expanded' ? 'expanded' : 'basic';

function dashboardAsset(path) { return CONTEXT_PATH + path + '?v=' + DASHBOARD_ASSET_VERSION; }
function sendDashboardState(frame) {
  if (!frame || !frame.contentWindow) return;
  frame.contentWindow.postMessage({source:'tnms-shell',type:'dashboard-state',mode:DASHBOARD_MODE,data:DASHBOARD_DATA}, location.origin);
}
function prepareDashboardFrame(frame) {
  try {
    const doc = frame.contentDocument || (frame.contentWindow && frame.contentWindow.document);
    if (!doc || !doc.body) return;
    doc.body.classList.add('embedded-dashboard');
    if (!doc.getElementById('tnms-embed-guard')) {
      const guard = doc.createElement('style');
      guard.id = 'tnms-embed-guard';
      guard.textContent = 'html,body{width:100%;height:100%;min-height:0}body>.app-shell{height:100%;min-height:0;padding:0!important}body .sidebar,body .topbar{display:none!important}body.dashboard-expanded .analytics-grid,body.dashboard-expanded .page-dots{display:none!important}body.dashboard-expanded .dashboard{grid-template-rows:auto minmax(0,1fr)!important}';
      doc.head.appendChild(guard);
    }
    sendDashboardState(frame);
  } catch (error) { console.warn('대시보드 본문 모드 적용 실패', error); }
}
function updateModeButtons() {
  document.querySelectorAll('[data-dashboard-mode]').forEach(function(button){
    const active=button.dataset.dashboardMode===DASHBOARD_MODE;
    button.classList.toggle('active',active);
    button.setAttribute('aria-pressed',String(active));
  });
}
function setDashboardMode(mode) {
  DASHBOARD_MODE = mode === 'expanded' ? 'expanded' : 'basic';
  localStorage.setItem('tnmsDashboardMode', DASHBOARD_MODE);
  updateModeButtons();
  sendDashboardState(document.getElementById('plannerDashboardFrame'));
}
function setDashboardSlide(index) {
  const frame = document.getElementById('plannerDashboardFrame');
  if (frame) frame.src = dashboardAsset(index === 0 ? '/css/tnms/planner-dashboard-map/index.html' : '/css/tnms/planner-dashboard-system/index.html');
}
window.addEventListener('message', function (event) {
  if (event.origin !== location.origin || !event.data || event.data.source !== 'tnms-planner') return;
  if (event.data.type === 'dashboard-slide') setDashboardSlide(Number(event.data.index) || 0);
  if (event.data.type === 'navigate' && event.data.key && window.TNMS_PAGE_URLS[event.data.key]) location.href = CONTEXT_PATH + window.TNMS_PAGE_URLS[event.data.key];
  if (event.data.type === 'station-detail' && event.data.stnCd) {
    api('/main/dashboard-station.ajax?stnCd='+encodeURIComponent(event.data.stnCd)).then(function(data){
      const frame=document.getElementById('plannerDashboardFrame');
      if(frame&&frame.contentWindow)frame.contentWindow.postMessage({source:'tnms-shell',type:'station-detail',stnCd:event.data.stnCd,data:data},location.origin);
    }).catch(function(error){showToast(error.message,true)});
  }
  if (event.data.type === 'system-stations' && event.data.linkSysCd) {
    api('/facility/data.ajax?linkSysCd='+encodeURIComponent(event.data.linkSysCd)).then(function(data){
      const frame=document.getElementById('plannerDashboardFrame');
      if(frame&&frame.contentWindow)frame.contentWindow.postMessage({source:'tnms-shell',type:'system-stations',linkSysCd:event.data.linkSysCd,data:data.stations||[]},location.origin);
    }).catch(function(error){showToast(error.message,true)});
  }
});
window.TNMS_PAGE_INIT = async function () {
  const html = '<div class="dashboard-embed-shell"><iframe id="plannerDashboardFrame" class="planner-dashboard-frame" '
    + 'src="' + dashboardAsset('/css/tnms/planner-dashboard-map/index.html') + '" title="TNMS 통합 대시보드"></iframe></div>';
  renderPage('dashboard', html);
  updateModeButtons();
  const frame = document.getElementById('plannerDashboardFrame');
  if (frame) frame.addEventListener('load', function () { prepareDashboardFrame(frame); });
  try { DASHBOARD_DATA = await api('/main/dashboard-data.ajax'); sendDashboardState(frame); }
  catch (error) { showToast(error.message, true); }
};
