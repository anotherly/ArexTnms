<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="org.springframework.web.util.JavaScriptUtils" %>
<%
String scriptPageKey = (String) request.getAttribute("pageKey");
if (scriptPageKey == null) scriptPageKey = "dashboard";
%>
<script>
window.TNMS_CONFIG = {
  contextPath: '<%=JavaScriptUtils.javaScriptEscape(request.getContextPath())%>',
  pageKey: '<%=JavaScriptUtils.javaScriptEscape(scriptPageKey)%>'
};
</script>
<script src="<%=request.getContextPath()%>/js/tnms/common/page-urls.js?v=20260904.1"></script>
<script src="<%=request.getContextPath()%>/js/tnms/common/tnms-common.js?v=20260904.1"></script>
