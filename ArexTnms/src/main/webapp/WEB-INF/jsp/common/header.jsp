<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="kr.co.TRSolution.tnms.user.vo.UserVO" %>
<%@ page import="org.springframework.web.util.HtmlUtils" %>
<%
String headerPageTitle = (String) request.getAttribute("pageTitle");
if (headerPageTitle == null) headerPageTitle = "AREX TNMS";
String headerPageKey = (String) request.getAttribute("pageKey");
UserVO headerLoginUser = (UserVO) session.getAttribute("loginUser");
String headerUserName = headerLoginUser == null ? "사용자"
        : (headerLoginUser.getUserNm() == null ? headerLoginUser.getUserId() : headerLoginUser.getUserNm());
%>
<header class="topbar">
  <div class="topbar-left">
    <div class="page-title"><%=HtmlUtils.htmlEscape(headerPageTitle)%></div>
    <% if ("dashboard".equals(headerPageKey)) { %>
    <div class="dashboard-mode-switch" role="group" aria-label="대시보드 표시 모드">
      <button type="button" data-dashboard-mode="basic" onclick="setDashboardMode('basic')">기본모드</button>
      <button type="button" data-dashboard-mode="expanded" onclick="setDashboardMode('expanded')">확장모드</button>
    </div>
    <div class="dashboard-theme-switch" role="group" aria-label="대시보드 테마">
      <button type="button" data-dashboard-theme="light" onclick="setDashboardTheme('light')" aria-pressed="true">Light</button>
      <button type="button" data-dashboard-theme="dark" onclick="setDashboardTheme('dark')" aria-pressed="false">Dark</button>
    </div>
    <% } %>
  </div>
  <div class="top-right">
    <button class="header-icon notification-trigger" id="notificationTrigger" type="button" title="알림" aria-label="알림" aria-expanded="false">
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M5 17h14l-2-3V9a5 5 0 0 0-10 0v5z"></path>
        <path d="M10 20h4"></path>
      </svg>
      <em id="notificationBadge" hidden>0</em>
    </button>
    <div class="user"><b id="headerUserName"><%=HtmlUtils.htmlEscape(headerUserName)%></b></div>
    <span class="header-divider"></span>
    <span class="header-clock" id="headerClock"></span>
    <button class="header-action-icon fullscreen-icon" type="button" onclick="toggleFullscreen()" title="전체화면" aria-label="전체화면">
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M8 3H3v5M16 3h5v5M8 21H3v-5M16 21h5v-5"></path>
      </svg>
    </button>
    <a class="header-action-icon logout" href="<%=request.getContextPath()%>/login/logout.do" title="로그아웃" aria-label="로그아웃">
      <svg viewBox="0 0 24 24" aria-hidden="true">
        <path d="M10 4H5a2 2 0 0 0-2 2v12a2 2 0 0 0 2 2h5"></path>
        <path d="M14 8l4 4-4 4"></path>
        <path d="M18 12H8"></path>
      </svg>
    </a>
  </div>
</header>
