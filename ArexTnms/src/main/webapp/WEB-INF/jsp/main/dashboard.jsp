<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
request.setAttribute("pageKey", "dashboard");
request.setAttribute("pageTitle", "통합망 관리시스템");
request.setAttribute("pageDescription", "");
%>
<!doctype html>
<html lang="ko">
<head>
  <jsp:include page="/WEB-INF/jsp/common/common-resources.jsp" />
  <link rel="stylesheet" href="<%=request.getContextPath()%>/css/tnms/dashboard-theme.css?v=20261015.1" />
</head>
<body>
<div class="app">
  <jsp:include page="/WEB-INF/jsp/common/menu.jsp" />
  <main class="main">
    <jsp:include page="/WEB-INF/jsp/common/header.jsp" />
    <section class="content dashboard-content">
      <div id="pageBody"></div>
    </section>
  </main>
</div>
<jsp:include page="/WEB-INF/jsp/common/common-scripts.jsp" />
<script src="<%=request.getContextPath()%>/js/tnms/pages/dashboard/dashboard.js?v=20261015.1"></script>
</body>
</html>
