package kr.co.TRSolution.tnms.monitoring.web;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.audit.service.AuditService;
import kr.co.TRSolution.tnms.common.BaseController;
import kr.co.TRSolution.tnms.common.util.ClientIpUtil;
import kr.co.TRSolution.tnms.monitoring.service.MonitoringService;
import kr.co.TRSolution.tnms.monitoring.vo.EquipmentVO;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Controller
public class MonitoringController extends BaseController {
    @Resource(name = "monitoringService") private MonitoringService monitoringService;
    @Resource(name = "auditService") private AuditService auditService;

    @RequestMapping(value = "/main/dashboard-data.ajax", method = RequestMethod.GET)
    public ModelAndView dashboard() {
        try { return success(monitoringService.selectDashboard()); }
        catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/main/dashboard-station.ajax", method = RequestMethod.GET)
    public ModelAndView dashboardStation(@RequestParam("stnCd") String stnCd) {
        try { return success(monitoringService.selectStationSystemSummary(stnCd)); }
        catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/main/dashboard-system-stations.ajax", method = RequestMethod.GET)
    public ModelAndView dashboardSystemStations(@RequestParam("linkSysCd") String linkSysCd) {
        try {
            EquipmentVO searchVO = new EquipmentVO();
            searchVO.setLinkSysCd(linkSysCd);
            return success(monitoringService.selectStationSummary(searchVO));
        } catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/facility/data.ajax", method = RequestMethod.GET)
    public ModelAndView facility(@ModelAttribute EquipmentVO searchVO) {
        try { return success(monitoringService.selectFacility(searchVO)); }
        catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/facility/detail.ajax", method = RequestMethod.GET)
    public ModelAndView detail(@RequestParam("eqpmntSn") Long eqpmntSn) {
        try { return success(monitoringService.selectEquipment(eqpmntSn)); }
        catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/facility/save.ajax", method = RequestMethod.POST)
    public ModelAndView save(@ModelAttribute EquipmentVO equipmentVO, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            Long sn = monitoringService.saveEquipment(equipmentVO, actor.getUserId());
            auditService.record(actor, ClientIpUtil.getClientIp(request), "설비관리", equipmentVO.getEqpmntSn() == null ? "REG" : "MDFCN", String.valueOf(sn), "장비 정보 저장", "SUCCESS");
            return success("장비 정보를 저장했습니다.", sn);
        } catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/facility/delete.ajax", method = RequestMethod.POST)
    public ModelAndView delete(@RequestParam("eqpmntSn") Long eqpmntSn, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            monitoringService.deleteEquipment(eqpmntSn, actor.getUserId());
            auditService.record(actor, ClientIpUtil.getClientIp(request), "설비관리", "DEL", String.valueOf(eqpmntSn), "장비 미사용 처리", "SUCCESS");
            return success("장비를 삭제했습니다.", null);
        } catch (Exception e) { return fail(message(e)); }
    }

    private String message(Exception e) { return e.getMessage() == null ? "처리 중 오류가 발생했습니다." : e.getMessage(); }
}
