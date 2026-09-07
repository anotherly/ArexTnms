<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="kr.co.TRSolution.tnms.user.vo.UserVO" %>
<%@ page import="org.springframework.web.util.HtmlUtils" %>
<%
String headerPageTitle = (String) request.getAttribute("pageTitle");
if (headerPageTitle == null) headerPageTitle = "AREX TNMS";
UserVO headerLoginUser = (UserVO) session.getAttribute("loginUser");
String headerUserName = headerLoginUser == null ? "사용자"
        : (headerLoginUser.getUserNm() == null ? headerLoginUser.getUserId() : headerLoginUser.getUserNm());
%>
<header class="topbar">
  <div class="page-title"><%=HtmlUtils.htmlEscape(headerPageTitle)%></div>
  <div class="top-right">
    <span class="header-icon" title="알림">
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M5 17h14l-2-3V9a5 5 0 0 0-10 0v5z"></path>
        <path d="M10 20h4"></path>
      </svg>
      <em>12</em>
    </span>
    <div class="user"><b id="headerUserName"><%=HtmlUtils.htmlEscape(headerUserName)%></b></div>
    <span class="header-divider"></span>
    <span class="header-clock" id="headerClock"></span>
    <button class="fullscreen-icon" type="button" onclick="toggleFullscreen()" title="전체화면" aria-label="전체화면"></button>
    <a class="logout" href="<%=request.getContextPath()%>/login/logout.do" title="로그아웃">로그아웃</a>
  </div>
</header>
