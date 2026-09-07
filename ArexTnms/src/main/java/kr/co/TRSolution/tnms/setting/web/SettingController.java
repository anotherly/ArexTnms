package kr.co.TRSolution.tnms.setting.web;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

@Controller
public class SettingController {
    @RequestMapping(value = "/setting/common-ui.do", method = RequestMethod.GET)
    public String commonUi() { return "setting/commonUi"; }
}
