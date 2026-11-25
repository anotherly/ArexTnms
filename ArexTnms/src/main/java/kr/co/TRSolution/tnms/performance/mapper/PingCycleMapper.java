package kr.co.TRSolution.tnms.performance.mapper;

import java.util.List;
import java.util.Map;
import egovframework.rte.psl.dataaccess.mapper.Mapper;

/** com_ping_info 수집/핑 설정 CRUD; 원천 수집 raw/com_device 데이터는 조회 전용. */
@Mapper("pingCycleMapper")
public interface PingCycleMapper {
    List<Map<String,Object>> selectSystems(Map<String,Object> params);
    List<Map<String,Object>> selectCycles(Map<String,Object> params);
    Map<String,Object> selectCycle(Map<String,Object> params);
    List<Map<String,Object>> selectHeatmap(Map<String,Object> params);
    int insertCycle(Map<String,Object> params);
    int updateCycle(Map<String,Object> params);
    int deleteCycle(Map<String,Object> params);
}
