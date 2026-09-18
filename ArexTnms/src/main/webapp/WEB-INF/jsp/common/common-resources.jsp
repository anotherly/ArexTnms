<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="org.springframework.web.util.HtmlUtils" %>
<%
String commonPageTitle = (String) request.getAttribute("pageTitle");
if (commonPageTitle == null || commonPageTitle.length() == 0) commonPageTitle = "AREX TNMS";
%>
<meta charset="utf-8" />
<meta name="viewport" content="width=device-width, initial-scale=1" />
<title><%=HtmlUtils.htmlEscape(commonPageTitle)%> | AREX TNMS</title>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/tnms/common-ui.css?v=20260904.1" />
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/tnms/modern-ui.css?v=20260918.1" />

<% if (!"settings".equals((String) request.getAttribute("pageKey"))) { %>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/tnms/planner-v2.css?v=20260917.4" />
<% } %>

<%
String facilityStylePageKey = (String) request.getAttribute("pageKey");
boolean facilityStylePage = "systems".equals(facilityStylePageKey) || "equipment".equals(facilityStylePageKey)
        || "scada".equals(facilityStylePageKey) || "switch".equals(facilityStylePageKey) || "cctv".equals(facilityStylePageKey);
if (facilityStylePage) {
%>
<link rel="stylesheet" href="<%=request.getContextPath()%>/css/tnms/facility-screen.css?v=20260918.2" />
<% } %>
