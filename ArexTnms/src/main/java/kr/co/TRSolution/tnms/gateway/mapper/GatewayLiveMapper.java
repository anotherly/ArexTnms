package kr.co.TRSolution.tnms.gateway.mapper;

import java.util.List;
import java.util.Map;
import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.monitoring.vo.EquipmentVO;
import kr.co.TRSolution.tnms.monitoring.vo.StationStatusVO;

/** 게이트웨이 저장 테이블의 읽기 전용 화면 조회. 원천 테이블은 쓰지 않습니다. */
@Mapper("gatewayLiveMapper")
public interface GatewayLiveMapper {
    List<EquipmentVO> selectSystemSummary(Map<String, Object> params);
    List<StationStatusVO> selectStationSummary(Map<String, Object> params);
    List<EquipmentVO> selectStationSystemSummary(Map<String, Object> params);
    List<EquipmentVO> selectEquipmentList(Map<String, Object> params);
    EquipmentVO selectEquipmentSummary(Map<String, Object> params);
    EquipmentVO selectEquipmentByKey(Map<String, Object> params);
    int selectPerformanceEquipmentCount(Map<String, Object> params);
    List<Map<String, Object>> selectPerformanceEquipmentList(Map<String, Object> params);
    List<Map<String, Object>> selectPerformanceTrend(Map<String, Object> params);
    List<Map<String, Object>> selectPerformanceTop5(Map<String, Object> params);
    List<Map<String, Object>> selectIndicatorStates(Map<String, Object> params);
    List<Map<String, Object>> selectGatewayEquipmentRawData(Map<String,Object> params);
    List<Map<String, Object>> selectRealtimeFaults(Map<String, Object> params);
    List<Map<String, Object>> selectFaultHistory(Map<String, Object> params);
    Map<String, Object> selectRealtimeFaultSummary(Map<String, Object> params);
    List<Map<String, Object>> selectFaultGrades(Map<String,Object> args);
    Map<String, Object> selectFaultLogDetail(Map<String,Object> args);
    Map<String, Object> selectFaultDetail(Map<String, Object> params);
    List<Map<String, Object>> selectFaultAction(Map<String, Object> params);
}
