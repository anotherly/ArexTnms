package kr.co.TRSolution.tnms.report.mapper;

import java.util.List;
import java.util.Map;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.report.vo.ReportVO;

@Mapper("reportMapper")
public interface ReportMapper {
    ReportVO selectFaultSummary(ReportVO searchVO);
    List<Map<String, Object>> selectDailyFaultSummary(ReportVO searchVO);
    List<Map<String, Object>> selectFaultSystemSummary(ReportVO searchVO);
    List<Map<String, Object>> selectFaultStationSummary(ReportVO searchVO);
    List<Map<String, Object>> selectFaultDetailList(ReportVO searchVO);
}
