package kr.co.TRSolution.tnms.facility.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class FacilityController {
    @RequestMapping(value = "/facility/transmission.do", method = RequestMethod.GET)
    public String transmission() { return "facility/transmission"; }

    @RequestMapping(value = "/facility/pids.do", method = RequestMethod.GET)
    public String pids() { return "facility/pids"; }

    @RequestMapping(value = "/facility/pbx.do", method = RequestMethod.GET)
    public String pbx() { return "facility/pbx"; }

    @RequestMapping(value = "/facility/cctv.do", method = RequestMethod.GET)
    public String cctv() { return "facility/cctv"; }

    @RequestMapping(value = "/facility/scada.do", method = RequestMethod.GET)
    public String scada() { return "facility/scada"; }
}
