package kr.co.TRSolution.tnms.common.security;

import java.io.IOException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.List;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import kr.co.TRSolution.tnms.auth.service.AuthService;
import kr.co.TRSolution.tnms.auth.vo.MenuAuthVO;
import kr.co.TRSolution.tnms.user.vo.UserVO;
import kr.co.TRSolution.tnms.monitoring.service.MonitoringService;
import kr.co.TRSolution.tnms.monitoring.vo.EquipmentVO;

public class AuthInterceptor extends HandlerInterceptorAdapter {
    private static final Map<String, Requirement> REQUIREMENTS = createRequirements();

    @Resource(name = "authService")
    private AuthService authService;

    @Resource(name = "monitoringService")
    private MonitoringService monitoringService;

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) throws Exception {
        HttpSession session = request.getSession(false);
        UserVO loginUser = session == null ? null : (UserVO) session.getAttribute("loginUser");
        if (loginUser == null) return reject(request, response, HttpServletResponse.SC_UNAUTHORIZED, "로그인이 필요합니다.");

        if (!"GET".equalsIgnoreCase(request.getMethod())) {
            String sessionToken = (String) session.getAttribute("csrfToken");
            String requestToken = request.getHeader("X-CSRF-TOKEN");
            if (sessionToken == null || !sessionToken.equals(requestToken)) {
                return reject(request, response, HttpServletResponse.SC_FORBIDDEN, "요청 검증값이 올바르지 않습니다. 화면을 새로고침해 주세요.");
            }
        }

        Map<String, MenuAuthVO> permissionMap = authService.selectPermissionMap(loginUser.getAuthrtCd());
        session.setAttribute("menuAuthMap", permissionMap);
        List<String> allowedSystems = authService.selectAllowedSystemCodes(loginUser.getAuthrtCd());
        request.setAttribute(SystemDataScope.REQUEST_ATTRIBUTE, allowedSystems);

        String path = request.getRequestURI().substring(request.getContextPath().length());
        Requirement requirement = REQUIREMENTS.get(path);
        if ("/setting/common-ui/code.ajax".equals(path)) {
            String requestedAction = request.getParameter("_authAction");
            requirement = new Requirement("settings", "REG".equals(requestedAction) ? "REG" : "MDFCN");
        }
        // 같은 그룹/일정 저장 주소는 등록과 수정 요청을 구분합니다.
        if ("/fault/exception-group-save.ajax".equals(path)) {
            requirement = new Requirement("exceptions", hasValue(request.getParameter("groupSn")) ? "MDFCN" : "REG");
        } else if ("/fault/exception-schedule-save.ajax".equals(path)) {
            requirement = new Requirement("exceptions", hasValue(request.getParameter("scheduleSn")) ? "MDFCN" : "REG");
        }
        // 장애 상세는 실시간 장애 및 장애이력 화면에서 함께 사용합니다.
        if ("/fault/detail.ajax".equals(path)) {
            MenuAuthVO rt = permissionMap.get("faults");
            MenuAuthVO hist = permissionMap.get("faultHistory");
            if ((rt != null && rt.permits("DTL")) || (hist != null && hist.permits("DTL"))) return true;
            return reject(request, response, HttpServletResponse.SC_FORBIDDEN, "해당 기능에 대한 권한이 없습니다.");
        }
        if (requirement == null && path.startsWith("/facility/") && path.endsWith(".ajax")) {
            String linkSysCd = request.getParameter("linkSysCd");
            String equipmentNo = request.getParameter("eqpmntSn");
            // 상세/수정/삭제는 브라우저에서 전달한 시스템코드가 아니라 DB의 실제 장비를 기준으로 권한 검증.
            if (hasValue(equipmentNo)) {
                try {
                    EquipmentVO actual = monitoringService.selectEquipment(Long.valueOf(equipmentNo));
                    if (actual == null) throw new IllegalArgumentException("장비 없음");
                    if (hasValue(linkSysCd) && !linkSysCd.equals(actual.getLinkSysCd()))
                        return reject(request, response, HttpServletResponse.SC_FORBIDDEN, "장비 연계시스템 정보가 일치하지 않습니다.");
                    linkSysCd = actual.getLinkSysCd();
                } catch (Exception exception) {
                    return reject(request, response, HttpServletResponse.SC_FORBIDDEN, "해당 장비의 데이터 접근 권한이 없습니다.");
                }
            }
            String action = "/facility/save.ajax".equals(path) ? (hasValue(equipmentNo) ? "MDFCN" : "REG")
                    : "/facility/delete.ajax".equals(path) ? "DEL" : "/facility/detail.ajax".equals(path) ? "DTL" : "LIST";
            if (hasValue(linkSysCd) && !allowedSystems.contains(linkSysCd))
                return reject(request, response, HttpServletResponse.SC_FORBIDDEN, "해당 연계시스템의 데이터 조회 권한이 없습니다.");
            requirement = new Requirement(facilityScreenKey(linkSysCd), action);
        }
        if (requirement == null) return true;
        MenuAuthVO permission = permissionMap.get(requirement.screenKey);
        if (permission != null && permission.permits(requirement.action)) return true;
        return reject(request, response, HttpServletResponse.SC_FORBIDDEN, "해당 기능에 대한 권한이 없습니다.");
    }

    private boolean reject(HttpServletRequest request, HttpServletResponse response, int status, String message) throws IOException {
        if (isAjax(request)) {
            response.setStatus(status);
            response.setCharacterEncoding("UTF-8");
            response.setContentType("application/json;charset=UTF-8");
            response.getWriter().write("{\"success\":false,\"message\":\"" + message + "\"}");
        } else if (status == HttpServletResponse.SC_UNAUTHORIZED) {
            response.sendRedirect(request.getContextPath() + "/login/login.do");
        } else {
            response.setStatus(status);
            response.setCharacterEncoding("UTF-8");
            response.setContentType("text/html;charset=UTF-8");
            response.getWriter().write("<!doctype html><meta charset='utf-8'><script>alert('" + message
                    + "');location.replace('" + request.getContextPath() + "/main/dashboard.do');</script>");
        }
        return false;
    }

    private boolean isAjax(HttpServletRequest request) {
        return request.getRequestURI().endsWith(".ajax") || "XMLHttpRequest".equalsIgnoreCase(request.getHeader("X-Requested-With"));
    }

    private static Map<String, Requirement> createRequirements() {
        Map<String, Requirement> map = new HashMap<String, Requirement>();
        map.put("/facility/transmission.do", new Requirement("systems", "LIST"));
        map.put("/facility/pids.do", new Requirement("equipment", "LIST"));
        map.put("/facility/pbx.do", new Requirement("switch", "LIST"));
        map.put("/facility/cctv.do", new Requirement("cctv", "LIST"));
        map.put("/facility/scada.do", new Requirement("scada", "LIST"));
        // 성능관리 화면 및 AJAX는 화면 기능 권한과 서버 권한을 동일하게 적용합니다.
        map.put("/performance/overview-data.ajax", new Requirement("performance", "LIST"));
        map.put("/performance/equipment-detail.ajax", new Requirement("performance", "DTL"));
        map.put("/performance/cycle-data.ajax", new Requirement("cycle", "LIST"));
        map.put("/performance/cycle-detail.ajax", new Requirement("cycle", "DTL"));
        map.put("/performance/cycle-save.ajax", new Requirement("cycle", "MDFCN"));
        map.put("/performance/threshold-data.ajax", new Requirement("threshold", "LIST"));
        map.put("/performance/threshold-detail.ajax", new Requirement("threshold", "DTL"));
        map.put("/performance/threshold-save.ajax", new Requirement("threshold", "MDFCN"));
        map.put("/performance/raw-data.ajax", new Requirement("raw", "LIST"));
        // 장애관리: 조회와 조치·이관·예외 일정 관리를 분리합니다.
        map.put("/fault/realtime-data.ajax", new Requirement("faults", "LIST"));
        map.put("/fault/realtime-excel.do", new Requirement("faults", "LIST"));
        map.put("/fault/history-data.ajax", new Requirement("faultHistory", "LIST"));
        map.put("/fault/save.ajax", new Requirement("faults", "MDFCN"));
        map.put("/fault/judgment.ajax", new Requirement("faults", "MDFCN"));
        map.put("/fault/transfer.ajax", new Requirement("faults", "MDFCN"));
        map.put("/fault/complete.ajax", new Requirement("faultHistory", "MDFCN"));
        map.put("/fault/types-data.ajax", new Requirement("faultTypes", "LIST"));
        map.put("/fault/type-detail.ajax", new Requirement("faultTypes", "DTL"));
        map.put("/fault/exceptions-data.ajax", new Requirement("exceptions", "LIST"));
        map.put("/fault/exception-group-detail.ajax", new Requirement("exceptions", "DTL"));
        map.put("/fault/exception-equipment.ajax", new Requirement("exceptions", "LIST"));
        map.put("/fault/exception-group-delete.ajax", new Requirement("exceptions", "DEL"));
        map.put("/fault/exception-schedule-detail.ajax", new Requirement("exceptions", "DTL"));
        map.put("/fault/exception-schedule-delete.ajax", new Requirement("exceptions", "DEL"));
        map.put("/performance/overview.do", new Requirement("performance", "LIST"));
        map.put("/performance/cycle.do", new Requirement("cycle", "LIST"));
        map.put("/performance/threshold.do", new Requirement("threshold", "LIST"));
        map.put("/performance/raw.do", new Requirement("raw", "LIST"));
        map.put("/fault/realtime.do", new Requirement("faults", "LIST"));
        map.put("/fault/history.do", new Requirement("faultHistory", "LIST"));
        map.put("/fault/exceptions.do", new Requirement("exceptions", "LIST"));
        map.put("/fault/types.do", new Requirement("faultTypes", "LIST"));
        map.put("/report/fault-performance.do", new Requirement("reports", "LIST"));
        map.put("/report/fault-performance/data.ajax", new Requirement("reports", "LIST"));
        map.put("/report/fault-performance/excel.do", new Requirement("reports", "LIST"));
        map.put("/user/list.do", new Requirement("users", "LIST"));
        map.put("/auth/list.do", new Requirement("auth", "LIST"));
        map.put("/user/applications.do", new Requirement("users", "LIST"));
        map.put("/user/applications/list.ajax", new Requirement("users", "LIST"));
        map.put("/user/applications/detail.ajax", new Requirement("users", "DTL"));
        map.put("/user/applications/approve.ajax", new Requirement("users", "MDFCN"));
        map.put("/user/applications/reject.ajax", new Requirement("users", "MDFCN"));
        map.put("/setting/common-ui.do", new Requirement("settings", "LIST"));
        map.put("/setting/common-ui/data.ajax", new Requirement("settings", "LIST"));
        map.put("/setting/common-ui/ui.ajax", new Requirement("settings", "MDFCN"));
        map.put("/audit/job-log.do", new Requirement("logs", "LIST"));
        map.put("/audit/job-log/list.ajax", new Requirement("logs", "LIST"));
        map.put("/audit/job-log/detail.ajax", new Requirement("logs", "DTL"));
        map.put("/user/list.ajax", new Requirement("users", "LIST"));
        map.put("/user/detail.ajax", new Requirement("users", "DTL"));
        map.put("/user/idCheck.ajax", new Requirement("users", "REG"));
        map.put("/user/insert.ajax", new Requirement("users", "REG"));
        map.put("/user/update.ajax", new Requirement("users", "MDFCN"));
        map.put("/user/delete.ajax", new Requirement("users", "DEL"));
        map.put("/user/unlock.ajax", new Requirement("users", "MDFCN"));
        map.put("/auth/options.ajax", new Requirement("users", "LIST"));
        map.put("/auth/list.ajax", new Requirement("auth", "LIST"));
        map.put("/auth/detail.ajax", new Requirement("auth", "DTL"));
        map.put("/auth/insert.ajax", new Requirement("auth", "REG"));
        map.put("/auth/update.ajax", new Requirement("auth", "MDFCN"));
        map.put("/auth/delete.ajax", new Requirement("auth", "DEL"));
        map.put("/auth/savePermissions.ajax", new Requirement("auth", "MDFCN"));
        return Collections.unmodifiableMap(map);
    }

    private static boolean hasValue(String value) { return value != null && value.trim().length() > 0; }

    private static String facilityScreenKey(String linkSysCd) {
        if ("EMS_PIDS".equals(linkSysCd)) return "equipment";
        if ("PBX".equals(linkSysCd)) return "switch";
        if ("VMS".equals(linkSysCd)) return "cctv";
        if ("SCADA_SEC".equals(linkSysCd)) return "scada";
        return "systems";
    }

    private static class Requirement {
        private final String screenKey;
        private final String action;
        Requirement(String screenKey, String action) { this.screenKey = screenKey; this.action = action; }
    }
}
