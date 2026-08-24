<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AREX TNMS 로그인</title>
    <style>
        @font-face{font-family:Pretendard;src:url('<%=request.getContextPath()%>/fonts/tnms/PretendardVariable.woff2') format('woff2-variations');font-style:normal;font-weight:45 920;font-display:swap}
        :root{--navy:#0b213f;--blue:#1264db;--line:#d8e0ea;--muted:#8995a7}
        *{box-sizing:border-box}
        html,body{width:100%;height:100%}
        body{margin:0;font-family:Pretendard,-apple-system,BlinkMacSystemFont,"Segoe UI",sans-serif;color:var(--navy);background:#eaf2f9;overflow:hidden}
        button,input{font:inherit}
        .login-page{position:relative;width:100%;height:100%;min-height:620px;display:grid;grid-template-columns:minmax(0,61%) minmax(430px,39%);overflow:hidden}
        .login-visual{position:relative;min-width:0;background:#9dd1f5 url('<%=request.getContextPath()%>/images/tnms/login-airport.jpg') center/cover no-repeat}
        .login-visual:after{content:"";position:absolute;inset:0;background:linear-gradient(90deg,transparent 72%,rgba(255,255,255,.18))}
        .login-side{position:relative;display:grid;place-items:center;padding:36px;background:linear-gradient(180deg,rgba(250,252,255,.62),rgba(255,255,255,.82));backdrop-filter:blur(6px)}
        .login-card{width:min(430px,100%);padding:44px 38px 38px;border:1px solid rgba(214,222,232,.9);border-radius:20px;background:rgba(255,255,255,.92);box-shadow:0 24px 70px rgba(12,45,82,.14)}
        .brand{text-align:center;margin-bottom:28px}
        .brand img{display:block;width:210px;height:auto;margin:0 auto 13px}
        .brand h1{margin:0;color:#13243b;font-size:27px;line-height:1.2;letter-spacing:.2px}
        .brand strong{display:block;margin-top:10px;font-size:14px}
        .brand small{display:block;margin-top:8px;color:#9aa4b2;font-size:11px}
        .divider{width:34px;height:1px;margin:18px auto 22px;background:#e5e9ef}
        .field{position:relative;margin-bottom:13px}
        .field svg{position:absolute;left:15px;top:50%;width:18px;height:18px;transform:translateY(-50%);stroke:#1b2635;fill:none;stroke-width:1.8}
        .field input{width:100%;height:52px;padding:0 48px;border:1px solid #d6dde7;border-radius:7px;background:#fff;color:#14243a;font-size:13px;outline:none;transition:.2s}
        .field input::placeholder{color:#9aa5b3}
        .field input:focus{border-color:#1768dc;box-shadow:0 0 0 3px rgba(23,104,220,.10)}
        .password-toggle{position:absolute;right:10px;top:50%;width:38px;height:38px;transform:translateY(-50%);border:0;background:transparent;color:#172438;cursor:pointer;display:grid;place-items:center}
        .password-toggle svg{position:static;transform:none}
        .button{width:100%;height:51px;border-radius:7px;font-size:14px;font-weight:700;cursor:pointer;transition:.18s}
        .button:disabled{opacity:.65;cursor:wait}
        .button-primary{margin-top:7px;border:1px solid #1264db;background:#1264db;color:#fff;box-shadow:0 8px 20px rgba(18,100,219,.18)}
        .button-primary:hover{background:#0e56c2}
        .button-secondary{margin-top:13px;border:1px solid #1470cf;background:#fff;color:#0757a9}
        .button-secondary:hover{background:#f5f9ff}
        .button-icon{display:inline-flex;align-items:center;justify-content:center;gap:11px}
        .button-icon svg{width:17px;height:17px;stroke:currentColor;fill:none;stroke-width:1.8}
        .message{min-height:20px;margin:12px 0 -2px;color:#e33d4e;font-size:12px;text-align:center}
        .security-note{margin:21px 0 0;color:#8d98a7;font-size:11px;line-height:1.65;text-align:center}
        @media(max-width:900px){
            body{overflow:auto}.login-page{min-height:100%;display:block}.login-visual{position:fixed;inset:0;background-position:30% center;background-size:auto 100%}.login-visual:after{background:rgba(4,29,62,.28)}
            .login-side{min-height:100vh;padding:24px;background:transparent}.login-card{width:min(430px,100%);background:rgba(255,255,255,.95)}
        }
        @media(max-height:700px) and (min-width:901px){.login-card{padding:28px 34px}.brand{margin-bottom:16px}.brand img{width:180px;margin-bottom:7px}.brand h1{font-size:23px}.divider{margin:12px auto 16px}.field input,.button{height:46px}.security-note{margin-top:12px}}
    </style>
</head>
<body>
<main class="login-page">
    <section class="login-visual" aria-label="공항철도 전경"></section>
    <section class="login-side">
        <div class="login-card">
            <div class="brand">
                <img src="<%=request.getContextPath()%>/images/tnms/arex-logo-color.png" alt="AREX Airport Express">
                <h1>TNMS 2026</h1>
                <strong>통합네트워크 관리시스템</strong>
                <small>Total Network Management System</small>
            </div>
            <div class="divider"></div>
            <form id="loginForm">
                <div class="field">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><circle cx="12" cy="8" r="3.5"></circle><path d="M5.5 20c.5-4 2.6-6 6.5-6s6 2 6.5 6"></path></svg>
                    <input id="userId" name="userId" autocomplete="username" maxlength="20" placeholder="아이디를 입력하세요" aria-label="아이디" required autofocus>
                </div>
                <div class="field">
                    <svg viewBox="0 0 24 24" aria-hidden="true"><rect x="5" y="10" width="14" height="11" rx="2"></rect><path d="M8 10V7a4 4 0 0 1 8 0v3"></path></svg>
                    <input id="password" name="password" type="password" autocomplete="current-password" maxlength="20" placeholder="비밀번호를 입력하세요" aria-label="비밀번호" required>
                    <button class="password-toggle" id="passwordToggle" type="button" aria-label="비밀번호 표시">
                        <svg viewBox="0 0 24 24"><path d="M2.5 12s3.5-6 9.5-6 9.5 6 9.5 6-3.5 6-9.5 6-9.5-6-9.5-6z"></path><circle cx="12" cy="12" r="2.5"></circle></svg>
                    </button>
                </div>
                <button class="button button-primary button-icon" id="loginButton" type="submit">
                    <svg viewBox="0 0 24 24"><path d="M10 17l5-5-5-5M15 12H3"></path><path d="M14 4h6v16h-6"></path></svg>
                    로그인
                </button>
                <button class="button button-secondary button-icon" id="accountApplyButton" type="button">
                    <svg viewBox="0 0 24 24"><circle cx="9" cy="8" r="3"></circle><path d="M3.5 19c.5-3.5 2.4-5.3 5.5-5.3 1.2 0 2.2.2 3 .7M17 11v7M13.5 14.5h7"></path></svg>
                    계정신청
                </button>
                <div class="message" id="message" role="alert"></div>
            </form>
            <p class="security-note">로그인 실패 5회 시 계정이 잠깁니다.<br>계정 잠금은 시스템 관리자에게 문의해 주세요.</p>
        </div>
    </section>
</main>
<script>
const contextPath='<%=request.getContextPath()%>';
const password=document.getElementById('password');
document.getElementById('passwordToggle').addEventListener('click',function(){
    const show=password.type==='password';
    password.type=show?'text':'password';
    this.setAttribute('aria-label',show?'비밀번호 숨기기':'비밀번호 표시');
});
document.getElementById('accountApplyButton').addEventListener('click',function(){
    document.getElementById('message').textContent='계정신청 기능은 발주처 협의 후 제공될 예정입니다.';
});
document.getElementById('loginForm').addEventListener('submit',async function(e){
    e.preventDefault();
    const button=document.getElementById('loginButton'),message=document.getElementById('message');
    button.disabled=true;message.textContent='';
    try{
        const response=await fetch(contextPath+'/login/loginPost.do',{method:'POST',headers:{'Content-Type':'application/x-www-form-urlencoded;charset=UTF-8','X-Requested-With':'XMLHttpRequest'},body:new URLSearchParams(new FormData(e.target))});
        const json=await response.json();
        if(!json.success)throw new Error(json.message||'로그인에 실패했습니다.');
        location.replace(json.url);
    }catch(error){message.textContent=error.message;button.disabled=false;}
});
</script>
</body>
</html>
