package kr.co.TRSolution.tnms.auth.web;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.audit.service.AuditService;
import kr.co.TRSolution.tnms.auth.service.AuthService;
import kr.co.TRSolution.tnms.auth.vo.AuthVO;
import kr.co.TRSolution.tnms.auth.vo.MenuAuthVO;
import kr.co.TRSolution.tnms.common.BaseController;
import kr.co.TRSolution.tnms.common.util.ClientIpUtil;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Controller
public class AuthController extends BaseController {
    private static final Logger logger = LoggerFactory.getLogger(AuthController.class);
    @Resource(name = "authService") private AuthService authService;
    @Resource(name = "auditService") private AuditService auditService;

    @RequestMapping(value = "/auth/list.do", method = RequestMethod.GET)
    public String authPage() { return "auth/list"; }

    @RequestMapping(value = {"/auth/list.ajax", "/auth/options.ajax"}, method = RequestMethod.GET)
    public ModelAndView list() {
        try { return success(authService.selectAuthList()); }
        catch (Exception e) { logger.warn("권한 목록 조회 실패", e); return fail(message(e)); }
    }

    @RequestMapping(value = "/auth/detail.ajax", method = RequestMethod.GET)
    public ModelAndView detail(@RequestParam("authrtSn") Long authrtSn) {
        try { return success(authService.selectAuth(authrtSn)); }
        catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/auth/insert.ajax", method = RequestMethod.POST)
    public ModelAndView insert(@ModelAttribute AuthVO authVO, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            AuthVO created = authService.createAuth(authVO, actor.getUserSn());
            auditService.record(actor, ClientIpUtil.getClientIp(request), "권한 관리", "REG",
                    String.valueOf(created.getAuthrtSn()), "권한 등록", "SUCCESS");
            return success("권한을 등록했습니다.", created);
        } catch (Exception e) { logger.warn("권한 등록 실패", e); return fail(message(e)); }
    }

    @RequestMapping(value = "/auth/update.ajax", method = RequestMethod.POST)
    public ModelAndView update(@ModelAttribute AuthVO authVO, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            authService.updateAuth(authVO, actor.getUserSn());
            auditService.record(actor, ClientIpUtil.getClientIp(request), "권한 관리", "MDFCN",
                    String.valueOf(authVO.getAuthrtSn()), "권한 정보 수정", "SUCCESS");
            return success("권한 정보를 수정했습니다.", null);
        } catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/auth/delete.ajax", method = RequestMethod.POST)
    public ModelAndView delete(@RequestParam("authrtSn") Long authrtSn, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            authService.deleteAuth(authrtSn);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "권한 관리", "DEL",
                    String.valueOf(authrtSn), "권한 삭제", "SUCCESS");
            return success("권한을 삭제했습니다.", null);
        } catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/auth/savePermissions.ajax", method = RequestMethod.POST,
                    consumes = "application/json")
    public ModelAndView savePermissions(@RequestBody AuthVO requestVO, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            authService.saveMenuPermissions(requestVO.getAuthrtSn(), requestVO.getMenuAuthList());
            auditService.record(actor, ClientIpUtil.getClientIp(request), "권한 관리", "MDFCN",
                    String.valueOf(requestVO.getAuthrtSn()), "메뉴·기능 권한 저장", "SUCCESS");
            refreshOwnPermissions(request, actor, requestVO.getAuthrtSn());
            return success("메뉴·기능 권한을 저장했습니다.", null);
        } catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/auth/myPermissions.ajax", method = RequestMethod.GET)
    public ModelAndView myPermissions(HttpServletRequest request) {
        try {
            UserVO user = loginUser(request);
            Map<String, MenuAuthVO> permissions = authService.selectPermissionMap(user.getAuthrtSn());
            request.getSession().setAttribute("menuAuthMap", permissions);
            Map<String, Object> result = new HashMap<String, Object>();
            result.put("user", user);
            result.put("permissions", permissions);
            result.put("csrfToken", request.getSession().getAttribute("csrfToken"));
            return success(result);
        } catch (Exception e) {
            logger.warn("로그인 사용자 권한 조회 실패", e);
            return fail(message(e));
        }
    }

    private void refreshOwnPermissions(HttpServletRequest request, UserVO actor, Long changedAuthrtSn) {
        if (actor.getAuthrtSn().equals(changedAuthrtSn)) {
            request.getSession().setAttribute("menuAuthMap", authService.selectPermissionMap(changedAuthrtSn));
        }
    }

    private String message(Exception e) {
        return e.getMessage() == null ? "처리 중 오류가 발생했습니다." : e.getMessage();
    }
}
