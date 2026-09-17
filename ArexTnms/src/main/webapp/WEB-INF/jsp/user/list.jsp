<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
request.setAttribute("pageKey", "users");
request.setAttribute("pageTitle", "운영관리 > 계정관리");
request.setAttribute("pageDescription", "계정 신청부터 승인·계정 관리까지 한 화면에서 처리합니다.");
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
        <div><h1>계정관리</h1><p>계정 신청 현황과 TNMS 사용자 계정을 통합 관리합니다.</p></div>
        <div class="actions page-actions" id="pageActions"></div>
      </div>
      <div id="pageBody"></div>
    </section>
  </main>
</div>
<jsp:include page="/WEB-INF/jsp/common/common-scripts.jsp" />
<script src="<%=request.getContextPath()%>/js/tnms/pages/user/applications.js?v=20260917.2"></script>
<script src="<%=request.getContextPath()%>/js/tnms/pages/user/users.js?v=20260917.2"></script>
</body>
</html>
