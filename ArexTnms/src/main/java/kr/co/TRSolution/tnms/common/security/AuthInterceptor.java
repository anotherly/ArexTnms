package kr.co.TRSolution.tnms.common.security;

import java.io.IOException;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.springframework.web.servlet.handler.HandlerInterceptorAdapter;

import kr.co.TRSolution.tnms.auth.service.AuthService;
import kr.co.TRSolution.tnms.auth.vo.MenuAuthVO;
import kr.co.TRSolution.tnms.user.vo.UserVO;

public class AuthInterceptor extends HandlerInterceptorAdapter {
    private static final Map<String, Requirement> REQUIREMENTS = createRequirements();

    @Resource(name = "authService")
    private AuthService authService;

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

        Map<String, MenuAuthVO> permissionMap = authService.selectPermissionMap(loginUser.getAuthrtSn());
        session.setAttribute("menuAuthMap", permissionMap);

        String path = request.getRequestURI().substring(request.getContextPath().length());
        Requirement requirement = REQUIREMENTS.get(path);
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
        map.put("/main/dashboard.do", new Requirement("dashboard", "LIST"));
        map.put("/facility/transmission.do", new Requirement("systems", "LIST"));
        map.put("/facility/pids.do", new Requirement("equipment", "LIST"));
        map.put("/facility/pbx.do", new Requirement("switch", "LIST"));
        map.put("/facility/cctv.do", new Requirement("cctv", "LIST"));
        map.put("/facility/scada.do", new Requirement("scada", "LIST"));
        map.put("/performance/overview.do", new Requirement("performance", "LIST"));
        map.put("/performance/cycle.do", new Requirement("cycle", "LIST"));
        map.put("/performance/threshold.do", new Requirement("threshold", "LIST"));
        map.put("/performance/raw.do", new Requirement("raw", "LIST"));
        map.put("/fault/realtime.do", new Requirement("faults", "LIST"));
        map.put("/fault/history.do", new Requirement("faultHistory", "LIST"));
        map.put("/fault/exceptions.do", new Requirement("exceptions", "LIST"));
        map.put("/fault/types.do", new Requirement("faultTypes", "LIST"));
        map.put("/report/fault-performance.do", new Requirement("reports", "LIST"));
        map.put("/user/list.do", new Requirement("users", "LIST"));
        map.put("/auth/list.do", new Requirement("auth", "LIST"));
        map.put("/user/applications.do", new Requirement("applications", "LIST"));
        map.put("/user/applications/list.ajax", new Requirement("applications", "LIST"));
        map.put("/user/applications/detail.ajax", new Requirement("applications", "DTL"));
        map.put("/user/applications/approve.ajax", new Requirement("applications", "MDFCN"));
        map.put("/user/applications/reject.ajax", new Requirement("applications", "MDFCN"));
        map.put("/setting/common-ui.do", new Requirement("settings", "LIST"));
        map.put("/audit/job-log.do", new Requirement("logs", "LIST"));
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

    private static class Requirement {
        private final String screenKey;
        private final String action;
        Requirement(String screenKey, String action) { this.screenKey = screenKey; this.action = action; }
    }
}
