package kr.co.TRSolution.tnms.performance.web;

import java.net.URLEncoder;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
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

    @SuppressWarnings("unchecked")
    @RequestMapping(value = "/performance/overview-excel.do", method = RequestMethod.GET)
    public void overviewExcel(@RequestParam Map<String, String> params, HttpServletResponse response) throws Exception {
        Map<String, Object> data = performanceService.selectOverview(copy(params));
        List<Map<String, Object>> rows = (List<Map<String, Object>>) data.get("equipments");
        Workbook wb = new XSSFWorkbook();
        try {
            Sheet sheet = wb.createSheet("성능현황");
            String[] headers = {"시스템","역사","장비명","관리번호","IP","CPU(%)","MEMORY(%)","상태","마지막 수집"};
            Row hr = sheet.createRow(0);
            for (int i=0;i<headers.length;i++) hr.createCell(i).setCellValue(headers[i]);
            int r=1;
            if (rows != null) {
                for (Map<String,Object> x : rows) {
                    Row row=sheet.createRow(r++);
                    set(row,0,x.get("linkSysNm")); set(row,1,x.get("stnNm")); set(row,2,x.get("eqpmntNm"));
                    set(row,3,x.get("eqpmntMngNo")); set(row,4,x.get("ipAddr")); set(row,5,x.get("cpuUsgrt"));
                    set(row,6,x.get("mmryUsgrt")); set(row,7,x.get("sttsCd")); set(row,8,x.get("lastClctDt"));
                }
            }
            writeWorkbook(response, wb, sheet, headers.length, "TNMS_성능현황.xlsx");
        } finally { wb.close(); }
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
            if (actor != null) auditService.record(actor, ClientIpUtil.getClientIp(request), "수집주기 관리", "MDFCN", params.get("clctCycleSn"), "수집주기 수정", "SUCCESS");
            return success("수집주기를 저장했습니다.", null);
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

    @SuppressWarnings("unchecked")
    @RequestMapping(value = "/performance/raw-excel.do", method = RequestMethod.GET)
    public void rawExcel(@RequestParam Map<String, String> params, HttpServletResponse response) throws Exception {
        Map<String,Object> data=performanceService.selectRawData(copy(params));
        List<Map<String,Object>> rows=(List<Map<String,Object>>) data.get("rows");
        boolean itf="interface".equalsIgnoreCase(params.get("tab"));
        Workbook wb=new XSSFWorkbook();
        try {
            Sheet sheet=wb.createSheet(itf?"인터페이스 데이터":"장비 데이터");
            String[] headers=itf
                ? new String[]{"수집일시","시스템","메시지유형","송수신방향","원천IP","데이터구분","수집상태","오류내용"}
                : new String[]{"수집일시","데이터구분","시스템","역사","장비명","관리번호","CPU(%)","MEMORY(%)"};
            Row hr=sheet.createRow(0); for(int i=0;i<headers.length;i++)hr.createCell(i).setCellValue(headers[i]);
            int r=1;
            if(rows!=null){for(Map<String,Object>x:rows){Row row=sheet.createRow(r++);if(itf){
                set(row,0,x.get("clctDt"));set(row,1,x.get("linkSysNm"));set(row,2,x.get("msgTypeNm"));set(row,3,x.get("trsmDrctNm"));
                set(row,4,x.get("souIpAddr"));set(row,5,x.get("dataSeCd"));set(row,6,x.get("clctSttsCd"));set(row,7,x.get("errCn"));
            }else{
                set(row,0,x.get("clctDt")!=null?x.get("clctDt"):x.get("statsDt"));set(row,1,x.get("dataTypeNm"));set(row,2,x.get("linkSysNm"));
                set(row,3,x.get("stnNm"));set(row,4,x.get("eqpmntNm"));set(row,5,x.get("eqpmntMngNo"));set(row,6,x.get("cpuUsgrt"));set(row,7,x.get("mmryUsgrt"));
            }}}
            writeWorkbook(response, wb, sheet, headers.length, itf?"TNMS_인터페이스_RAW.xlsx":"TNMS_장비성능_RAW.xlsx");
        } finally { wb.close(); }
    }

    private void writeWorkbook(HttpServletResponse response, Workbook wb, Sheet sheet, int columns, String filename) throws Exception {
        for (int i=0;i<columns;i++) sheet.autoSizeColumn(i);
        String encoded=URLEncoder.encode(filename,"UTF-8").replace("+","%20");
        response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
        response.setHeader("Content-Disposition", "attachment; filename*=UTF-8''"+encoded);
        wb.write(response.getOutputStream());
        response.getOutputStream().flush();
    }
    private void set(Row row,int idx,Object value){Cell c=row.createCell(idx);c.setCellValue(value==null?"":String.valueOf(value));}
    private Map<String, Object> copy(Map<String, String> src) { return new HashMap<String, Object>(src); }
    private String message(Exception e) { return e.getMessage() == null ? "처리 중 오류가 발생했습니다." : e.getMessage(); }
}
