package kr.co.TRSolution.tnms.audit.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class AuditPageController {
    @RequestMapping(value = "/audit/job-log.do", method = RequestMethod.GET)
    public String jobLog() { return "audit/jobLog"; }
}
