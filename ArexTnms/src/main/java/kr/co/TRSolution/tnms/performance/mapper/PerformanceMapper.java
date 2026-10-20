package kr.co.TRSolution.tnms.performance.mapper;

import java.util.List;
import java.util.Map;

import egovframework.rte.psl.dataaccess.mapper.Mapper;

@Mapper("performanceMapper")
public interface PerformanceMapper {
    List<Map<String, Object>> selectLinkSystems();
    List<Map<String, Object>> selectStations();
    List<Map<String, Object>> selectPerformanceIndicatorStates(Map<String, Object> params);
    List<Map<String, Object>> selectPerformanceEquipmentList(Map<String, Object> params);
    List<Map<String, Object>> selectPerformanceTrend(Map<String, Object> params);
    List<Map<String, Object>> selectPerformanceTop5(Map<String, Object> params);
    List<Map<String, Object>> selectCollectionCycles(Map<String, Object> params);
    List<Map<String, Object>> selectCollectionHeatmap(Map<String, Object> params);
    Map<String, Object> selectCollectionCycle(Long clctCycleSn);
    int updateCollectionCycle(Map<String, Object> params);
    List<Map<String, Object>> selectThresholds(Map<String, Object> params);
    Map<String, Object> selectThreshold(Long thrshldSn);
    Map<String, Object> selectThresholdByIndicator(String perfIdctCd);
    int insertThreshold(Map<String, Object> params);
    int updateThreshold(Map<String, Object> params);
    List<Map<String, Object>> selectEquipmentRawData(Map<String, Object> params);
    List<Map<String, Object>> selectInterfaceRawData(Map<String, Object> params);
    Map<String, Object> selectRawRetentionSummary();
}
