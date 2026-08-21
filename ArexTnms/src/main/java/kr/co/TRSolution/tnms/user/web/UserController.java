package kr.co.TRSolution.tnms.user.web;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.audit.service.AuditService;
import kr.co.TRSolution.tnms.common.BaseController;
import kr.co.TRSolution.tnms.common.util.ClientIpUtil;
import kr.co.TRSolution.tnms.user.service.UserService;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Controller
public class UserController extends BaseController {
    private static final Logger logger = LoggerFactory.getLogger(UserController.class);
    @Resource(name = "userService") private UserService userService;
    @Resource(name = "auditService") private AuditService auditService;

    @RequestMapping(value = "/user/list.ajax", method = RequestMethod.GET)
    public ModelAndView list(@ModelAttribute UserVO searchVO) {
        try { return success(userService.selectUserList(searchVO)); }
        catch (Exception e) { logger.warn("사용자 목록 조회 실패", e); return fail(message(e)); }
    }

    @RequestMapping(value = "/user/detail.ajax", method = RequestMethod.GET)
    public ModelAndView detail(@RequestParam("userSn") Long userSn) {
        try { return success(userService.selectUser(userSn)); }
        catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/user/idCheck.ajax", method = RequestMethod.GET)
    public ModelAndView idCheck(@RequestParam("userId") String userId) {
        try {
            Map<String, Boolean> result = new HashMap<String, Boolean>();
            result.put("available", Boolean.valueOf(userService.isUserIdAvailable(userId)));
            return success(result);
        } catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/user/insert.ajax", method = RequestMethod.POST)
    public ModelAndView insert(@ModelAttribute UserVO userVO, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            userService.createUser(userVO, actor);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "사용자 계정 설정", "REG",
                    userVO.getUserId(), "사용자 등록", "SUCCESS");
            return success("사용자를 등록했습니다.", null);
        } catch (Exception e) {
            logger.warn("사용자 등록 실패", e);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "사용자 계정 설정", "REG",
                    userVO.getUserId(), message(e), "FAIL");
            return fail(message(e));
        }
    }

    @RequestMapping(value = "/user/update.ajax", method = RequestMethod.POST)
    public ModelAndView update(@ModelAttribute UserVO userVO, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            userService.updateUser(userVO, actor);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "사용자 계정 설정", "MDFCN",
                    String.valueOf(userVO.getUserSn()), "사용자 정보 수정", "SUCCESS");
            return success("사용자 정보를 수정했습니다.", null);
        } catch (Exception e) {
            logger.warn("사용자 수정 실패", e);
            return fail(message(e));
        }
    }

    @RequestMapping(value = "/user/delete.ajax", method = RequestMethod.POST)
    public ModelAndView delete(@RequestParam("userSn") Long userSn, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            userService.deleteUser(userSn, actor);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "사용자 계정 설정", "DEL",
                    String.valueOf(userSn), "사용자 삭제", "SUCCESS");
            return success("사용자를 삭제했습니다.", null);
        } catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/user/unlock.ajax", method = RequestMethod.POST)
    public ModelAndView unlock(@RequestParam("userSn") Long userSn, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            userService.unlockUser(userSn, actor);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "사용자 계정 설정", "MDFCN",
                    String.valueOf(userSn), "계정 잠금 해제", "SUCCESS");
            return success("계정 잠금을 해제했습니다.", null);
        } catch (Exception e) { return fail(message(e)); }
    }

    private String message(Exception e) {
        return e.getMessage() == null ? "처리 중 오류가 발생했습니다." : e.getMessage();
    }
}
