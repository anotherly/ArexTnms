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
import kr.co.TRSolution.tnms.gateway.service.GatewayLiveService;
import kr.co.TRSolution.tnms.monitoring.vo.EquipmentVO;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Controller
public class MonitoringController extends BaseController {
    @Resource(name = "monitoringService") private MonitoringService monitoringService;
    @Resource(name = "gatewayLiveService") private GatewayLiveService gatewayLiveService;
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

    /** 실데이터 장비의 복합키 조회. 기존 웹 장비 일련번호와 혼용하지 않습니다. */
    @RequestMapping(value = "/facility/gateway-detail.ajax", method = RequestMethod.GET)
    public ModelAndView gatewayDetail(@RequestParam("emsId") Integer emsId,
                                       @RequestParam("deviceId") String deviceId) {
        try { return success(gatewayLiveService.device(emsId.intValue(), deviceId)); }
        catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/facility/save.ajax", method = RequestMethod.POST)
    public ModelAndView save(@ModelAttribute EquipmentVO equipmentVO, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            Long sn = monitoringService.saveEquipment(equipmentVO, actor.getUserId());
            auditService.record(actor, ClientIpUtil.getClientIp(request), "설비관리",
                equipmentVO.getGatewayDeviceId() == null || equipmentVO.getGatewayDeviceId().trim().isEmpty() ? "REG" : "MDFCN",
                equipmentVO.getEmsId() + ":" + equipmentVO.getEqpmntMngNo(), "장비 정보 저장", "SUCCESS");
            return success("장비 정보를 저장했습니다.", sn);
        } catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value="/facility/gateway-delete.ajax",method=RequestMethod.POST)
    public ModelAndView gatewayDelete(@RequestParam("emsId") int emsId,@RequestParam("deviceId") String deviceId,HttpServletRequest request){
        UserVO actor=loginUser(request);
        try {
            monitoringService.deleteEquipmentByKey(emsId,deviceId,actor.getUserId());
            auditService.record(actor,ClientIpUtil.getClientIp(request),"설비관리","DEL",emsId+":"+deviceId,"장비 삭제","SUCCESS");
            return success("장비를 삭제했습니다.",null);
        } catch(Exception e){return fail(message(e));}
    }
    @RequestMapping(value="/facility/delete.ajax",method=RequestMethod.POST)
    public ModelAndView legacyDelete(@RequestParam("eqpmntSn") Long sn){
        return fail("구형 EQPMNT_SN 삭제는 지원하지 않습니다. EMS ID와 장비 ID를 사용하세요.");
    }

    private String message(Exception e) { return e.getMessage() == null ? "처리 중 오류가 발생했습니다." : e.getMessage(); }
}
