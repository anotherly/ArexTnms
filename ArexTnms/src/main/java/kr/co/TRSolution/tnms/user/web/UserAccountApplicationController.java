package kr.co.TRSolution.tnms.user.web;

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
import kr.co.TRSolution.tnms.user.service.UserAccountApplicationService;
import kr.co.TRSolution.tnms.user.vo.UserAccountApplicationVO;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Controller
public class UserAccountApplicationController extends BaseController {
    private static final Logger logger = LoggerFactory.getLogger(UserAccountApplicationController.class);

    @Resource(name = "userAccountApplicationService")
    private UserAccountApplicationService applicationService;

    @Resource(name = "auditService")
    private AuditService auditService;

    @RequestMapping(value = "/login/account-application.do", method = RequestMethod.GET)
    public String applicationPage() {
        return "login/account-application";
    }

    @RequestMapping(value = "/login/account-application.ajax", method = RequestMethod.POST)
    public ModelAndView submit(@ModelAttribute UserAccountApplicationVO application) {
        try {
            String applicationNo = applicationService.submit(application);
            ModelAndView mav = success("계정 신청이 접수되었습니다. 관리자 승인 후 사용할 수 있습니다.", null);
            mav.addObject("applicationNo", applicationNo);
            return mav;
        } catch (IllegalArgumentException e) {
            return fail(e.getMessage());
        } catch (Exception e) {
            logger.error("계정 신청 처리 오류. userId=" + application.getUserId(), e);
            return fail("계정 신청 처리 중 오류가 발생했습니다.");
        }
    }

    @RequestMapping(value = "/user/applications/list.ajax", method = RequestMethod.GET)
    public ModelAndView list(@ModelAttribute UserAccountApplicationVO searchVO) {
        try {
            return success(applicationService.selectApplicationList(searchVO));
        } catch (Exception e) {
            logger.warn("계정 신청 목록 조회 실패", e);
            return fail(message(e));
        }
    }

    @RequestMapping(value = "/user/applications/detail.ajax", method = RequestMethod.GET)
    public ModelAndView detail(@RequestParam("aplySn") Long aplySn) {
        try {
            return success(applicationService.selectApplication(aplySn));
        } catch (Exception e) {
            return fail(message(e));
        }
    }

    @RequestMapping(value = "/user/applications/approve.ajax", method = RequestMethod.POST)
    public ModelAndView approve(@RequestParam("aplySn") Long aplySn, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            UserAccountApplicationVO application = applicationService.selectApplication(aplySn);
            applicationService.approve(aplySn, actor);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "계정 신청 현황", "MDFCN",
                    application.getAplyNo(), "계정 신청 승인", "SUCCESS");
            return success("계정 신청을 승인했습니다.", null);
        } catch (Exception e) {
            logger.warn("계정 신청 승인 실패. aplySn=" + aplySn, e);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "계정 신청 현황", "MDFCN",
                    String.valueOf(aplySn), message(e), "FAIL");
            return fail(message(e));
        }
    }

    @RequestMapping(value = "/user/applications/reject.ajax", method = RequestMethod.POST)
    public ModelAndView reject(@RequestParam("aplySn") Long aplySn,
                               @RequestParam("rfslRsn") String rfslRsn,
                               HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            UserAccountApplicationVO application = applicationService.selectApplication(aplySn);
            applicationService.reject(aplySn, rfslRsn, actor);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "계정 신청 현황", "MDFCN",
                    application.getAplyNo(), "계정 신청 반려", "SUCCESS");
            return success("계정 신청을 반려했습니다.", null);
        } catch (Exception e) {
            logger.warn("계정 신청 반려 실패. aplySn=" + aplySn, e);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "계정 신청 현황", "MDFCN",
                    String.valueOf(aplySn), message(e), "FAIL");
            return fail(message(e));
        }
    }

    private String message(Exception e) {
        return e.getMessage() == null ? "처리 중 오류가 발생했습니다." : e.getMessage();
    }
}
