package kr.co.TRSolution.tnms.fault.service.impl;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.fault.mapper.FaultMapper;
import kr.co.TRSolution.tnms.fault.service.FaultService;

@Service("faultService")
public class FaultServiceImpl implements FaultService {
    @Resource(name = "faultMapper") private FaultMapper faultMapper;

    @Override
    public Map<String, Object> selectRealtime(Map<String, Object> params) {
        Map<String, Object> result = common();
        result.put("summary", faultMapper.selectRealtimeSummary(params));
        result.put("faults", faultMapper.selectRealtimeFaults(params));
        return result;
    }

    @Override
    public Map<String, Object> selectHistory(Map<String, Object> params) {
        Map<String, Object> result = common();
        result.put("summary", faultMapper.selectHistorySummary(params));
        result.put("faults", faultMapper.selectHistoryFaults(params));
        return result;
    }

    @Override
    public Map<String, Object> selectFaultDetail(String dsbltyNo) {
        if (blank(dsbltyNo)) throw new IllegalArgumentException("장애를 선택해 주세요.");
        Map<String, Object> result = new HashMap<String, Object>();
        Map<String, Object> fault = faultMapper.selectFaultDetail(dsbltyNo);
        if (fault == null) throw new IllegalArgumentException("장애 정보를 찾을 수 없습니다.");
        result.put("fault", fault);
        result.put("actions", faultMapper.selectFaultActions(dsbltyNo));
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveFault(Map<String, Object> params, String actorId, String actorName) {
        String no = value(params.get("dsbltyNo"));
        if (blank(no)) throw new IllegalArgumentException("장애를 선택해 주세요.");
        String judgment = value(params.get("dsbltyJgmtCd"));
        if (!blank(judgment) && !("SERVICE".equals(judgment) || "STATUS".equals(judgment) || "INFO".equals(judgment))) {
            throw new IllegalArgumentException("장애 판단값이 올바르지 않습니다.");
        }
        String actionReason = value(params.get("actionReason"));
        if (!blank(actionReason)) params.put("reason", actionReason);
        params.put("actorId", actorId);
        if (faultMapper.updateFault(params) != 1) throw new IllegalArgumentException("장애 정보를 찾을 수 없습니다.");
        String action = value(params.get("actionCn"));
        String symptom = value(params.get("symptom"));
        if (!blank(action) || !blank(symptom) || !blank(actionReason)) {
            insertAction(no, "TEMP", valueOr(action, "임시조치 정보 수정"), params, actorId, actorName);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void applyJudgment(String dsbltyNos, String judgment, String actorId, String actorName) {
        if (blank(judgment)) throw new IllegalArgumentException("장애 판단을 선택해 주세요.");
        if (!("SERVICE".equals(judgment) || "STATUS".equals(judgment) || "INFO".equals(judgment))) {
            throw new IllegalArgumentException("장애 판단값이 올바르지 않습니다.");
        }
        String judgmentNm = "SERVICE".equals(judgment) ? "서비스장애" : "STATUS".equals(judgment) ? "상태장애" : "정보";
        for (String no : split(dsbltyNos)) {
            Map<String, Object> p = new HashMap<String, Object>();
            p.put("dsbltyNo", no); p.put("dsbltyJgmtCd", judgment); p.put("lastMdfrId", actorId);
            faultMapper.updateFault(p);
            insertAction(no, "JUDGMENT", "장애 판단: " + judgmentNm, p, actorId, actorName);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void transfer(String dsbltyNos, String actorId, String actorName) {
        for (String no : split(dsbltyNos)) {
            Map<String, Object> p = new HashMap<String, Object>();
            p.put("dsbltyNo", no); p.put("prcsSttsCd", "CONFIRMED"); p.put("idntyUserId", actorId);
            faultMapper.updateFaultStatus(p);
            insertAction(no, "TRANSFER", "장애 이관", p, actorId, actorName);
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void complete(Map<String, Object> params, String actorId, String actorName) {
        String no = value(params.get("dsbltyNo"));
        if (blank(no)) throw new IllegalArgumentException("장애를 선택해 주세요.");
        params.put("prcsSttsCd", "COMPLETED"); params.put("idntyUserId", actorId); params.put("completeYn", "Y");
        faultMapper.updateFaultStatus(params);
        insertAction(no, "COMPLETE", valueOr(params.get("actionCn"), "완료조치 등록"), params, actorId, actorName);
    }

    @Override
    public Map<String, Object> selectTypes(Map<String, Object> params) {
        Map<String, Object> result = common();
        result.put("types", faultMapper.selectFaultTypes(params));
        return result;
    }

    @Override
    public Map<String, Object> selectType(Long dsbltyTypeSn) {
        if (dsbltyTypeSn == null) throw new IllegalArgumentException("장애유형을 선택해 주세요.");
        Map<String, Object> row = faultMapper.selectFaultType(dsbltyTypeSn);
        if (row == null) throw new IllegalArgumentException("장애유형을 찾을 수 없습니다.");
        return row;
    }

    @Override
    public Map<String, Object> selectExceptions(Map<String, Object> params) {
        Map<String, Object> result = common();
        List<Map<String,Object>> groups = faultMapper.selectExceptionGroups();
        result.put("groups", groups);
        if (blank(params.get("groupSn")) && !groups.isEmpty()) params.put("groupSn", groups.get(0).get("groupSn"));
        result.put("schedules", faultMapper.selectExceptionSchedules(params));
        return result;
    }

    @Override
    public Map<String, Object> selectExceptionGroup(Long groupSn) {
        Map<String, Object> result = new HashMap<String, Object>();
        Map<String, Object> group = groupSn == null ? null : faultMapper.selectExceptionGroup(groupSn);
        result.put("group", group);
        result.put("members", groupSn == null ? new ArrayList<Map<String,Object>>() : faultMapper.selectExceptionGroupMembers(groupSn));
        result.put("candidates", faultMapper.selectExceptionEquipmentCandidates(new HashMap<String,Object>()));
        result.put("systems", faultMapper.selectLinkSystems());
        result.put("stations", faultMapper.selectStations());
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveExceptionGroup(Map<String, Object> params, String actorId) {
        String name = value(params.get("groupNm"));
        if (blank(name)) throw new IllegalArgumentException("그룹명을 입력해 주세요.");
        Long sn = longValue(params.get("groupSn"));
        params.put("rgtrId", actorId); params.put("mdfrId", actorId); params.put("useYn", "N".equals(value(params.get("useYn"))) ? "N" : "Y");
        if (sn == null) { faultMapper.insertExceptionGroup(params); sn = longValue(params.get("groupSn")); }
        else { params.put("groupSn", sn); faultMapper.updateExceptionGroup(params); faultMapper.deleteExceptionGroupMemberIndicators(sn); faultMapper.deleteExceptionGroupMembers(sn); }
        String members = value(params.get("memberSns"));
        if (!blank(members)) for (String m : members.split(",")) {
            Long eq = longValue(m); if (eq == null) continue;
            Map<String,Object> rel = new HashMap<String,Object>(); rel.put("groupSn", sn); rel.put("eqpmntSn", eq); rel.put("allIdctYn", "Y");
            faultMapper.insertExceptionGroupMember(rel);
        }
        return sn;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteExceptionGroup(Long groupSn) {
        if (groupSn == null) throw new IllegalArgumentException("삭제할 그룹을 선택해 주세요.");
        faultMapper.deleteExceptionScheduleGradesByGroup(groupSn);
        faultMapper.deleteExceptionSchedulesByGroup(groupSn);
        faultMapper.deleteExceptionGroupMemberIndicators(groupSn);
        faultMapper.deleteExceptionGroupMembers(groupSn);
        if (faultMapper.deleteExceptionGroup(groupSn) != 1) throw new IllegalArgumentException("예외그룹을 찾을 수 없습니다.");
    }

    @Override
    public Map<String, Object> selectExceptionSchedule(Long scheduleSn) {
        if (scheduleSn == null) throw new IllegalArgumentException("일정을 선택해 주세요.");
        Map<String,Object> result = new HashMap<String,Object>();
        Map<String,Object> row = faultMapper.selectExceptionSchedule(scheduleSn);
        if (row == null) throw new IllegalArgumentException("예외일정을 찾을 수 없습니다.");
        result.put("schedule", row); result.put("grades", faultMapper.selectExceptionScheduleGrades(scheduleSn));
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveExceptionSchedule(Map<String, Object> params, String actorId) {
        Long groupSn = longValue(params.get("groupSn"));
        if (groupSn == null) throw new IllegalArgumentException("예외그룹을 선택해 주세요.");
        if (blank(params.get("scheduleNm")) || blank(params.get("beginDt")) || blank(params.get("endDt"))) throw new IllegalArgumentException("일정명과 시작/종료일시를 입력해 주세요.");
        if (blank(params.get("reason"))) throw new IllegalArgumentException("예외 사유를 입력해 주세요.");
        params.put("bgngDt", dateTimeValue(params.get("beginDt")));
        params.put("endDt", dateTimeValue(params.get("endDt")));
        params.put("excpRsn", value(params.get("reason")));
        Long sn = longValue(params.get("scheduleSn"));
        params.put("rgtrId", actorId); params.put("mdfrId", actorId); params.put("useYn", "N".equals(value(params.get("useYn"))) ? "N" : "Y");
        if (sn == null) { faultMapper.insertExceptionSchedule(params); sn = longValue(params.get("scheduleSn")); }
        else { params.put("scheduleSn", sn); faultMapper.updateExceptionSchedule(params); faultMapper.deleteExceptionScheduleGrades(sn); }
        String grades = value(params.get("grades"));
        if (!blank(grades)) for (String g : grades.split(",")) {
            Map<String,Object> rel = new HashMap<String,Object>(); rel.put("scheduleSn", sn); rel.put("grade", g.trim()); faultMapper.insertExceptionScheduleGrade(rel);
        }
        return sn;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteExceptionSchedule(Long scheduleSn) {
        if (scheduleSn == null) throw new IllegalArgumentException("삭제할 일정을 선택해 주세요.");
        faultMapper.deleteExceptionScheduleGrades(scheduleSn);
        if (faultMapper.deleteExceptionSchedule(scheduleSn) != 1) throw new IllegalArgumentException("예외일정을 찾을 수 없습니다.");
    }

    private Map<String,Object> common() {
        Map<String,Object> result = new HashMap<String,Object>();
        result.put("systems", faultMapper.selectLinkSystems()); result.put("stations", faultMapper.selectStations());
        result.put("gradeCodes", faultMapper.selectFaultGradeCodes()); result.put("processCodes", faultMapper.selectProcessStatusCodes());
        return result;
    }
    private void insertAction(String no, String type, String cn, Map<String,Object> source, String actorId, String actorName) {
        Map<String,Object> a = new HashMap<String,Object>(); a.put("dsbltyNo", no); a.put("actnSeCd", type); a.put("actnCn", cn);
        a.put("symptom", source.get("symptom")); a.put("reason", source.get("reason")); a.put("plan", source.get("plan")); a.put("result", source.get("result"));
        a.put("actorId", actorId); a.put("actorName", actorName); a.put("ctrlCmdCn", source.get("ctrlCmdCn")); faultMapper.insertFaultAction(a);
    }
    private List<String> split(String csv) { List<String> r=new ArrayList<String>(); if (csv!=null) for(String s:csv.split(",")) if(!blank(s)) r.add(s.trim()); if(r.isEmpty()) throw new IllegalArgumentException("장애를 선택해 주세요."); return r; }
    private boolean blank(Object v) { return v == null || String.valueOf(v).trim().length() == 0; }
    private String value(Object v) { return v == null ? null : String.valueOf(v).trim(); }
    private String valueOr(Object v, String d) { String s=value(v); return blank(s)?d:s; }
    private Long longValue(Object v) { try { return blank(v) ? null : Long.valueOf(String.valueOf(v)); } catch(Exception e){ return null; } }
    private String dateTimeValue(Object v) { String s=value(v); if (s==null) return null; s=s.replace('T', ' '); return s.length()==16 ? s+":00" : s; }
}
