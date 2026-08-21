<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="ko">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>AREX TNMS 로그인</title>
    <style>
        *{box-sizing:border-box}html,body{height:100%}body{margin:0;font-family:"Malgun Gothic","Noto Sans KR",sans-serif;background:radial-gradient(circle at 72% 12%,#173653 0,#091523 38%,#06101c 75%);color:#e8f1fb;display:grid;place-items:center}.login-wrap{width:min(430px,calc(100vw - 32px));background:linear-gradient(180deg,#0c1e30f2,#091827f2);border:1px solid #29455d;border-radius:18px;padding:36px;box-shadow:0 24px 60px #02081399}.brand{display:flex;align-items:center;gap:14px;margin-bottom:30px}.logo{width:54px;height:46px;display:grid;place-items:center;border-radius:12px;background:linear-gradient(135deg,#1dc4dc,#1378ec);font-size:24px;font-weight:800}.brand b{font-size:23px}.brand small{display:block;color:#7892ad;margin-top:4px}.label{display:block;color:#91a9bd;font-size:13px;margin:16px 0 7px}.input{width:100%;height:46px;border:1px solid #2b465f;border-radius:8px;background:#0b1e30;color:#e7f2fb;padding:0 13px;font-size:14px;outline:none}.input:focus{border-color:#27b9da;box-shadow:0 0 0 3px #1bb4d31c}.button{width:100%;height:46px;border:0;border-radius:8px;margin-top:24px;background:linear-gradient(135deg,#1689e9,#16b4d3);color:#fff;font-size:14px;font-weight:700;cursor:pointer}.message{min-height:21px;margin-top:14px;color:#ff8d9d;font-size:13px;text-align:center}.note{border-top:1px solid #20384e;margin-top:24px;padding-top:16px;color:#657f98;font-size:12px;text-align:center;line-height:1.6}
    </style>
</head>
<body>
<main class="login-wrap">
    <div class="brand"><div class="logo">A</div><div><b>AREX TNMS</b><small>통합 네트워크 관리시스템</small></div></div>
    <form id="loginForm">
        <label class="label" for="userId">사용자 아이디</label>
        <input class="input" id="userId" name="userId" autocomplete="username" maxlength="20" required>
        <label class="label" for="password">비밀번호</label>
        <input class="input" id="password" name="password" type="password" autocomplete="current-password" maxlength="20" required>
        <button class="button" id="loginButton" type="submit">로그인</button>
        <div class="message" id="message"></div>
    </form>
    <div class="note">로그인 실패 5회 시 계정이 잠깁니다.<br>계정 잠금은 시스템 관리자에게 문의해 주세요.</div>
</main>
<script>
const contextPath='<%=request.getContextPath()%>';
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
