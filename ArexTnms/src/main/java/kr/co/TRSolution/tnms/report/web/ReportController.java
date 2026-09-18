package kr.co.TRSolution.tnms.report.web;

import javax.annotation.Resource;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.common.BaseController;
import kr.co.TRSolution.tnms.report.service.ReportService;
import kr.co.TRSolution.tnms.report.vo.ReportVO;

@Controller
public class ReportController extends BaseController {
    @Resource(name = "reportService") private ReportService reportService;
    @RequestMapping(value = "/report/fault-performance.do", method = RequestMethod.GET)
    public String faultPerformance() { return "report/faultPerformance"; }

    @RequestMapping(value = "/report/fault-performance/data.ajax", method = RequestMethod.GET)
    public ModelAndView data(@ModelAttribute ReportVO searchVO) {
        try { return success(reportService.selectFaultPerformance(searchVO)); }
        catch (Exception e) { return fail(e.getMessage() == null ? "보고서 조회 중 오류가 발생했습니다." : e.getMessage()); }
    }
}
