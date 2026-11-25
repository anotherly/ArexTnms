package kr.co.TRSolution.tnms.fault.mapper;
import java.util.List;
import java.util.Map;
import egovframework.rte.psl.dataaccess.mapper.Mapper;
/** 모든 장애데이터는 raw_event_log / raw_event_action에서만 읽습니다. */
@Mapper("faultMapper")
public interface FaultMapper {
    List<Map<String,Object>> selectLinkSystems();
    List<Map<String,Object>> selectStations();
    List<Map<String,Object>> selectFaultTypes(Map<String,Object> params);
    Map<String,Object> selectFaultType(Map<String,Object> params);
    List<Map<String, Object>> selectExceptionGroups();
    Map<String, Object> selectExceptionGroup(Long groupSn);
    List<Map<String, Object>> selectExceptionGroupMembers(Long groupSn);
    List<Map<String, Object>> selectExceptionEquipmentCandidates(Map<String, Object> params);
    int insertExceptionGroup(Map<String, Object> params);
    int updateExceptionGroup(Map<String, Object> params);
    int deleteExceptionGroupMemberIndicators(Long groupSn);
    int deleteExceptionGroupMembers(Long groupSn);
    int insertExceptionGroupMember(Map<String, Object> params);
    int deleteExceptionScheduleGradesByGroup(Long groupSn);
    int deleteExceptionSchedulesByGroup(Long groupSn);
    int deleteExceptionGroup(Long groupSn);
    List<Map<String, Object>> selectExceptionSchedules(Map<String, Object> params);
    Map<String, Object> selectExceptionSchedule(Long scheduleSn);
    List<String> selectExceptionScheduleGrades(Long scheduleSn);
    int insertExceptionSchedule(Map<String, Object> params);
    int updateExceptionSchedule(Map<String, Object> params);
    int deleteExceptionScheduleGrades(Long scheduleSn);
    int insertExceptionScheduleGrade(Map<String, Object> params);
    int deleteExceptionSchedule(Long scheduleSn);

}
