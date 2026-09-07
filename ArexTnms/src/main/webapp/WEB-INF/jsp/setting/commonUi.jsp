<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
request.setAttribute("pageKey", "settings");
request.setAttribute("pageTitle", "공통코드·UI 설정");
request.setAttribute("pageDescription", "이벤트 등급 색상, 목록 행수와 공통코드를 관리합니다.");
%>
<!doctype html>
<html lang="ko">
<head>
  <jsp:include page="/WEB-INF/jsp/common/common-resources.jsp" />
</head>
<body>
<div class="app">
  <jsp:include page="/WEB-INF/jsp/common/menu.jsp" />
  <main class="main">
    <jsp:include page="/WEB-INF/jsp/common/header.jsp" />
    <section class="content">
      <div class="heading">
        <div><h1>공통코드·UI 설정</h1><p>이벤트 등급 색상, 목록 행수와 공통코드를 관리합니다.</p></div>
        <div class="actions page-actions" id="pageActions"></div>
      </div>
      <div id="pageBody"></div>
    </section>
  </main>
</div>
<jsp:include page="/WEB-INF/jsp/common/common-scripts.jsp" />
<script src="<%=request.getContextPath()%>/js/tnms/pages/setting/common-ui.js?v=20260904.1"></script>
</body>
</html>
