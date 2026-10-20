package kr.co.TRSolution.tnms.performance.service;

import java.util.Map;

public interface PerformanceService {
    Map<String, Object> selectOverview(Map<String, Object> params);
    Map<String, Object> selectCycleData(Map<String, Object> params);
    Map<String, Object> selectThresholdData(Map<String, Object> params);
    Map<String, Object> selectRawData(Map<String, Object> params);
    Map<String, Object> selectCycle(Long clctCycleSn);
    void saveCycle(Map<String, Object> params, String actorId);
    Map<String, Object> selectThreshold(Long thrshldSn, String perfIdctCd);
    Long saveThreshold(Map<String, Object> params, String actorId);
}
