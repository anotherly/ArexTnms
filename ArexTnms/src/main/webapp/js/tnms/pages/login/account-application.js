(function () {
  'use strict';

  const form = document.getElementById('accountApplicationForm');
  const submitButton = document.getElementById('submitButton');
  const formMessage = document.getElementById('formMessage');
  const contextPath = window.TNMS_CONTEXT_PATH || '';

  function setFieldError(name, message) {
    const error = form.querySelector('[data-error-for="' + name + '"]');
    const field = form.elements[name];
    if (error) error.textContent = message || '';
    if (field && field.classList) field.classList.toggle('is-invalid', Boolean(message));
    if (field && field.closest && field.closest('.password-field')) {
      field.closest('.password-field').classList.toggle('is-invalid', Boolean(message));
    }
  }

  function clearErrors() {
    form.querySelectorAll('.field-error').forEach(function (element) { element.textContent = ''; });
    form.querySelectorAll('.is-invalid').forEach(function (element) { element.classList.remove('is-invalid'); });
    formMessage.textContent = '';
  }

  function value(name) {
    return String(form.elements[name].value || '').trim();
  }

  function validate() {
    clearErrors();
    const userId = value('userId');
    const password = form.elements.password.value;
    const passwordConfirm = form.elements.passwordConfirm.value;
    const checks = [
      ['userId', /^(?=.*[A-Za-z])(?=.*\d)[A-Za-z\d]{4,20}$/.test(userId), '아이디는 영문과 숫자를 조합해 4~20자로 입력해 주세요.'],
      ['password', /^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).{8,30}$/.test(password), '비밀번호는 영문·숫자·특수문자를 포함해 8~30자로 입력해 주세요.'],
      ['password', userId.length === 0 || password.toLowerCase().indexOf(userId.toLowerCase()) === -1, '비밀번호에 사용자 아이디를 포함할 수 없습니다.'],
      ['passwordConfirm', password === passwordConfirm, '비밀번호 확인이 일치하지 않습니다.'],
      ['userNm', value('userNm').length > 0, '이름을 입력해 주세요.'],
      ['affiliation', value('affiliation').length > 0, '소속을 입력해 주세요.'],
      ['mobileNo', /^\d{10,11}$/.test(value('mobileNo')), '핸드폰번호는 하이픈 없이 숫자 10~11자로 입력해 주세요.'],
      ['telno', value('telno') === '' || /^\d{9,11}$/.test(value('telno')), '전화번호는 하이픈 없이 숫자 9~11자로 입력해 주세요.'],
      ['emlAddr', /^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(value('emlAddr')), '이메일 주소 형식이 올바르지 않습니다.']
    ];
    let firstInvalid = null;
    checks.forEach(function (check) {
      if (!check[1] && !form.querySelector('[data-error-for="' + check[0] + '"]').textContent) {
        setFieldError(check[0], check[2]);
        if (!firstInvalid) firstInvalid = form.elements[check[0]];
      }
    });
    if (firstInvalid) firstInvalid.focus();
    return !firstInvalid;
  }

  form.querySelectorAll('.password-toggle').forEach(function (button) {
    button.addEventListener('click', function () {
      const input = document.getElementById(button.dataset.passwordTarget);
      const show = input.type === 'password';
      input.type = show ? 'text' : 'password';
      button.setAttribute('aria-pressed', String(show));
      button.setAttribute('aria-label', show ? '비밀번호 숨기기' : '비밀번호 표시');
    });
  });

  ['mobileNo', 'telno'].forEach(function (name) {
    form.elements[name].addEventListener('input', function () {
      this.value = this.value.replace(/\D/g, '');
    });
  });

  form.addEventListener('submit', async function (event) {
    event.preventDefault();
    if (!validate()) return;
    submitButton.disabled = true;
    formMessage.textContent = '';
    try {
      const response = await fetch(contextPath + '/login/account-application.ajax', {
        method: 'POST',
        headers: {'Content-Type': 'application/x-www-form-urlencoded;charset=UTF-8', 'X-Requested-With': 'XMLHttpRequest'},
        body: new URLSearchParams(new FormData(form))
      });
      const result = await response.json();
      if (!response.ok || !result.success) throw new Error(result.message || '계정 신청을 처리하지 못했습니다.');
      alert(result.message || '계정 신청이 접수되었습니다. 관리자 승인 후 사용할 수 있습니다.');
      location.replace(contextPath + '/login/login.do');
    } catch (error) {
      formMessage.textContent = error.message || '계정 신청 중 오류가 발생했습니다.';
      submitButton.disabled = false;
    }
  });
}());
