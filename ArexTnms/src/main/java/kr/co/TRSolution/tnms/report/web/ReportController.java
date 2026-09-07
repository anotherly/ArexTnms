package kr.co.TRSolution.tnms.report.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class ReportController {
    @RequestMapping(value = "/report/fault-performance.do", method = RequestMethod.GET)
    public String faultPerformance() { return "report/faultPerformance"; }
}
