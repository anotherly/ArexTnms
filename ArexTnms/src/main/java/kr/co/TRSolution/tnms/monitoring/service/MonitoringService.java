package kr.co.TRSolution.tnms.monitoring.service;

import java.util.List;
import java.util.Map;

import kr.co.TRSolution.tnms.monitoring.vo.EquipmentVO;
import kr.co.TRSolution.tnms.monitoring.vo.StationStatusVO;

public interface MonitoringService {
    Map<String, Object> selectDashboard();
    Map<String, Object> selectFacility(EquipmentVO searchVO);
    List<StationStatusVO> selectStationSummary(EquipmentVO searchVO);
    List<EquipmentVO> selectStationSystemSummary(String stnCd);
    EquipmentVO selectEquipment(Long eqpmntSn);
    Long saveEquipment(EquipmentVO equipmentVO, String actorId);
    void deleteEquipment(Long eqpmntSn, String actorId);
}
