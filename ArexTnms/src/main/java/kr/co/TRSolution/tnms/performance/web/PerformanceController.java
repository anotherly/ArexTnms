package kr.co.TRSolution.tnms.performance.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class PerformanceController {
    @RequestMapping(value = "/performance/overview.do", method = RequestMethod.GET)
    public String overview() { return "performance/overview"; }

    @RequestMapping(value = "/performance/cycle.do", method = RequestMethod.GET)
    public String cycle() { return "performance/cycle"; }

    @RequestMapping(value = "/performance/threshold.do", method = RequestMethod.GET)
    public String threshold() { return "performance/threshold"; }

    @RequestMapping(value = "/performance/raw.do", method = RequestMethod.GET)
    public String raw() { return "performance/raw"; }
}
