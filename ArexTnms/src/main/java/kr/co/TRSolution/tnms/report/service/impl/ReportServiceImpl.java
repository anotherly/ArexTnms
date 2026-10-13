package kr.co.TRSolution.tnms.report.service.impl;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import kr.co.TRSolution.tnms.report.mapper.ReportMapper;
import kr.co.TRSolution.tnms.report.service.ReportService;
import kr.co.TRSolution.tnms.report.vo.ReportVO;

@Service("reportService")
public class ReportServiceImpl implements ReportService {
    @Resource(name = "reportMapper") private ReportMapper reportMapper;

    @Override
    public Map<String, Object> selectFaultPerformance(ReportVO searchVO) {
        if (searchVO == null) searchVO = new ReportVO();
        defaultDates(searchVO);
        List<Map<String,Object>> daily=reportMapper.selectDailyFaultSummary(searchVO);
        if ((searchVO.getSelectedDate()==null || searchVO.getSelectedDate().trim().length()==0) && daily!=null && !daily.isEmpty()) {
            Object latest=daily.get(daily.size()-1).get("reportDate");
            if(latest!=null) searchVO.setSelectedDate(String.valueOf(latest));
        }
        Map<String, Object> result = new HashMap<String, Object>();
        result.put("condition", searchVO);
        result.put("summary", reportMapper.selectFaultSummary(searchVO));
        result.put("daily", daily);
        result.put("systems", reportMapper.selectFaultSystemSummary(searchVO));
        result.put("stations", reportMapper.selectFaultStationSummary(searchVO));
        result.put("details", reportMapper.selectFaultDetailList(searchVO));
        return result;
    }

    private void defaultDates(ReportVO vo) {
        Calendar cal = Calendar.getInstance();
        SimpleDateFormat f = new SimpleDateFormat("yyyy-MM-dd");
        if (vo.getEndDate() == null || vo.getEndDate().trim().length() == 0) vo.setEndDate(f.format(cal.getTime()));
        if (vo.getStartDate() == null || vo.getStartDate().trim().length() == 0) {
            cal.add(Calendar.DAY_OF_MONTH, -6);
            vo.setStartDate(f.format(cal.getTime()));
        }
    }
}
