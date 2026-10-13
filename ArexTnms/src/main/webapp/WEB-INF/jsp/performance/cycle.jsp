<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
request.setAttribute("pageKey", "cycle");
request.setAttribute("pageTitle", "수집주기 관리");
request.setAttribute("pageDescription", "시스템별 성능수집과 PING 상태감시 주기·타임아웃을 설정합니다.");
%>
<!doctype html>
<html lang="ko">
<head>
  <jsp:include page="/WEB-INF/jsp/common/common-resources.jsp" />
  <link rel="stylesheet" href="<%=request.getContextPath()%>/css/tnms/management-screen.css?v=20261010.3" />
</head>
<body>
<div class="app">
  <jsp:include page="/WEB-INF/jsp/common/menu.jsp" />
  <main class="main">
    <jsp:include page="/WEB-INF/jsp/common/header.jsp" />
    <section class="content">
      <div class="heading">
        <div><h1>수집주기 관리</h1><p>시스템별 성능수집과 PING 상태감시 주기·타임아웃을 설정합니다.</p></div>
        <div class="actions page-actions" id="pageActions"></div>
      </div>
      <div id="pageBody"></div>
    </section>
  </main>
</div>
<jsp:include page="/WEB-INF/jsp/common/common-scripts.jsp" />
<script src="<%=request.getContextPath()%>/js/tnms/pages/management-common.js?v=20261010.3"></script>
<script src="<%=request.getContextPath()%>/js/tnms/pages/performance/cycle.js?v=20261010.3"></script>
</body>
</html>
