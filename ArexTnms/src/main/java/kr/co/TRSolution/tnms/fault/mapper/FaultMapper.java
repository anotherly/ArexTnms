package kr.co.TRSolution.tnms.fault.mapper;

import java.util.List;
import java.util.Map;

import egovframework.rte.psl.dataaccess.mapper.Mapper;

@Mapper("faultMapper")
public interface FaultMapper {
    List<Map<String, Object>> selectLinkSystems();
    List<Map<String, Object>> selectStations();
    List<Map<String, Object>> selectFaultGradeCodes();
    List<Map<String, Object>> selectProcessStatusCodes();
    Map<String, Object> selectRealtimeSummary(Map<String, Object> params);
    List<Map<String, Object>> selectRealtimeFaults(Map<String, Object> params);
    List<Map<String, Object>> selectHistoryFaults(Map<String, Object> params);
    Map<String, Object> selectHistorySummary(Map<String, Object> params);
    Map<String, Object> selectFaultDetail(String dsbltyNo);
    List<Map<String, Object>> selectFaultActions(String dsbltyNo);
    int updateFault(Map<String, Object> params);
    int updateFaultStatus(Map<String, Object> params);
    int insertFaultAction(Map<String, Object> params);
    List<Map<String, Object>> selectFaultTypes(Map<String, Object> params);
    Map<String, Object> selectFaultType(Long dsbltyTypeSn);
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
