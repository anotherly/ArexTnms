<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
request.setAttribute("pageKey", "faults");
request.setAttribute("pageTitle", "실시간 장애관리");
request.setAttribute("pageDescription", "현재 발생 중인 장애를 조회하고 판단·임시조치·이관을 수행합니다.");
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
        <div><h1>실시간 장애관리</h1><p>현재 발생 중인 장애를 조회하고 판단·임시조치·이관을 수행합니다.</p></div>
        <div class="actions page-actions" id="pageActions"></div>
      </div>
      <div id="pageBody"></div>
    </section>
  </main>
</div>
<jsp:include page="/WEB-INF/jsp/common/common-scripts.jsp" />
<script src="<%=request.getContextPath()%>/js/tnms/pages/management-common.js?v=20261010.3"></script>
<script src="<%=request.getContextPath()%>/js/tnms/pages/fault/realtime.js?v=20261008.3"></script>
</body>
</html>
