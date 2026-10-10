package kr.co.TRSolution.tnms.performance.web;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.audit.service.AuditService;
import kr.co.TRSolution.tnms.common.BaseController;
import kr.co.TRSolution.tnms.common.util.ClientIpUtil;
import kr.co.TRSolution.tnms.performance.service.PerformanceService;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Controller
public class PerformanceController extends BaseController {
    @Resource(name = "performanceService") private PerformanceService performanceService;
    @Resource(name = "auditService") private AuditService auditService;

    @RequestMapping(value = "/performance/overview.do", method = RequestMethod.GET)
    public String overview() { return "performance/overview"; }
    @RequestMapping(value = "/performance/cycle.do", method = RequestMethod.GET)
    public String cycle() { return "performance/cycle"; }
    @RequestMapping(value = "/performance/threshold.do", method = RequestMethod.GET)
    public String threshold() { return "performance/threshold"; }
    @RequestMapping(value = "/performance/raw.do", method = RequestMethod.GET)
    public String raw() { return "performance/raw"; }

    @RequestMapping(value = "/performance/overview-data.ajax", method = RequestMethod.GET)
    public ModelAndView overviewData(@RequestParam Map<String, String> params) {
        try { return success(performanceService.selectOverview(copy(params))); }
        catch (Exception e) { return fail(message(e)); }
    }
    @RequestMapping(value = "/performance/equipment-detail.ajax", method = RequestMethod.GET)
    public ModelAndView equipmentDetail(@RequestParam Map<String, String> params) {
        try {
            if (params.get("eqpmntSn") == null || params.get("eqpmntSn").trim().length() == 0) return fail("장비를 선택해 주세요.");
            return success(performanceService.selectOverview(copy(params)));
        } catch (Exception e) { return fail(message(e)); }
    }

    @RequestMapping(value = "/performance/cycle-data.ajax", method = RequestMethod.GET)
    public ModelAndView cycleData(@RequestParam Map<String, String> params) {
        try { return success(performanceService.selectCycleData(copy(params))); }
        catch (Exception e) { return fail(message(e)); }
    }
    @RequestMapping(value = "/performance/cycle-detail.ajax", method = RequestMethod.GET)
    public ModelAndView cycleDetail(@RequestParam("clctCycleSn") Long sn) {
        try { return success(performanceService.selectCycle(sn)); }
        catch (Exception e) { return fail(message(e)); }
    }
    @RequestMapping(value = "/performance/cycle-save.ajax", method = RequestMethod.POST)
    public ModelAndView cycleSave(@RequestParam Map<String, String> params, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            performanceService.saveCycle(copy(params), actor == null ? null : actor.getUserId());
            if (actor != null) auditService.record(actor, ClientIpUtil.getClientIp(request), "수집주기 관리", "MDFCN", params.get("clctCycleSn"), "연동주기 수정", "SUCCESS");
            return success("연동주기를 저장했습니다.", null);
        } catch (Exception e) { return fail(message(e)); }
    }
    @RequestMapping(value = "/performance/threshold-data.ajax", method = RequestMethod.GET)
    public ModelAndView thresholdData(@RequestParam Map<String, String> params) {
        try { return success(performanceService.selectThresholdData(copy(params))); }
        catch (Exception e) { return fail(message(e)); }
    }
    @RequestMapping(value = "/performance/threshold-detail.ajax", method = RequestMethod.GET)
    public ModelAndView thresholdDetail(@RequestParam(value="thrshldSn", required=false) Long sn,
                                        @RequestParam(value="perfIdctCd", required=false) String perfIdctCd) {
        try { return success(performanceService.selectThreshold(sn, perfIdctCd)); }
        catch (Exception e) { return fail(message(e)); }
    }
    @RequestMapping(value = "/performance/threshold-save.ajax", method = RequestMethod.POST)
    public ModelAndView thresholdSave(@RequestParam Map<String, String> params, HttpServletRequest request) {
        UserVO actor = loginUser(request);
        try {
            Long sn = performanceService.saveThreshold(copy(params), actor == null ? null : actor.getUserId());
            if (actor != null) auditService.record(actor, ClientIpUtil.getClientIp(request), "임계치 관리", "MDFCN", String.valueOf(sn), "임계치 저장", "SUCCESS");
            return success("임계치를 저장했습니다.", sn);
        } catch (Exception e) { return fail(message(e)); }
    }
    @RequestMapping(value = "/performance/raw-data.ajax", method = RequestMethod.GET)
    public ModelAndView rawData(@RequestParam Map<String, String> params) {
        try { return success(performanceService.selectRawData(copy(params))); }
        catch (Exception e) { return fail(message(e)); }
    }

    private Map<String, Object> copy(Map<String, String> src) { return new HashMap<String, Object>(src); }
    private String message(Exception e) { return e.getMessage() == null ? "처리 중 오류가 발생했습니다." : e.getMessage(); }
}
