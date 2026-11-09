package kr.co.TRSolution.tnms.performance.web;

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
import kr.co.TRSolution.tnms.performance.service.PingCycleService;
import kr.co.TRSolution.tnms.user.vo.UserVO;

/** 기존 수집주기관리 화면의 com_ping_info CRUD. */
@Controller
public class PingCycleController extends BaseController {
    @Resource(name="pingCycleService") private PingCycleService pingCycleService;
    @Resource(name="auditService") private AuditService auditService;

    @RequestMapping(value="/performance/ping-cycle-data.ajax", method=RequestMethod.GET)
    public ModelAndView data(@RequestParam Map<String,String> params) {
        try { return success(pingCycleService.selectData(params)); }
        catch (Exception e) { return fail(error(e)); }
    }

    @RequestMapping(value="/performance/ping-cycle-detail.ajax", method=RequestMethod.GET)
    public ModelAndView detail(@RequestParam("emsId") Integer emsId,
                               @RequestParam("dataSeCd") String dataSeCd) {
        try { return success(pingCycleService.selectDetail(emsId, dataSeCd)); }
        catch (Exception e) { return fail(error(e)); }
    }

    @RequestMapping(value="/performance/ping-cycle-save.ajax", method=RequestMethod.POST)
    public ModelAndView save(@RequestParam Map<String,String> params, HttpServletRequest request) {
        try {
            UserVO actor = loginUser(request);
            if (actor == null) return fail("로그인이 필요합니다.");
            pingCycleService.save(params, actor.getUserId());
            String action = "CREATE".equals(params.get("mode")) ? "REG" : "MDFCN";
            auditService.record(actor, ClientIpUtil.getClientIp(request), "수집주기 관리", action,
                    params.get("emsId")+":"+params.get("dataSeCd"), "com_ping_info 설정 저장", "SUCCESS");
            return success("com_ping_info 수집주기 설정을 저장했습니다.", null);
        } catch (Exception e) { return fail(error(e)); }
    }

    @RequestMapping(value="/performance/ping-cycle-delete.ajax", method=RequestMethod.POST)
    public ModelAndView delete(@RequestParam("emsId") Integer emsId,
                               @RequestParam("dataSeCd") String dataSeCd, HttpServletRequest request) {
        try {
            UserVO actor = loginUser(request);
            if (actor == null) return fail("로그인이 필요합니다.");
            pingCycleService.delete(emsId, dataSeCd);
            auditService.record(actor, ClientIpUtil.getClientIp(request), "수집주기 관리", "DEL",
                    emsId+":"+dataSeCd, "com_ping_info 설정 삭제", "SUCCESS");
            return success("수집주기 설정을 삭제했습니다.", null);
        } catch (Exception e) { return fail(error(e)); }
    }

    private String error(Exception e) { return e.getMessage()==null ? "처리 중 오류가 발생했습니다." : e.getMessage(); }
}
