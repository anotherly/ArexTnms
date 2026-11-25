package kr.co.TRSolution.tnms.setting.web;

import java.util.List;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.audit.service.AuditService;
import kr.co.TRSolution.tnms.common.BaseController;
import kr.co.TRSolution.tnms.common.util.ClientIpUtil;
import kr.co.TRSolution.tnms.setting.service.SettingService;
import kr.co.TRSolution.tnms.setting.vo.CommonCodeVO;
import kr.co.TRSolution.tnms.setting.vo.UiSettingVO;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Controller
public class SettingController extends BaseController {
    @Resource(name = "settingService") private SettingService settingService;
    @Resource(name = "auditService") private AuditService auditService;
    @RequestMapping(value = "/setting/common-ui.do", method = RequestMethod.GET)
    public String commonUi() { return "setting/commonUi"; }

    @RequestMapping(value = "/setting/common-ui/data.ajax", method = RequestMethod.GET)
    public ModelAndView data(@RequestParam(value = "groupId", required = false) String groupId) {
        try { return success(settingService.selectSettings(groupId)); }
        catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/setting/common-ui/ui.ajax", method = RequestMethod.POST)
    public ModelAndView saveUi(@RequestBody List<UiSettingVO> list, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            settingService.saveUiSettings(list, actor.getUserId());
            auditService.record(actor, ClientIpUtil.getClientIp(request), "공통코드·UI 설정", "MDFCN", "UI", "UI 설정 저장", "SUCCESS");
            return success("UI 설정을 저장했습니다.", null);
        } catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/setting/common-ui/code.ajax", method = RequestMethod.POST)
    public ModelAndView saveCode(CommonCodeVO vo, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            settingService.saveCommonCode(vo, actor.getUserId());
            auditService.record(actor, ClientIpUtil.getClientIp(request), "공통코드·UI 설정", "MDFCN", vo.getComCdGroupId() + ":" + vo.getComCd(), "공통코드 저장", "SUCCESS");
            return success("공통코드를 저장했습니다.", null);
        } catch (Exception e) { return fail(message(e)); }
    }

    private String message(Exception e) { return e.getMessage() == null ? "처리 중 오류가 발생했습니다." : e.getMessage(); }
}
