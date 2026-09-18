package kr.co.TRSolution.tnms.audit.web;

import javax.annotation.Resource;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.audit.service.AuditService;
import kr.co.TRSolution.tnms.audit.vo.AuditVO;
import kr.co.TRSolution.tnms.common.BaseController;

@Controller
public class AuditPageController extends BaseController {
    @Resource(name = "auditService") private AuditService auditService;
    @RequestMapping(value = "/audit/job-log.do", method = RequestMethod.GET)
    public String jobLog() { return "audit/jobLog"; }

    @RequestMapping(value = "/audit/job-log/list.ajax", method = RequestMethod.GET)
    public ModelAndView list(@ModelAttribute AuditVO searchVO) {
        try { return success(auditService.selectJobLogList(searchVO)); }
        catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/audit/job-log/detail.ajax", method = RequestMethod.GET)
    public ModelAndView detail(@RequestParam("jobLogSn") Long jobLogSn) {
        try { return success(auditService.selectJobLog(jobLogSn)); }
        catch (Exception e) { return fail(message(e)); }
    }

    private String message(Exception e) { return e.getMessage() == null ? "처리 중 오류가 발생했습니다." : e.getMessage(); }
}
