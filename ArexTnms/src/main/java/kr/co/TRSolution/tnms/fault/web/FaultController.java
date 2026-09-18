package kr.co.TRSolution.tnms.fault.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class FaultController {
    @RequestMapping(value = "/fault/realtime.do", method = RequestMethod.GET)
    public String realtime() { return "fault/realtime"; }

    @RequestMapping(value = "/fault/history.do", method = RequestMethod.GET)
    public String history() { return "fault/history"; }

    @RequestMapping(value = "/fault/exceptions.do", method = RequestMethod.GET)
    public String exceptions() { return "fault/exceptions"; }

    @RequestMapping(value = "/fault/types.do", method = RequestMethod.GET)
    public String types() { return "fault/types"; }
}
