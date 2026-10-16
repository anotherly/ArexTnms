package kr.co.TRSolution.tnms.fault.web;

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
import kr.co.TRSolution.tnms.fault.service.FaultService;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Controller
public class FaultController extends BaseController {
    @Resource(name="faultService") private FaultService faultService;
    @Resource(name="auditService") private AuditService auditService;

    @RequestMapping(value="/fault/realtime.do", method=RequestMethod.GET) public String realtime(){return "fault/realtime";}
    @RequestMapping(value="/fault/history.do", method=RequestMethod.GET) public String history(){return "fault/history";}
    @RequestMapping(value="/fault/exceptions.do", method=RequestMethod.GET) public String exceptions(){return "fault/exceptions";}
    @RequestMapping(value="/fault/types.do", method=RequestMethod.GET) public String types(){return "fault/types";}

    @RequestMapping(value="/fault/realtime-data.ajax", method=RequestMethod.GET)
    public ModelAndView realtimeData(@RequestParam Map<String,String> p){try{return success(faultService.selectRealtime(copy(p)));}catch(Exception e){return fail(msg(e));}}

    @SuppressWarnings("unchecked")
    @RequestMapping(value="/fault/realtime-excel.do", method=RequestMethod.GET)
    public void realtimeExcel(@RequestParam Map<String,String> p, HttpServletResponse response) throws Exception {
        Map<String,Object> data = faultService.selectRealtime(copy(p));
        List<Map<String,Object>> rows = (List<Map<String,Object>>) data.get("faults");
        Workbook wb = new XSSFWorkbook();
        try {
            Sheet sheet = wb.createSheet("실시간장애");
            String[] headers = {"NO.","등급","설비","역사/시설","장비명","IP","장비종류","발생위치","장애유형","장애내용","발생시각","장애판단","임시조치"};
            Row hr = sheet.createRow(0);
            for (int i=0;i<headers.length;i++) hr.createCell(i).setCellValue(headers[i]);
            int rowNo = 1;
            if (rows != null) {
                int displayNo = rows.size();
                for (Map<String,Object> x : rows) {
                    Row row = sheet.createRow(rowNo++);
                    setCell(row,0,displayNo--);
                    setCell(row,1,x.get("dsbltyGrdNm"));
                    setCell(row,2,x.get("linkSysNm"));
                    setCell(row,3,x.get("stnNm"));
                    setCell(row,4,x.get("eqpmntNm"));
                    setCell(row,5,x.get("ipAddr"));
                    setCell(row,6,x.get("eqpmntClsfNm") == null ? x.get("eqpmntSeCd") : x.get("eqpmntClsfNm"));
                    setCell(row,7,x.get("dsbltyOcrnPlcNm"));
                    setCell(row,8,x.get("dsbltyTypeNm"));
                    setCell(row,9,x.get("dsbltyOcrnCn"));
                    setCell(row,10,x.get("dsbltyOcrnDt"));
                    String j = String.valueOf(x.get("dsbltyJgmtCd") == null ? "" : x.get("dsbltyJgmtCd"));
                    setCell(row,11,"SERVICE".equals(j)?"서비스장애":"STATUS".equals(j)?"상태장애":"INFO".equals(j)?"정보":"미판단");
                    setCell(row,12,"Y".equals(String.valueOf(x.get("tempActionYn")))?"입력완료":"미입력");
                }
            }
            for (int i=0;i<headers.length;i++) sheet.autoSizeColumn(i);
            String filename = URLEncoder.encode("TNMS_실시간장애.xlsx", "UTF-8").replace("+", "%20");
            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setHeader("Content-Disposition", "attachment; filename*=UTF-8''" + filename);
            wb.write(response.getOutputStream());
            response.getOutputStream().flush();
        } finally { wb.close(); }
    }
    @RequestMapping(value="/fault/history-data.ajax", method=RequestMethod.GET)
    public ModelAndView historyData(@RequestParam Map<String,String> p){try{return success(faultService.selectHistory(copy(p)));}catch(Exception e){return fail(msg(e));}}
    @SuppressWarnings("unchecked")
    @RequestMapping(value="/fault/history-excel.do", method=RequestMethod.GET)
    public void historyExcel(@RequestParam Map<String,String> p, HttpServletResponse response) throws Exception {
        Map<String,Object> data = faultService.selectHistory(copy(p));
        List<Map<String,Object>> rows = (List<Map<String,Object>>) data.get("faults");
        Workbook wb = new XSSFWorkbook();
        try {
            Sheet sheet = wb.createSheet("장애이력조치");
            String[] headers = {"NO.","등급","장애판단","설비","역사/시설","장비명","IP","장애내용","발생일시","복구일시","조치상태"};
            Row hr = sheet.createRow(0); for(int i=0;i<headers.length;i++) hr.createCell(i).setCellValue(headers[i]);
            int rowNo=1, displayNo=rows==null?0:rows.size();
            if(rows!=null) for(Map<String,Object> x:rows){
                Row row=sheet.createRow(rowNo++); setCell(row,0,displayNo--); setCell(row,1,x.get("dsbltyGrdNm"));
                String j=String.valueOf(x.get("dsbltyJgmtCd")==null?"":x.get("dsbltyJgmtCd"));
                setCell(row,2,"SERVICE".equals(j)?"서비스장애":"STATUS".equals(j)?"상태장애":"INFO".equals(j)?"정보":"미판단");
                setCell(row,3,x.get("linkSysNm")); setCell(row,4,x.get("stnNm")); setCell(row,5,x.get("eqpmntNm")); setCell(row,6,x.get("ipAddr"));
                setCell(row,7,x.get("dsbltyOcrnCn")); setCell(row,8,x.get("dsbltyOcrnDt")); setCell(row,9,x.get("dsbltyEndDt")); setCell(row,10,x.get("prcsSttsNm"));
            }
            for(int i=0;i<headers.length;i++) sheet.autoSizeColumn(i);
            String filename=URLEncoder.encode("TNMS_장애이력조치.xlsx","UTF-8").replace("+","%20");
            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setHeader("Content-Disposition","attachment; filename*=UTF-8''"+filename);
            wb.write(response.getOutputStream()); response.getOutputStream().flush();
        } finally { wb.close(); }
    }
    @RequestMapping(value="/fault/detail.ajax", method=RequestMethod.GET)
    public ModelAndView detail(@RequestParam("dsbltyNo") String no){try{return success(faultService.selectFaultDetail(no));}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/save.ajax", method=RequestMethod.POST)
    public ModelAndView save(@RequestParam Map<String,String> p,HttpServletRequest r){UserVO a=loginUser(r);try{faultService.saveFault(copy(p),id(a),name(a));audit(a,r,"실시간 장애","MDFCN",p.get("dsbltyNo"),"장애 정보 수정");return success("장애 정보를 저장했습니다.",null);}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/judgment.ajax", method=RequestMethod.POST)
    public ModelAndView judgment(@RequestParam("dsbltyNos") String nos,@RequestParam("judgment") String j,HttpServletRequest r){UserVO a=loginUser(r);try{faultService.applyJudgment(nos,j,id(a),name(a));audit(a,r,"실시간 장애","MDFCN",nos,"장애 판단 적용");return success("장애 판단을 적용했습니다.",null);}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/transfer.ajax", method=RequestMethod.POST)
    public ModelAndView transfer(@RequestParam("dsbltyNos") String nos,HttpServletRequest r){UserVO a=loginUser(r);try{faultService.transfer(nos,id(a),name(a));audit(a,r,"실시간 장애","CTRL",nos,"장애 이관");return success("선택 장애를 이관 처리했습니다.",null);}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/complete.ajax", method=RequestMethod.POST)
    public ModelAndView complete(@RequestParam Map<String,String> p,HttpServletRequest r){UserVO a=loginUser(r);try{faultService.complete(copy(p),id(a),name(a));audit(a,r,"장애이력·조치","MDFCN",p.get("dsbltyNo"),"완료조치 등록");return success("완료조치를 등록했습니다.",null);}catch(Exception e){return fail(msg(e));}}

    @RequestMapping(value="/fault/types-data.ajax", method=RequestMethod.GET)
    public ModelAndView typesData(@RequestParam Map<String,String> p){try{return success(faultService.selectTypes(copy(p)));}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/type-detail.ajax", method=RequestMethod.GET)
    public ModelAndView typeDetail(@RequestParam("dsbltyTypeSn") Long sn){try{return success(faultService.selectType(sn));}catch(Exception e){return fail(msg(e));}}

    @RequestMapping(value="/fault/exceptions-data.ajax", method=RequestMethod.GET)
    public ModelAndView exceptionsData(@RequestParam Map<String,String> p){try{return success(faultService.selectExceptions(copy(p)));}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/exception-group-detail.ajax", method=RequestMethod.GET)
    public ModelAndView groupDetail(@RequestParam(value="groupSn",required=false) Long sn){try{return success(faultService.selectExceptionGroup(sn));}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/exception-equipment.ajax", method=RequestMethod.GET)
    public ModelAndView exceptionEquipment(@RequestParam Map<String,String> p){try{return success(faultService.searchExceptionEquipment(copy(p)));}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/exception-group-save.ajax", method=RequestMethod.POST)
    public ModelAndView groupSave(@RequestParam Map<String,String> p,HttpServletRequest r){UserVO a=loginUser(r);try{Long sn=faultService.saveExceptionGroup(copy(p),id(a));audit(a,r,"장애 예외설정","MDFCN",String.valueOf(sn),"예외그룹 저장");return success("예외그룹을 저장했습니다.",sn);}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/exception-group-delete.ajax", method=RequestMethod.POST)
    public ModelAndView groupDelete(@RequestParam("groupSn") Long sn,HttpServletRequest r){UserVO a=loginUser(r);try{faultService.deleteExceptionGroup(sn);audit(a,r,"장애 예외설정","DEL",String.valueOf(sn),"예외그룹 삭제");return success("예외그룹을 삭제했습니다.",null);}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/exception-schedule-detail.ajax", method=RequestMethod.GET)
    public ModelAndView scheduleDetail(@RequestParam("scheduleSn") Long sn){try{return success(faultService.selectExceptionSchedule(sn));}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/exception-schedule-save.ajax", method=RequestMethod.POST)
    public ModelAndView scheduleSave(@RequestParam Map<String,String> p,HttpServletRequest r){UserVO a=loginUser(r);try{Long sn=faultService.saveExceptionSchedule(copy(p),id(a));audit(a,r,"장애 예외설정","MDFCN",String.valueOf(sn),"예외일정 저장");return success("예외일정을 저장했습니다.",sn);}catch(Exception e){return fail(msg(e));}}
    @RequestMapping(value="/fault/exception-schedule-delete.ajax", method=RequestMethod.POST)
    public ModelAndView scheduleDelete(@RequestParam("scheduleSn") Long sn,HttpServletRequest r){UserVO a=loginUser(r);try{faultService.deleteExceptionSchedule(sn);audit(a,r,"장애 예외설정","DEL",String.valueOf(sn),"예외일정 삭제");return success("예외일정을 삭제했습니다.",null);}catch(Exception e){return fail(msg(e));}}

    private void setCell(Row row, int idx, Object value) { Cell cell=row.createCell(idx); cell.setCellValue(value==null?"":String.valueOf(value)); }
    private Map<String,Object> copy(Map<String,String> p){return new HashMap<String,Object>(p);} private String msg(Exception e){return e.getMessage()==null?"처리 중 오류가 발생했습니다.":e.getMessage();}
    private String id(UserVO u){return u==null?null:u.getUserId();} private String name(UserVO u){return u==null?null:u.getUserNm();}
    private void audit(UserVO a,HttpServletRequest r,String menu,String job,String key,String cn){if(a!=null)auditService.record(a,ClientIpUtil.getClientIp(r),menu,job,key,cn,"SUCCESS");}
}
