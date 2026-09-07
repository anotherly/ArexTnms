<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover">
  <title>TNMS 2026 - 로그인</title>
  <link rel="stylesheet" href="<%=request.getContextPath()%>/css/tnms/planner-login.css?v=20260902.3">
</head>
<body>
  <main class="screen" aria-label="TNMS 2026 로그인">
    <div class="stage">
      <img class="hero-photo" src="<%=request.getContextPath()%>/images/tnms/planner-login-bg.png" alt="" aria-hidden="true">

      <div class="login-card-shell" id="loginCardShell">
        <section class="login-card" id="loginCard" aria-labelledby="tnms-title">
          <img class="arex-logo" src="<%=request.getContextPath()%>/images/tnms/planner-arex-logo.png" alt="AREX Airport Express">

          <h1 id="tnms-title">TNMS 2026</h1>
          <p class="system-name">통합네트워크 관리시스템</p>
          <p class="system-name-en">Total Network Management System</p>
          <span class="divider" aria-hidden="true"></span>

          <form id="loginForm" class="login-form" novalidate>
            <div class="input-box id-box" id="idFieldBox">
              <label class="sr-only" for="userId">아이디</label>
              <svg class="icon user-svg" viewBox="0 0 18 20" aria-hidden="true">
                <circle cx="9" cy="5" r="4" fill="none" stroke="currentColor" stroke-width="2"/>
                <path d="M1 19C1 14 4 12 9 12C14 12 17 14 17 19" fill="none" stroke="currentColor" stroke-width="2"/>
              </svg>
              <input id="userId" name="userId" type="text" autocomplete="username" placeholder="아이디를 입력하세요" aria-describedby="errorMsg">
            </div>

            <div class="input-box pw-box" id="pwFieldBox">
              <label class="sr-only" for="password">비밀번호</label>
              <svg class="icon lock-svg" viewBox="0 0 16 20" aria-hidden="true">
                <rect x="1" y="8" width="14" height="11" rx="2" fill="none" stroke="currentColor" stroke-width="2"/>
                <path d="M4 8V5C4 2.8 5.8 1 8 1C10.2 1 12 2.8 12 5V8M8 12V15" fill="none" stroke="currentColor" stroke-width="2"/>
              </svg>
              <input id="password" name="password" type="password" autocomplete="current-password" placeholder="비밀번호를 입력하세요" aria-describedby="errorMsg">
              <button class="pw-toggle" id="pwToggle" type="button" aria-label="비밀번호 표시" aria-pressed="false">
                <svg viewBox="0 0 22 18" aria-hidden="true">
                  <path d="M1 9S5 3 11 3S21 9 21 9S17 15 11 15S1 9 1 9Z" fill="none" stroke="currentColor" stroke-width="2"/>
                  <path class="eye-slash" d="M3 1L19 17" fill="none" stroke="currentColor" stroke-width="2"/>
                </svg>
              </button>
            </div>

            <p class="error-msg" id="errorMsg" role="alert" aria-live="polite"></p>

            <button class="login-btn" type="submit">
              <svg class="login-svg" viewBox="0 0 14 16" aria-hidden="true">
                <path d="M6 1H1V15H6M9 12L13 8L9 4M13 8H4" fill="none" stroke="currentColor" stroke-width="2"/>
              </svg>
              <span>로그인</span>
            </button>

            <button class="signup-btn" id="signupBtn" type="button">
              <svg class="signup-svg" viewBox="0 0 22 19" aria-hidden="true">
                <circle cx="7" cy="5" r="3.5" fill="none" stroke="currentColor" stroke-width="2"/>
                <path d="M1 17C1 13 3 11 7 11M17 10V18M13 14H21" fill="none" stroke="currentColor" stroke-width="2"/>
              </svg>
              <span>계정신청</span>
            </button>
          </form>
        </section>
      </div>
    </div>
  </main>

  <script>
    const contextPath = '<%=request.getContextPath()%>';
    const loginForm = document.getElementById('loginForm');
    const passwordInput = document.getElementById('password');
    const passwordToggle = document.getElementById('pwToggle');
    const errorMessage = document.getElementById('errorMsg');
    const loginButton = loginForm.querySelector('.login-btn');
    const loginCardShell = document.getElementById('loginCardShell');
    const loginCard = document.getElementById('loginCard');

    function fitLoginCard() {
      const scale = Math.min(loginCardShell.clientWidth / 625, loginCardShell.clientHeight / 890);
      loginCard.style.setProperty('--card-scale', String(scale));
    }

    fitLoginCard();
    window.addEventListener('resize', fitLoginCard, {passive:true});
    if ('ResizeObserver' in window) new ResizeObserver(fitLoginCard).observe(loginCardShell);

    passwordToggle.addEventListener('click', function () {
      const show = passwordInput.type === 'password';
      passwordInput.type = show ? 'text' : 'password';
      passwordToggle.classList.toggle('is-visible', show);
      passwordToggle.setAttribute('aria-pressed', String(show));
      passwordToggle.setAttribute('aria-label', show ? '비밀번호 숨기기' : '비밀번호 표시');
    });

    document.getElementById('signupBtn').addEventListener('click', function () {
      location.href = contextPath + '/login/account-application.do';
    });

    loginForm.addEventListener('submit', async function (event) {
      event.preventDefault();
      if (!loginForm.userId.value.trim() || !loginForm.password.value) {
        errorMessage.textContent = '아이디와 비밀번호를 입력해 주세요';
        return;
      }
      loginButton.disabled = true;
      errorMessage.textContent = '';
      try {
        const response = await fetch(contextPath + '/login/loginPost.do', {
          method: 'POST',
          headers: {'Content-Type':'application/x-www-form-urlencoded;charset=UTF-8','X-Requested-With':'XMLHttpRequest'},
          body: new URLSearchParams(new FormData(loginForm))
        });
        const result = await response.json();
        if (!result.success) throw new Error(result.message || '아이디와 비밀번호를 확인해 주세요');
        location.replace(result.url);
      } catch (error) {
        errorMessage.textContent = error.message || '아이디와 비밀번호를 확인해 주세요';
        loginButton.disabled = false;
      }
    });
  </script>
</body>
</html>
