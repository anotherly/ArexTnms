<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
request.setAttribute("pageKey", "raw");
request.setAttribute("pageTitle", "Raw 데이터 조회");
request.setAttribute("pageDescription", "수신 원본과 집계 데이터의 저장 현황·보존기간·수집 품질을 확인합니다.");
%>
<!doctype html>
<html lang="ko">
<head>
  <jsp:include page="/WEB-INF/jsp/common/common-resources.jsp" />
  <link rel="stylesheet" href="<%=request.getContextPath()%>/css/tnms/management-screen.css?v=20261008.1" />
</head>
<body>
<div class="app">
  <jsp:include page="/WEB-INF/jsp/common/menu.jsp" />
  <main class="main">
    <jsp:include page="/WEB-INF/jsp/common/header.jsp" />
    <section class="content">
      <div class="heading">
        <div><h1>Raw 데이터 조회</h1><p>수신 원본과 집계 데이터의 저장 현황·보존기간·수집 품질을 확인합니다.</p></div>
        <div class="actions page-actions" id="pageActions"></div>
      </div>
      <div id="pageBody"></div>
    </section>
  </main>
</div>
<jsp:include page="/WEB-INF/jsp/common/common-scripts.jsp" />
<script src="<%=request.getContextPath()%>/js/tnms/pages/management-common.js?v=20261008.1"></script>
<script src="<%=request.getContextPath()%>/js/tnms/pages/performance/raw.js?v=20261008.1"></script>
</body>
</html>
