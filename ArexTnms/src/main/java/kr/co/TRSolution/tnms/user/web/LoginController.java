package kr.co.TRSolution.tnms.user.web;

import java.time.LocalDate;
import java.time.format.DateTimeParseException;
import java.util.Map;
import java.util.UUID;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.mindrot.jbcrypt.BCrypt;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.auth.service.AuthService;
import kr.co.TRSolution.tnms.auth.vo.MenuAuthVO;
import kr.co.TRSolution.tnms.common.BaseController;
import kr.co.TRSolution.tnms.common.SessionListener;
import kr.co.TRSolution.tnms.common.util.ClientIpUtil;
import kr.co.TRSolution.tnms.user.service.UserService;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Controller
public class LoginController extends BaseController {
    private static final Logger logger = LoggerFactory.getLogger(LoginController.class);

    @Resource(name = "userService") private UserService userService;
    @Resource(name = "authService") private AuthService authService;

    @RequestMapping(value = "/login/login.do", method = RequestMethod.GET)
    public String login(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session != null && session.getAttribute("loginUser") != null
                ? "redirect:/main/dashboard.do" : "login/login";
    }

    @RequestMapping(value = "/login/loginPost.do", method = RequestMethod.POST)
    public ModelAndView loginPost(@RequestParam("userId") String userId,
                                  @RequestParam("password") String password,
                                  HttpServletRequest request) {
        String ip = ClientIpUtil.getClientIp(request);
        UserVO user = userService.selectLoginUser(userId);
        try {
            if (user == null) {
                userService.recordLoginFailure(null, ip, request.getHeader("User-Agent"), "등록되지 않은 아이디");
                return fail("아이디 또는 비밀번호가 올바르지 않습니다.");
            }
            if (!"Y".equals(user.getUseYn()) || "DELETED".equals(user.getUserSttsCd()) ||
                    "SUSPENDED".equals(user.getUserSttsCd())) {
                userService.recordLoginFailure(user, ip, request.getHeader("User-Agent"), "미사용 계정");
                return fail("사용할 수 없는 계정입니다. 관리자에게 문의해 주세요.");
            }
            if ("LOCKED".equals(user.getUserSttsCd())) {
                userService.recordLoginFailure(user, ip, request.getHeader("User-Agent"), "잠금 계정");
                return fail("로그인 실패 5회로 잠긴 계정입니다. 관리자에게 문의해 주세요.");
            }
            if (user.getAuthrtCd() == null) {
                userService.recordLoginFailure(user, ip, request.getHeader("User-Agent"), "권한 미지정");
                return fail("권한이 지정되지 않은 계정입니다. 관리자에게 문의해 주세요.");
            }
            if (password == null || user.getUserEnpswd() == null || !BCrypt.checkpw(password, user.getUserEnpswd())) {
                userService.recordLoginFailure(user, ip, request.getHeader("User-Agent"), "비밀번호 불일치");
                return fail("아이디 또는 비밀번호가 올바르지 않습니다.");
            }

            boolean passwordChangeRequired = isPasswordChangeRequired(user.getPswdExpryYmd());
            userService.recordLoginSuccess(user, ip, request.getHeader("User-Agent"));
            user.setUserEnpswd(null);
            HttpSession session = request.getSession(true);
            request.changeSessionId();
            Map<String, MenuAuthVO> permissionMap = authService.selectPermissionMap(user.getAuthrtCd());
            session.setAttribute("loginUser", user);
            session.setAttribute("menuAuthMap", permissionMap);
            session.setAttribute("csrfToken", UUID.randomUUID().toString());
            SessionListener.register(user.getUserId(), session);
            ModelAndView mav = success(passwordChangeRequired ? "비밀번호 변경주기가 경과했습니다. 관리자에게 비밀번호 변경을 요청해 주세요." : "로그인되었습니다.", null);
            mav.addObject("url", request.getContextPath() + "/main/dashboard.do");
            mav.addObject("passwordChangeRequired", Boolean.valueOf(passwordChangeRequired));
            return mav;
        } catch (Exception e) {
            logger.error("로그인 처리 오류. userId=" + userId, e);
            return fail("로그인 처리 중 오류가 발생했습니다.");
        }
    }

    private boolean isPasswordChangeRequired(String expiryYmd) {
        if (expiryYmd == null || expiryYmd.trim().length() == 0) return false;
        try { return !LocalDate.parse(expiryYmd.substring(0, Math.min(10, expiryYmd.length()))).isAfter(LocalDate.now()); }
        catch (DateTimeParseException e) { return false; }
    }

    @RequestMapping(value = "/login/logout.do")
    public String logout(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        if (session != null) {
            UserVO user = (UserVO) session.getAttribute("loginUser");
            try { userService.recordLogout(user); } catch (Exception e) { logger.warn("로그아웃 이력 저장 실패", e); }
            SessionListener.unregister(session);
            session.invalidate();
        }
        return "redirect:/login/login.do";
    }
}
