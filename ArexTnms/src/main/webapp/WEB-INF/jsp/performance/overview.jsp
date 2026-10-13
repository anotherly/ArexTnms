<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
request.setAttribute("pageKey", "performance");
request.setAttribute("pageTitle", "성능현황");
request.setAttribute("pageDescription", "연동시스템과 장비의 실시간·기간별 성능 추이를 조회합니다.");
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
        <div><h1>성능현황</h1><p>연동시스템과 장비의 실시간·기간별 성능 추이를 조회합니다.</p></div>
        <div class="actions page-actions" id="pageActions"></div>
      </div>
      <div id="pageBody"></div>
    </section>
  </main>
</div>
<jsp:include page="/WEB-INF/jsp/common/common-scripts.jsp" />
<script src="<%=request.getContextPath()%>/js/tnms/pages/management-common.js?v=20261010.3"></script>
<script src="<%=request.getContextPath()%>/js/tnms/pages/performance/performance.js?v=20261010.3"></script>
</body>
</html>
