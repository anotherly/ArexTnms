package kr.co.TRSolution.tnms.monitoring.mapper;

import java.util.List;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.monitoring.vo.EquipmentLinkVO;
import kr.co.TRSolution.tnms.monitoring.vo.EquipmentVO;
import kr.co.TRSolution.tnms.monitoring.vo.ScadaEventVO;
import kr.co.TRSolution.tnms.monitoring.vo.StationStatusVO;

@Mapper("monitoringMapper")
public interface MonitoringMapper {
    List<EquipmentVO> selectSystemSummary();
    List<StationStatusVO> selectStationSummary(EquipmentVO searchVO);
    List<EquipmentVO> selectStationSystemSummary(String stnCd);
    List<EquipmentVO> selectEquipmentList(EquipmentVO searchVO);
    EquipmentVO selectEquipmentSummary(EquipmentVO searchVO);
    EquipmentVO selectEquipment(Long eqpmntSn);
    List<EquipmentVO> selectPidsLseCandidates(EquipmentVO searchVO);
    List<EquipmentLinkVO> selectEquipmentLinks(EquipmentVO searchVO);
    List<ScadaEventVO> selectRecentScadaEvents(EquipmentVO searchVO);
    int insertEquipment(EquipmentVO equipmentVO);
    int updateEquipment(EquipmentVO equipmentVO);
    int disableEquipment(EquipmentVO equipmentVO);
    int deletePidsLseRelations(Long eqpmntSn);
    int insertPidsLseRelation(EquipmentVO relationVO);
}
