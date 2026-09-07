
(function (global) {
  const config = global.TNMS_CONFIG || {};
  global.CONTEXT_PATH = config.contextPath || '';
  global.CSRF_TOKEN = '';
  global.PERMISSIONS = {};
  global.CURRENT_USER = {userNm: '사용자'};

  global.escapeHtml = function (value) {
    return String(value == null ? '' : value).replace(/[&<>'"]/g, function (ch) {
      return {'&': '&amp;', '<': '&lt;', '>': '&gt;', "'": '&#39;', '"': '&quot;'}[ch];
    });
  };

  global.hasPermission = function (screen, property) {
    const permission = global.PERMISSIONS[screen];
    return !!permission && permission[property || 'listAuthrtYn'] === 'Y';
  };

  global.permissionButton = function (screen, property, label, classes, handler) {
    return global.hasPermission(screen, property)
      ? '<button class="btn ' + (classes || '') + '" onclick="' + handler + '">' + label + '</button>'
      : '';
  };

  global.chip = function (text, type) {
    return '<span class="chip ' + (type || '') + '">' + text + '</span>';
  };

  global.btn = function (text, classes) {
    return '<button class="btn ' + (classes || '') + '">' + text + '</button>';
  };

  global.layout = function (key, body, actions) {
    const actionArea = document.getElementById('pageActions');
    if (actionArea) actionArea.innerHTML = actions || '';
    return body;
  };

  global.renderPage = function (key, html) {
    const body = document.getElementById('pageBody');
    if (!body) return;
    body.innerHTML = html || '';
    global.enhanceTables(body);
  };

  global.api = async function (path, options) {
    options = options || {};
    const headers = Object.assign({'X-Requested-With': 'XMLHttpRequest'}, options.headers || {});
    if (options.method && options.method.toUpperCase() !== 'GET') headers['X-CSRF-TOKEN'] = global.CSRF_TOKEN;
    const response = await fetch(global.CONTEXT_PATH + path, Object.assign({}, options, {headers: headers}));
    let json;
    try {
      json = await response.json();
    } catch (e) {
      json = {success: false, message: '서버 응답을 해석하지 못했습니다.'};
    }
    if (response.status === 401) {
      location.replace(global.CONTEXT_PATH + '/login/login.do');
      throw new Error('로그인이 필요합니다.');
    }
    if (!response.ok || json.success === false) throw new Error(json.message || '요청 처리에 실패했습니다.');
    return json.data;
  };

  global.bootstrapPermissions = async function () {
    const data = await global.api('/auth/myPermissions.ajax');
    global.CURRENT_USER = data.user || global.CURRENT_USER;
    global.PERMISSIONS = data.permissions || {};
    global.CSRF_TOKEN = data.csrfToken || '';
    const userName = document.getElementById('headerUserName');
    if (userName) userName.textContent = global.CURRENT_USER.userNm || global.CURRENT_USER.userId || '사용자';
    return data;
  };

  global.showToast = function (message, bad) {
    const old = document.querySelector('.toast');
    if (old) old.remove();
    const toast = document.createElement('div');
    toast.className = 'toast' + (bad ? ' bad' : '');
    toast.textContent = message;
    document.body.appendChild(toast);
    setTimeout(function () { toast.remove(); }, 2800);
  };

  global.showModal = function (html) {
    const backdrop = document.createElement('div');
    backdrop.className = 'modal-backdrop';
    backdrop.id = 'modalBackdrop';
    backdrop.innerHTML = '<div class="modal-panel">' + html + '</div>';
    backdrop.addEventListener('click', function (event) {
      if (event.target === backdrop) global.closeModal();
    });
    document.body.appendChild(backdrop);
  };

  global.closeModal = function () {
    const backdrop = document.getElementById('modalBackdrop');
    if (backdrop) backdrop.remove();
  };

  global.formatDate = function (value) {
    return value ? String(value).replace('T', ' ').substring(0, 19) : '-';
  };

  global.toggleFullscreen = function () {
    if (!document.fullscreenElement) {
      if (document.documentElement.requestFullscreen) document.documentElement.requestFullscreen();
    } else if (document.exitFullscreen) {
      document.exitFullscreen();
    }
  };

  global.enhanceTables = function (scope) {
    (scope || document).querySelectorAll('table').forEach(function (table) {
      const columns = table.querySelectorAll('tr:first-child > th').length;
      if (columns >= 8) table.classList.add('table-wide-xl');
      else if (columns >= 6) table.classList.add('table-wide');
      if (!table.parentElement.classList.contains('table-scroll')) {
        const scroll = document.createElement('div');
        scroll.className = 'table-scroll';
        table.parentNode.insertBefore(scroll, table);
        scroll.appendChild(table);
      }
    });
  };

  function updateClock() {
    const clock = document.getElementById('headerClock');
    if (!clock) return;
    const now = new Date();
    const date = new Intl.DateTimeFormat('ko-KR', {
      year: 'numeric', month: '2-digit', day: '2-digit', weekday: 'short'
    }).format(now);
    clock.textContent = date + ' ' + String(now.getHours()).padStart(2, '0') + ':'
      + String(now.getMinutes()).padStart(2, '0') + ':' + String(now.getSeconds()).padStart(2, '0');
  }

  function bindShell() {
    document.querySelectorAll('.nav-parent').forEach(function (button) {
      button.addEventListener('click', function () {
        const section = button.closest('.nav-section');
        const open = !section.classList.contains('open');
        section.classList.toggle('open', open);
        button.setAttribute('aria-expanded', String(open));
      });
    });
    document.querySelectorAll('.nav-item.denied').forEach(function (link) {
      link.addEventListener('click', function (event) {
        event.preventDefault();
        global.showToast('해당 화면에 대한 접근 권한이 없습니다.', true);
      });
    });
    const collapse = document.querySelector('.side-collapse');
    if (collapse) collapse.addEventListener('click', function () {
      document.querySelector('.app').classList.toggle('menu-collapsed');
    });
    updateClock();
    setInterval(updateClock, 1000);
  }

  document.addEventListener('DOMContentLoaded', async function () {
    bindShell();
    try {
      await global.bootstrapPermissions();
      if (!global.hasPermission(config.pageKey, 'listAuthrtYn')) {
        global.showToast('해당 화면에 대한 접근 권한이 없습니다.', true);
        return;
      }
      if (typeof global.TNMS_PAGE_INIT === 'function') await global.TNMS_PAGE_INIT();
    } catch (error) {
      global.showToast(error.message || '화면을 초기화하지 못했습니다.', true);
    }
  });
})(window);
