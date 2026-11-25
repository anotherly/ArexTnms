package kr.co.TRSolution.tnms.fault.service;

import java.util.Map;

public interface FaultService {
    Map<String, Object> selectRealtime(Map<String, Object> params);
    Map<String, Object> selectHistory(Map<String, Object> params);
    Map<String, Object> selectFaultDetail(String dsbltyNo);
    void saveFault(Map<String, Object> params, String actorId, String actorName);
    void applyJudgment(String dsbltyNos, String judgment, String actorId, String actorName);
    void transfer(String dsbltyNos, String actorId, String actorName);
    void complete(Map<String, Object> params, String actorId, String actorName);
    Map<String, Object> selectTypes(Map<String, Object> params);
    Map<String, Object> selectType(Long dsbltyTypeSn);
    Map<String, Object> selectExceptions(Map<String, Object> params);
    Map<String, Object> selectExceptionGroup(Long groupSn);
    Map<String, Object> searchExceptionEquipment(Map<String, Object> params);
    Long saveExceptionGroup(Map<String, Object> params, String actorId);
    void deleteExceptionGroup(Long groupSn);
    Map<String, Object> selectExceptionSchedule(Long scheduleSn);
    Long saveExceptionSchedule(Map<String, Object> params, String actorId);
    void deleteExceptionSchedule(Long scheduleSn);
}
