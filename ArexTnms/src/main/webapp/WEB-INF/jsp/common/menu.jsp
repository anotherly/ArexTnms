<%@ page language="java" contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%@ page import="java.util.Arrays" %>
<%@ page import="java.util.HashSet" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.Set" %>
<%@ page import="kr.co.TRSolution.tnms.auth.vo.MenuAuthVO" %>
<%!
private boolean canList(Map<String, MenuAuthVO> permissions, String key) {
    if (permissions == null) return true;
    MenuAuthVO permission = permissions.get(key);
    return permission != null && "Y".equals(permission.getListAuthrtYn());
}
private String itemClass(Map<String, MenuAuthVO> permissions, String activeKey, String key, String type) {
    return "nav-item " + type + (key.equals(activeKey) ? " active" : "")
            + (canList(permissions, key) ? "" : " denied");
}
private String icon(String key) {
    if ("dashboard".equals(key)) return "<path d='M4 11l8-7 8 7v9H5v-9'></path><path d='M9 20v-6h6v6'></path>";
    if ("systems".equals(key)) return "<path d='M4 7h16M4 12h16M4 17h16'></path><circle cx='7' cy='7' r='1'></circle>";
    if ("equipment".equals(key)) return "<rect x='5' y='4' width='14' height='16' rx='2'></rect><path d='M8 8h8M8 12h8'></path>";
    if ("switch".equals(key)) return "<path d='M4 7h16v10H4z'></path><path d='M8 10h2m2 0h2m2 0h1'></path>";
    if ("cctv".equals(key)) return "<path d='M4 8h11l4 4-4 4H4z'></path><circle cx='9' cy='12' r='2'></circle>";
    if ("scada".equals(key)) return "<path d='M5 20V9m7 11V4m7 16v-7'></path><path d='M3 20h18'></path>";
    if (key.startsWith("fault") || "exceptions".equals(key)) return "<path d='M12 3l9 17H3z'></path><path d='M12 9v4m0 3h.01'></path>";
    if ("performance".equals(key) || "cycle".equals(key) || "threshold".equals(key) || "raw".equals(key)) return "<circle cx='12' cy='12' r='8'></circle><path d='M12 12l4-4'></path>";
    if ("reports".equals(key)) return "<path d='M6 3h9l3 3v15H6z'></path><path d='M9 12h6m-6 4h6'></path>";
    if ("settings".equals(key)) return "<circle cx='12' cy='12' r='3'></circle><path d='M12 2v3m0 14v3M2 12h3m14 0h3'></path>";
    return "<circle cx='9' cy='8' r='3'></circle><path d='M3 20c.4-4 2.5-6 6-6s5.6 2 6 6'></path>";
}
%>
<%
String menuPageKey = (String) request.getAttribute("pageKey");
if (menuPageKey == null) menuPageKey = "dashboard";
@SuppressWarnings("unchecked")
Map<String, MenuAuthVO> menuPermissions = (Map<String, MenuAuthVO>) session.getAttribute("menuAuthMap");
Set<String> facilityKeys = new HashSet<String>(Arrays.asList("systems", "equipment", "switch", "cctv", "scada"));
Set<String> faultKeys = new HashSet<String>(Arrays.asList("faults", "faultHistory", "exceptions", "faultTypes"));
Set<String> performanceKeys = new HashSet<String>(Arrays.asList("performance", "cycle", "threshold", "raw"));
Set<String> operationKeys = new HashSet<String>(Arrays.asList("users", "auth", "applications", "logs"));
%>
<aside class="sidebar">
  <div class="brand"><div class="logo">AREX</div><div class="brand-copy"><b>AREX TNMS</b></div></div>
  <nav class="nav" aria-label="주 메뉴">
    <a class="<%=itemClass(menuPermissions, menuPageKey, "dashboard", "nav-root-item")%>"
       href="<%=request.getContextPath()%>/main/dashboard.do" data-key="dashboard">
      <i class="dot"><svg viewBox="0 0 24 24"><%=icon("dashboard")%></svg></i><span>통합 대시보드</span>
    </a>

    <section class="nav-section <%=facilityKeys.contains(menuPageKey) ? "open" : ""%>">
      <button class="nav-parent" type="button" aria-expanded="<%=facilityKeys.contains(menuPageKey)%>">
        <i class="dot"><svg viewBox="0 0 24 24"><%=icon("systems")%></svg></i><span>설비관리</span><b class="nav-chevron"></b>
      </button>
      <div class="nav-children">
        <a class="<%=itemClass(menuPermissions, menuPageKey, "systems", "nav-child")%>" href="<%=request.getContextPath()%>/facility/transmission.do?screen=systems" data-key="systems"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("systems")%></svg></i><span>전송설비</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "equipment", "nav-child")%>" href="<%=request.getContextPath()%>/facility/pids.do?screen=equipment" data-key="equipment"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("equipment")%></svg></i><span>행선안내설비</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "scada", "nav-child")%>" href="<%=request.getContextPath()%>/facility/scada.do?screen=scada" data-key="scada"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("scada")%></svg></i><span>SCADA 출입보안설비</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "switch", "nav-child")%>" href="<%=request.getContextPath()%>/facility/pbx.do?screen=switch" data-key="switch"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("switch")%></svg></i><span>전화교환설비</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "cctv", "nav-child")%>" href="<%=request.getContextPath()%>/facility/cctv.do?screen=cctv" data-key="cctv"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("cctv")%></svg></i><span>영상감시설비(CCTV)</span></a>
      </div>
    </section>

    <section class="nav-section <%=faultKeys.contains(menuPageKey) ? "open" : ""%>">
      <button class="nav-parent" type="button" aria-expanded="<%=faultKeys.contains(menuPageKey)%>"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("faults")%></svg></i><span>장애관리</span><b class="nav-chevron"></b></button>
      <div class="nav-children">
        <a class="<%=itemClass(menuPermissions, menuPageKey, "faults", "nav-child")%>" href="<%=request.getContextPath()%>/fault/realtime.do?screen=faults" data-key="faults"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("faults")%></svg></i><span>실시간 장애</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "faultHistory", "nav-child")%>" href="<%=request.getContextPath()%>/fault/history.do?screen=faultHistory" data-key="faultHistory"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("faultHistory")%></svg></i><span>장애이력·조치</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "exceptions", "nav-child")%>" href="<%=request.getContextPath()%>/fault/exceptions.do?screen=exceptions" data-key="exceptions"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("exceptions")%></svg></i><span>장애 예외설정</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "faultTypes", "nav-child")%>" href="<%=request.getContextPath()%>/fault/types.do?screen=faultTypes" data-key="faultTypes"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("faultTypes")%></svg></i><span>장애유형 관리</span></a>
      </div>
    </section>

    <section class="nav-section <%=performanceKeys.contains(menuPageKey) ? "open" : ""%>">
      <button class="nav-parent" type="button" aria-expanded="<%=performanceKeys.contains(menuPageKey)%>"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("performance")%></svg></i><span>성능관리</span><b class="nav-chevron"></b></button>
      <div class="nav-children">
        <a class="<%=itemClass(menuPermissions, menuPageKey, "performance", "nav-child")%>" href="<%=request.getContextPath()%>/performance/overview.do?screen=performance" data-key="performance"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("performance")%></svg></i><span>성능관리</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "cycle", "nav-child")%>" href="<%=request.getContextPath()%>/performance/cycle.do?screen=cycle" data-key="cycle"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("cycle")%></svg></i><span>연동주기 관리</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "threshold", "nav-child")%>" href="<%=request.getContextPath()%>/performance/threshold.do?screen=threshold" data-key="threshold"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("threshold")%></svg></i><span>임계치 관리</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "raw", "nav-child")%>" href="<%=request.getContextPath()%>/performance/raw.do?screen=raw" data-key="raw"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("raw")%></svg></i><span>Raw 데이터 관리</span></a>
      </div>
    </section>

    <section class="nav-section <%="reports".equals(menuPageKey) ? "open" : ""%>">
      <button class="nav-parent" type="button" aria-expanded="<%="reports".equals(menuPageKey)%>"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("reports")%></svg></i><span>보고서</span><b class="nav-chevron"></b></button>
      <div class="nav-children"><a class="<%=itemClass(menuPermissions, menuPageKey, "reports", "nav-child")%>" href="<%=request.getContextPath()%>/report/fault-performance.do?screen=reports" data-key="reports"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("reports")%></svg></i><span>장애·성능 보고서</span></a></div>
    </section>

    <section class="nav-section <%=operationKeys.contains(menuPageKey) ? "open" : ""%>">
      <button class="nav-parent" type="button" aria-expanded="<%=operationKeys.contains(menuPageKey)%>"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("users")%></svg></i><span>운영관리</span><b class="nav-chevron"></b></button>
      <div class="nav-children">
        <a class="<%=itemClass(menuPermissions, menuPageKey, "users", "nav-child")%>" href="<%=request.getContextPath()%>/user/list.do?screen=users" data-key="users"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("users")%></svg></i><span>사용자 계정 설정</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "auth", "nav-child")%>" href="<%=request.getContextPath()%>/auth/list.do?screen=auth" data-key="auth"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("auth")%></svg></i><span>권한 관리</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "applications", "nav-child")%>" href="<%=request.getContextPath()%>/user/applications.do?screen=applications" data-key="applications"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("applications")%></svg></i><span>계정 신청 현황</span></a>
        <a class="<%=itemClass(menuPermissions, menuPageKey, "logs", "nav-child")%>" href="<%=request.getContextPath()%>/audit/job-log.do?screen=logs" data-key="logs"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("logs")%></svg></i><span>작업로그 조회</span></a>
      </div>
    </section>

    <section class="nav-section <%="settings".equals(menuPageKey) ? "open" : ""%>">
      <button class="nav-parent" type="button" aria-expanded="<%="settings".equals(menuPageKey)%>"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("settings")%></svg></i><span>설정</span><b class="nav-chevron"></b></button>
      <div class="nav-children"><a class="<%=itemClass(menuPermissions, menuPageKey, "settings", "nav-child")%>" href="<%=request.getContextPath()%>/setting/common-ui.do?screen=settings" data-key="settings"><i class="dot"><svg viewBox="0 0 24 24"><%=icon("settings")%></svg></i><span>공통코드·UI 설정</span></a></div>
    </section>
  </nav>
  <div class="side-footer"><button class="side-collapse" type="button">← 메뉴 접기</button></div>
</aside>
