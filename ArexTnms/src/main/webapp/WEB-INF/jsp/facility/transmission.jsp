<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isELIgnored="true" %>
<%
request.setAttribute("pageKey", "systems");
request.setAttribute("pageTitle", "설비관리 > 전송설비");
request.setAttribute("pageDescription", "");
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
      <div id="pageBody"></div>
    </section>
  </main>
</div>
<jsp:include page="/WEB-INF/jsp/common/common-scripts.jsp" />
<script src="<%=request.getContextPath()%>/js/tnms/pages/facility/facility.js?v=20260904.1"></script>
</body>
</html>
