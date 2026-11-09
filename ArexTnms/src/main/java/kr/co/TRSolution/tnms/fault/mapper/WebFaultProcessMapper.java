package kr.co.TRSolution.tnms.fault.mapper;
import java.util.List;
import java.util.Map;
import egovframework.rte.psl.dataaccess.mapper.Mapper;
/** Web-only operator workflow. Never modifies raw_event_action/log. */
@Mapper("webFaultProcessMapper")
public interface WebFaultProcessMapper {
    List<Map<String,Object>> selectWebThresholdFaults(Map<String,Object> scope);
    List<Map<String,Object>> selectWebThresholdHistory(Map<String,Object> scope);
    Map<String,Object> selectWebThresholdDetail(Map<String,Object> scope);
    Map<String,Object> selectState(String faultKey);
    List<Map<String,Object>> selectStates(Map<String,Object> keys);
    int ensureState(String faultKey);
    int updateState(Map<String,Object> params);
    int insertAction(Map<String,Object> params);
    List<Map<String,Object>> selectActions(String faultKey);
}
