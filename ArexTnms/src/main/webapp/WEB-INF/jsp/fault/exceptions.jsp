<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
request.setAttribute("pageKey", "exceptions");
request.setAttribute("pageTitle", "장애 예외설정");
request.setAttribute("pageDescription", "정기점검 등 계획된 시간에는 선택 장비의 장애 이벤트를 억제합니다.");
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
        <div><h1>장애 예외설정</h1><p>정기점검 등 계획된 시간에는 선택 장비의 장애 이벤트를 억제합니다.</p></div>
        <div class="actions page-actions" id="pageActions"></div>
      </div>
      <div id="pageBody"></div>
    </section>
  </main>
</div>
<jsp:include page="/WEB-INF/jsp/common/common-scripts.jsp" />
<script src="<%=request.getContextPath()%>/js/tnms/pages/fault/exceptions.js?v=20260904.1"></script>
</body>
</html>
