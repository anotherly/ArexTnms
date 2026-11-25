package kr.co.TRSolution.tnms.monitoring.mapper;
import java.util.List;
import java.util.Map;
import egovframework.rte.psl.dataaccess.mapper.Mapper;
/** 기존 web_eqpmnt_info / web_gateway_device_ref 없이 원천 설비유형만 조회. */
@Mapper("monitoringMapper")
public interface MonitoringMapper {
    int insertGatewayDevice(kr.co.TRSolution.tnms.monitoring.vo.EquipmentVO vo);
    int updateGatewayDevice(kr.co.TRSolution.tnms.monitoring.vo.EquipmentVO vo);
    int deleteGatewayDevice(Map<String,Object> params);
    int countGatewayDevice(Map<String,Object> params);
    List<Map<String,Object>> selectEquipmentClassifications(String linkSysCd);
}
