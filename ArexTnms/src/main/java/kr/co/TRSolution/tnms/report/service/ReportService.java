package kr.co.TRSolution.tnms.report.service;

import java.util.Map;

import kr.co.TRSolution.tnms.report.vo.ReportVO;

public interface ReportService {
    Map<String, Object> selectFaultPerformance(ReportVO searchVO);
}
