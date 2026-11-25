(function (global) {
  'use strict';

  var state = {items: [], category: 'ALL', readFilter: 'ALL', sort: 'DESC', expanded: false};

  function isRead(item) { return item && item.readYn === 'Y'; }
  async function markRead(item) {
    if (!item || !item.notificationId || isRead(item)) return;
    await global.api('/notification/read.ajax', {
      method: 'POST',
      body: new URLSearchParams({notificationId: item.notificationId})
    });
    item.readYn = 'Y';
    item.readDt = new Date().toISOString();
    updateBadge();
  }
  async function markAllRead() {
    try {
      await global.api('/notification/read-all.ajax', {method:'POST', body:new URLSearchParams()});
      state.items.forEach(function (item) { item.readYn = 'Y'; });
      renderPanel();
      updateBadge();
      if (global.showToast) global.showToast('전체 알림을 읽음 처리했습니다.');
    } catch (e) {
      if (global.showToast) global.showToast(e.message || '전체 읽음 처리에 실패했습니다.', true);
    }
  }
  function categoryLabel(code) {
    return {ALL:'전체',FAULT:'고장',ACCOUNT:'계정신청',OPERATION:'운영관리',SETTING:'설정'}[code] || code;
  }
  function severityClass(code) {
    if (code === 'CRITICAL' || code === 'EMERGENCY' || code === 'HIGH') return 'critical';
    if (code === 'CAUTION' || code === 'WARNING' || code === 'MEDIUM') return 'caution';
    return 'normal';
  }
  function filtered() {
    var list = state.items.slice().filter(function (item) {
      if (state.category !== 'ALL' && item.categoryCd !== state.category) return false;
      var read = isRead(item);
      if (state.readFilter === 'UNREAD' && read) return false;
      if (state.readFilter === 'READ' && !read) return false;
      return true;
    });
    list.sort(function (a, b) {
      var av = String(a.eventDt || ''), bv = String(b.eventDt || '');
      return state.sort === 'ASC' ? av.localeCompare(bv) : bv.localeCompare(av);
    });
    return list;
  }
  function updateBadge() {
    var badge = document.getElementById('notificationBadge');
    if (!badge) return;
    var count = state.items.filter(function (item) { return !isRead(item); }).length;
    badge.hidden = count === 0;
    badge.textContent = count > 99 ? '99+' : String(count);
  }
  function countByCategory(code) {
    return state.items.filter(function (item) { return code === 'ALL' || item.categoryCd === code; }).length;
  }
  function panelShell() {
    var old = document.getElementById('notificationLayer');
    if (old) return old;
    var layer = document.createElement('div');
    layer.id = 'notificationLayer';
    layer.className = 'notification-layer';
    layer.innerHTML = '<div class="notification-dim" data-notification-close></div><aside class="notification-panel" id="notificationPanel" aria-label="알림"><div id="notificationPanelBody"></div></aside>';
    layer.addEventListener('click', function (event) {
      if (event.target.hasAttribute('data-notification-close')) closePanel();
    });
    document.body.appendChild(layer);
    return layer;
  }
  function renderPanel() {
    var layer = panelShell();
    layer.classList.toggle('expanded', state.expanded);
    var body = document.getElementById('notificationPanelBody');
    if (!body) return;
    var categories = ['ALL','FAULT','ACCOUNT','OPERATION','SETTING'];
    var list = filtered();
    var unread = state.items.filter(function (item) { return !isRead(item); }).length;
    body.innerHTML = ''+
      '<div class="notification-head"><div><h2>알림 <span>'+state.items.length+'</span></h2><p>장애·계정신청·운영/설정 작업 알림을 확인합니다.</p></div><button type="button" class="notification-close" data-notification-close aria-label="닫기">×</button></div>'+
      '<div class="notification-category-tabs">'+categories.map(function (code) {
        return '<button type="button" data-noti-category="'+code+'" class="'+(state.category===code?'active':'')+'">'+categoryLabel(code)+' <em>'+countByCategory(code)+'</em></button>';
      }).join('')+'</div>'+
      '<div class="notification-toolbar"><div class="notification-read-tabs">'+
        '<button data-noti-read="ALL" class="'+(state.readFilter==='ALL'?'active':'')+'">전체</button>'+
        '<button data-noti-read="UNREAD" class="'+(state.readFilter==='UNREAD'?'active':'')+'">안읽음 <b>'+unread+'</b></button>'+
        '<button data-noti-read="READ" class="'+(state.readFilter==='READ'?'active':'')+'">읽음</button></div>'+
        '<select id="notificationSort"><option value="DESC" '+(state.sort==='DESC'?'selected':'')+'>최신순</option><option value="ASC" '+(state.sort==='ASC'?'selected':'')+'>오래된순</option></select></div>'+
      '<div class="notification-list">'+(list.length ? list.map(function (item) {
        var read = isRead(item);
        var id = encodeURIComponent(String(item.notificationId || ''));
        return '<button type="button" class="notification-item '+(read?'read ':'')+severityClass(item.severityCd)+'" data-noti-id="'+id+'">'+
          '<span class="notification-unread-dot"></span><span class="notification-kind">'+global.escapeHtml(item.categoryNm || categoryLabel(item.categoryCd))+'</span>'+
          '<strong>'+global.escapeHtml(item.title || '알림')+'</strong><span class="notification-message">'+global.escapeHtml(item.message || '-')+'</span>'+
          '<span class="notification-meta"><i>'+global.escapeHtml(item.sourceName || 'TNMS')+'</i><time>'+global.escapeHtml(item.eventDt || '-')+'</time></span></button>';
      }).join('') : '<div class="notification-empty">조건에 맞는 알림이 없습니다.</div>')+'</div>'+
      '<div class="notification-footer"><button type="button" class="btn" id="notificationReadAll">전체 읽음 처리</button><button type="button" class="btn primary" id="notificationExpand">'+(state.expanded?'간단히 보기':'전체 알림 보기')+'</button></div>';

    body.querySelectorAll('[data-notification-close]').forEach(function (el) { el.addEventListener('click', closePanel); });
    body.querySelectorAll('[data-noti-category]').forEach(function (el) { el.addEventListener('click', function () { state.category = el.dataset.notiCategory; renderPanel(); }); });
    body.querySelectorAll('[data-noti-read]').forEach(function (el) { el.addEventListener('click', function () { state.readFilter = el.dataset.notiRead; renderPanel(); }); });
    var sort = body.querySelector('#notificationSort');
    if (sort) sort.addEventListener('change', function () { state.sort = sort.value; renderPanel(); });
    var readAll = body.querySelector('#notificationReadAll');
    if (readAll) readAll.addEventListener('click', markAllRead);
    var expand = body.querySelector('#notificationExpand');
    if (expand) expand.addEventListener('click', function () { state.expanded = !state.expanded; renderPanel(); });
    body.querySelectorAll('[data-noti-id]').forEach(function (el) {
      el.addEventListener('click', async function () {
        var decoded = decodeURIComponent(el.dataset.notiId || '');
        var item = state.items.find(function (x) { return String(x.notificationId || '') === decoded; });
        if (!item) return;
        try { await markRead(item); } catch (e) { if (global.showToast) global.showToast(e.message, true); return; }
        el.classList.add('read');
        if (item.targetUrl) location.href = global.CONTEXT_PATH + item.targetUrl;
      });
    });
  }
  function openPanel() {
    renderPanel();
    var layer = document.getElementById('notificationLayer');
    if (layer) layer.classList.add('open');
    document.body.classList.add('notification-open');
    var trigger = document.getElementById('notificationTrigger');
    if (trigger) trigger.setAttribute('aria-expanded', 'true');
  }
  function closePanel() {
    var layer = document.getElementById('notificationLayer');
    if (layer) layer.classList.remove('open');
    document.body.classList.remove('notification-open');
    var trigger = document.getElementById('notificationTrigger');
    if (trigger) trigger.setAttribute('aria-expanded', 'false');
  }
  async function loadNotifications() {
    try {
      state.items = (await global.api('/notification/list.ajax')) || [];
      updateBadge();
    } catch (e) {
      state.items = [];
      updateBadge();
    }
  }
  document.addEventListener('DOMContentLoaded', function () {
    var trigger = document.getElementById('notificationTrigger');
    if (!trigger) return;
    trigger.addEventListener('click', function () {
      var layer = document.getElementById('notificationLayer');
      if (layer && layer.classList.contains('open')) closePanel(); else openPanel();
    });
    document.addEventListener('keydown', function (event) { if (event.key === 'Escape') closePanel(); });
    setTimeout(loadNotifications, 150);
    setInterval(loadNotifications, 60000);
  });
})(window);
