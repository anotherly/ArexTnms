package kr.co.TRSolution.tnms.report.service.impl;

import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;

import kr.co.TRSolution.tnms.gateway.service.GatewayLiveService;
import kr.co.TRSolution.tnms.report.mapper.ReportMapper;
import kr.co.TRSolution.tnms.report.service.ReportService;
import kr.co.TRSolution.tnms.report.vo.ReportVO;

@Service("reportService")
public class ReportServiceImpl implements ReportService {
    @Resource(name = "reportMapper") private ReportMapper reportMapper;
    @Resource(name = "gatewayLiveService") private GatewayLiveService gatewayLiveService;

    @Override
    public Map<String, Object> selectFaultPerformance(ReportVO searchVO) {
        if (searchVO == null) searchVO = new ReportVO();
        defaultDates(searchVO);
        // 보고서 또한 데이터 조회권한을 서버에서 계산해 원천 로그에 적용한다.
        Map<String,Object> filter = new HashMap<String,Object>();
        filter.put("linkSysCd", searchVO.getLinkSysCd());
        @SuppressWarnings("unchecked")
        List<Integer> allowed = (List<Integer>) gatewayLiveService.scope(filter).get("allowedEmsIds");
        searchVO.setAllowedEmsIds(allowed);
        if (searchVO.getStartDate().compareTo(searchVO.getEndDate()) > 0)
            throw new IllegalArgumentException("조회 시작일은 종료일보다 늦을 수 없습니다.");
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
