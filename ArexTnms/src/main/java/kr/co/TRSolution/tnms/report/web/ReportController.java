package kr.co.TRSolution.tnms.report.web;

import java.net.URLEncoder;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletResponse;

import org.apache.poi.ss.usermodel.Cell;
import org.apache.poi.ss.usermodel.Row;
import org.apache.poi.ss.usermodel.Sheet;
import org.apache.poi.ss.usermodel.Workbook;
import org.apache.poi.xssf.usermodel.XSSFWorkbook;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.common.BaseController;
import kr.co.TRSolution.tnms.report.service.ReportService;
import kr.co.TRSolution.tnms.report.vo.ReportVO;

@Controller
public class ReportController extends BaseController {
    @Resource(name = "reportService") private ReportService reportService;

    @RequestMapping(value = "/report/fault-performance.do", method = RequestMethod.GET)
    public String faultPerformance() { return "report/faultPerformance"; }

    @RequestMapping(value = "/report/fault-performance/data.ajax", method = RequestMethod.GET)
    public ModelAndView data(@ModelAttribute ReportVO searchVO) {
        try { return success(reportService.selectFaultPerformance(searchVO)); }
        catch (Exception e) { return fail(e.getMessage() == null ? "보고서 조회 중 오류가 발생했습니다." : e.getMessage()); }
    }

    @SuppressWarnings("unchecked")
    @RequestMapping(value = "/report/fault-performance/excel.do", method = RequestMethod.GET)
    public void excel(@ModelAttribute ReportVO searchVO, HttpServletResponse response) throws Exception {
        Map<String, Object> data = reportService.selectFaultPerformance(searchVO);
        List<Map<String, Object>> details = (List<Map<String, Object>>) data.get("details");
        Workbook wb = new XSSFWorkbook();
        try {
            Sheet sheet = wb.createSheet("장애현황");
            String[] headers = {"NO","역명","설비명","장비명","IP","발생시간","이관/종료시간","총 장애시간(초)","등급","장애내용"};
            Row hr = sheet.createRow(0);
            for (int i=0;i<headers.length;i++) hr.createCell(i).setCellValue(headers[i]);
            int r = 1;
            if (details != null) {
                for (Map<String, Object> x : details) {
                    Row row = sheet.createRow(r);
                    set(row,0,r++); set(row,1,x.get("stnNm")); set(row,2,x.get("linkSysNm")); set(row,3,x.get("eqpmntNm"));
                    set(row,4,x.get("ipAddr")); set(row,5,x.get("ocrnDt")); set(row,6,x.get("transferEndDt")); set(row,7,x.get("durationSec"));
                    set(row,8,x.get("gradeCd")); set(row,9,x.get("faultCn"));
                }
            }
            for (int i=0;i<headers.length;i++) sheet.autoSizeColumn(i);
            String filename = URLEncoder.encode("TNMS_장애성능보고서.xlsx", "UTF-8").replace("+", "%20");
            response.setContentType("application/vnd.openxmlformats-officedocument.spreadsheetml.sheet");
            response.setHeader("Content-Disposition", "attachment; filename*=UTF-8''" + filename);
            wb.write(response.getOutputStream());
            response.getOutputStream().flush();
        } finally { wb.close(); }
    }

    private void set(Row row, int idx, Object value) {
        Cell cell = row.createCell(idx);
        cell.setCellValue(value == null ? "" : String.valueOf(value));
    }
}
