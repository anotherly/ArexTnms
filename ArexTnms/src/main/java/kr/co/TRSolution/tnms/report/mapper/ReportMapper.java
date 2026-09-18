package kr.co.TRSolution.tnms.report.mapper;

import java.util.List;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.report.vo.ReportVO;

@Mapper("reportMapper")
public interface ReportMapper {
    ReportVO selectFaultSummary(ReportVO searchVO);
    List<ReportVO> selectFaultSystemSummary(ReportVO searchVO);
}
