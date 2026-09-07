<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<!doctype html>
<html lang="ko">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>TNMS 2026 - 계정 신청</title>
  <link rel="stylesheet" href="<%=request.getContextPath()%>/css/tnms/planner-account-application.css?v=20260904.1">
</head>
<body>
  <header class="application-header">
    <a class="application-brand" href="<%=request.getContextPath()%>/login/login.do" aria-label="TNMS 로그인 페이지로">
      <img src="<%=request.getContextPath()%>/images/tnms/arex-logo-white.png" alt="AREX Airport Express">
    </a>
    <h1>계정 신청</h1>
  </header>

  <main class="application-main">
    <section class="application-card" aria-labelledby="application-title">
      <div class="section-heading">
        <h2 id="application-title">기본정보</h2>
        <p>계정 사용을 위해 아래 정보를 입력해 주세요.</p>
      </div>

      <form id="accountApplicationForm" class="application-form" novalidate>
        <div class="form-row">
          <label for="userId">사용자 아이디 <em>*</em></label>
          <div class="field-area">
            <input id="userId" name="userId" type="text" maxlength="20" autocomplete="username" placeholder="영문, 숫자 조합 4~20자로 입력해 주세요" required>
            <p class="field-error" data-error-for="userId"></p>
          </div>
        </div>

        <div class="form-row">
          <label for="password">비밀번호 <em>*</em></label>
          <div class="field-area">
            <div class="password-field">
              <input id="password" name="password" type="password" maxlength="30" autocomplete="new-password" placeholder="비밀번호를 입력해 주세요" required>
              <button class="password-toggle" type="button" data-password-target="password" aria-label="비밀번호 표시" aria-pressed="false">
                <svg viewBox="0 0 24 18" aria-hidden="true"><path d="M1.5 9S5.5 3 12 3s10.5 6 10.5 6S18.5 15 12 15 1.5 9 1.5 9Z"/><circle cx="12" cy="9" r="2.8"/></svg>
              </button>
            </div>
            <p class="field-error" data-error-for="password"></p>
          </div>
        </div>

        <div class="form-row">
          <label for="passwordConfirm">비밀번호 확인 <em>*</em></label>
          <div class="field-area">
            <div class="password-field">
              <input id="passwordConfirm" name="passwordConfirm" type="password" maxlength="30" autocomplete="new-password" placeholder="비밀번호를 다시 입력해 주세요" required>
              <button class="password-toggle" type="button" data-password-target="passwordConfirm" aria-label="비밀번호 확인 표시" aria-pressed="false">
                <svg viewBox="0 0 24 18" aria-hidden="true"><path d="M1.5 9S5.5 3 12 3s10.5 6 10.5 6S18.5 15 12 15 1.5 9 1.5 9Z"/><circle cx="12" cy="9" r="2.8"/></svg>
              </button>
            </div>
            <p class="field-error" data-error-for="passwordConfirm"></p>
          </div>
        </div>

        <div class="form-row">
          <label for="userNm">이름 <em>*</em></label>
          <div class="field-area">
            <input id="userNm" name="userNm" type="text" maxlength="100" autocomplete="name" placeholder="이름을 입력해 주세요" required>
            <p class="field-error" data-error-for="userNm"></p>
          </div>
        </div>

        <div class="form-row affiliation-row">
          <span class="row-label">소속 <em>*</em></span>
          <div class="field-area">
            <div class="radio-group">
              <label><input type="radio" name="userSeNm" value="내부" checked><span></span>내부</label>
              <label><input type="radio" name="userSeNm" value="외부"><span></span>외부</label>
            </div>
            <input id="affiliation" name="affiliation" type="text" maxlength="100" placeholder="소속을 입력해 주세요" required>
            <div class="affiliation-help">
              <p>내부 선택 시 본인의 부서명을 입력해 주세요.</p>
              <p>외부 선택 시 회사명과 참여 중인 사업 또는 관련 업무를 함께 입력해 주세요.</p>
            </div>
            <p class="field-error" data-error-for="affiliation"></p>
          </div>
        </div>

        <div class="form-row">
          <label for="mobileNo">핸드폰번호 <em>*</em></label>
          <div class="field-area">
            <input id="mobileNo" name="mobileNo" type="tel" inputmode="numeric" maxlength="11" autocomplete="tel" placeholder="핸드폰번호를 입력해 주세요" required>
            <p class="field-error" data-error-for="mobileNo"></p>
          </div>
        </div>

        <div class="form-row">
          <label for="telno">전화번호</label>
          <div class="field-area">
            <input id="telno" name="telno" type="tel" inputmode="numeric" maxlength="11" placeholder="전화번호를 입력해 주세요">
            <p class="field-error" data-error-for="telno"></p>
          </div>
        </div>

        <div class="form-row">
          <label for="emlAddr">이메일 <em>*</em></label>
          <div class="field-area">
            <input id="emlAddr" name="emlAddr" type="email" maxlength="320" autocomplete="email" placeholder="이메일을 입력해 주세요" required>
            <p class="field-error" data-error-for="emlAddr"></p>
          </div>
        </div>

        <aside class="password-guide" aria-label="비밀번호 작성 안내">
          <span aria-hidden="true">i</span>
          <div>
            <p>비밀번호는 최소 8자 이상, 최대 30자 이하로 입력해 주세요.</p>
            <p>비밀번호에는 영문, 숫자, 특수문자를 모두 포함해 주세요.</p>
            <p>사용자 아이디가 포함된 비밀번호는 사용할 수 없습니다.</p>
          </div>
        </aside>

        <p class="form-message" id="formMessage" role="alert" aria-live="polite"></p>
        <div class="form-actions">
          <button class="submit-button" id="submitButton" type="submit">계정신청하기</button>
          <a class="back-button" href="<%=request.getContextPath()%>/login/login.do">로그인 페이지로</a>
        </div>
      </form>
    </section>
  </main>

  <script>window.TNMS_CONTEXT_PATH = '<%=request.getContextPath()%>';</script>
  <script src="<%=request.getContextPath()%>/js/tnms/pages/login/account-application.js?v=20260904.1"></script>
</body>
</html>
