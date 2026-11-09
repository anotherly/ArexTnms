package kr.co.TRSolution.tnms.fault.service.impl;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import kr.co.TRSolution.tnms.common.security.SystemDataScope;
import kr.co.TRSolution.tnms.fault.mapper.FaultMapper;
import kr.co.TRSolution.tnms.fault.mapper.WebFaultProcessMapper;
import kr.co.TRSolution.tnms.fault.service.FaultService;
import kr.co.TRSolution.tnms.gateway.service.GatewayLiveService;

/** Gateway event source stays immutable; web handling/exceptions are separate web-owned records. */
@Service("faultService")
public class FaultServiceImpl implements FaultService {
  @Resource(name="faultMapper") private FaultMapper faultMapper;
  @Resource(name="webFaultProcessMapper") private WebFaultProcessMapper processMapper;
  @Resource(name="gatewayLiveService") private GatewayLiveService gatewayLiveService;

  @Override public Map<String,Object> selectRealtime(Map<String,Object> p){
    Map<String,Object> r=common();List<Map<String,Object>> rows=new ArrayList<Map<String,Object>>(gatewayLiveService.activeFaults(p));
    rows.addAll(processMapper.selectWebThresholdFaults(gatewayLiveService.scope(p)));
    rows=overlay(rows);
    r.put("faults",rows);
    Map<String,Object> summary=new HashMap<String,Object>();
    int em=0,hi=0,lo=0,wa=0,in=0;
    for(Map<String,Object>x:rows){String g=value(x.get("dsbltyGrdCd"));
      if("EMERGENCY".equals(g))em++;else if("HIGH".equals(g))hi++;
      else if("LOW".equals(g))lo++;else if("WARNING".equals(g))wa++;
      else if("INFO".equals(g))in++; }
    summary.put("totalCount",rows.size());summary.put("emergencyCount",em);
    summary.put("highCount",hi);summary.put("lowCount",lo);
    summary.put("warningCount",wa);summary.put("infoCount",in);
    r.put("summary",summary);return r;
  }
  @Override public Map<String,Object> selectHistory(Map<String,Object> p){
    Map<String,Object> r=common();List<Map<String,Object>> rows=new ArrayList<Map<String,Object>>(gatewayLiveService.history(p));
    rows.addAll(processMapper.selectWebThresholdHistory(gatewayLiveService.scope(p)));
    rows=overlay(rows);
    if(!blank(p.get("prcsSttsCd"))){String desired=value(p.get("prcsSttsCd"));
      java.util.Iterator<Map<String,Object>> iter=rows.iterator();while(iter.hasNext())
        if(!desired.equals(value(iter.next().get("prcsSttsCd"))))iter.remove();}
    r.put("faults",rows);Map<String,Object>s=new HashMap<String,Object>();
    int temp=0,complete=0;for(Map<String,Object>x:rows){
      if("Y".equals(value(x.get("tempActionYn"))))temp++;
      if("COMPLETED".equals(value(x.get("prcsSttsCd"))))complete++;}
    s.put("totalCount",rows.size());s.put("tempCount",temp);
    s.put("completedCount",complete);s.put("unconfirmedCount",rows.size()-complete);
    r.put("summary",s);return r;
  }
  @Override public Map<String,Object> selectFaultDetail(String no){
    if(blank(no)||!no.matches("(GW-[AH]|WEB-P)-[0-9]{1,18}"))throw new IllegalArgumentException("장애 ID가 유효하지 않습니다.");
    Map<String,Object> row=getOriginal(no);
    if(row==null)throw new IllegalArgumentException("장애정보를 찾을 수 없거나 접근권한이 없습니다.");
    row.put("dsbltyNo",no);Map<String,Object> state=processMapper.selectState(no);
    if(state!=null)row.putAll(state);
    Map<String,Object> r=new HashMap<String,Object>();r.put("fault",row);
    List<Map<String,Object>> actions=new ArrayList<Map<String,Object>>();
    if(no.startsWith("GW-"))actions.addAll(gatewayLiveService.faultActions(no));
    actions.addAll(processMapper.selectActions(no));r.put("actions",actions);return r;
  }
  /** Gateway rows are filtered by SQL exception schedule BEFORE web workflow flags are layered. */
  private List<Map<String,Object>> overlay(List<Map<String,Object>> rows){
    if(rows==null||rows.isEmpty())return rows==null?new ArrayList<Map<String,Object>>():rows;
    List<String> ids=new ArrayList<String>();for(Map<String,Object> row:rows)ids.add(value(row.get("dsbltyNo")));
    Map<String,Object> args=new HashMap<String,Object>();args.put("ids",ids);
    List<Map<String,Object>> states=processMapper.selectStates(args);
    Map<String,Map<String,Object>> by=new HashMap<String,Map<String,Object>>();
    for(Map<String,Object> st:states)by.put(value(st.get("faultKey")),st);
    for(Map<String,Object> row:rows){Map<String,Object> state=by.get(value(row.get("dsbltyNo")));
      if(state!=null)row.putAll(state);
      else {row.put("prcsSttsCd","UNCONFIRMED");row.put("prcsSttsNm","미확인");row.put("tempActionYn","N");}
      String status=value(row.get("prcsSttsCd"));
      if("COMPLETED".equals(status))row.put("prcsSttsNm","완료");
      else if("CONFIRMED".equals(status))row.put("prcsSttsNm","이관");
      else if("TEMP_ACTN".equals(status))row.put("prcsSttsNm","임시조치");
    }
    return rows;
  }

  private Map<String,Object> getOriginal(String no){
    if(no.startsWith("WEB-P-")){
      Map<String,Object> p=new HashMap<String,Object>();
      p.put("eventSeq",Long.valueOf(no.substring(6)));
      return processMapper.selectWebThresholdDetail(gatewayLiveService.scope(p));
    }
    return gatewayLiveService.faultDetail(no);
  }
  private void ensureAccess(String no){
    if(blank(no)||!no.matches("(GW-[AH]|WEB-P)-[0-9]{1,18}") || getOriginal(no)==null)
      throw new IllegalArgumentException("장애정보가 없거나 조회권한이 없습니다.");
  }
  private void persistAction(String no,String type,String content,Map<String,Object> p,String actorId,String actorName){
    Map<String,Object>a=new HashMap<String,Object>();a.put("faultKey",no);a.put("actnSeCd",type);
    a.put("actnCn",content);a.put("symptom",p.get("symptom"));
    a.put("reason",p.get("actionReason")!=null?p.get("actionReason"):p.get("reason"));
    a.put("result",p.get("result"));a.put("plan",p.get("plan"));
    a.put("actorId",actorId);a.put("actorName",actorName);
    processMapper.insertAction(a);
  }
  private void update(String no,Map<String,Object> p){
    processMapper.ensureState(no);
    p.put("faultKey",no);processMapper.updateState(p);
  }
  @Override @Transactional(rollbackFor=Exception.class)
  public void saveFault(Map<String,Object> p,String actorId,String actorName){
    String no=value(p.get("dsbltyNo"));ensureAccess(no);
    String j=value(p.get("dsbltyJgmtCd"));if(!blank(j)&&!Arrays.asList("SERVICE","STATUS","INFO").contains(j))
      throw new IllegalArgumentException("장애판단값이 잘못되었습니다.");
    Map<String,Object>m=new HashMap<String,Object>();
    if(!blank(j))m.put("dsbltyJgmtCd",j);
    for(String k:Arrays.asList("dsbltyTypeNm","dsbltyOcrnCn","dsbltyOcrnPlcNm"))
      if(p.containsKey(k))m.put(k,p.get(k));
    if(!blank(p.get("prcsSttsCd"))){
      String status=value(p.get("prcsSttsCd"));
      if(!Arrays.asList("UNCONFIRMED","TEMP_ACTN","CONFIRMED","COMPLETED").contains(status))
        throw new IllegalArgumentException("잘못된 장애 조치 상태입니다.");
      m.put("prcsSttsCd",status);
    }
    if(p.containsKey("mgmtMemoCn")) m.put("mgmtMemoCn",p.get("mgmtMemoCn"));
    if(!blank(p.get("tempActionCn"))||!blank(p.get("actionCn"))) {
      m.put("tempActionYn","Y");
      if(blank(p.get("prcsSttsCd"))) m.put("prcsSttsCd","TEMP_ACTN");
    }
    update(no,m);
    if(!blank(p.get("tempActionCn"))||!blank(p.get("actionCn"))||!blank(p.get("symptom"))||!blank(p.get("actionReason")))
      persistAction(no,"TEMP",valueOr(p.get("tempActionCn"),valueOr(p.get("actionCn"),"임시조치")),p,actorId,actorName);
    if("COMPLETED".equals(value(p.get("prcsSttsCd"))))complete(p,actorId,actorName);
    else if(!blank(p.get("completeActionCn"))) {
      p.put("prcsSttsCd","COMPLETED"); complete(p,actorId,actorName);
    }
  }
  @Override @Transactional(rollbackFor=Exception.class)
  public void applyJudgment(String keys,String judgment,String actorId,String actorName){
    if(!Arrays.asList("SERVICE","STATUS","INFO").contains(judgment))throw new IllegalArgumentException("판단 유형이 잘못되었습니다.");
    for(String no:split(keys)){ensureAccess(no);Map<String,Object>m=new HashMap<String,Object>();m.put("dsbltyJgmtCd",judgment);
      update(no,m);persistAction(no,"JUDGMENT","장애판단: "+judgment,new HashMap<String,Object>(),actorId,actorName);}
  }
  @Override @Transactional(rollbackFor=Exception.class)
  public void transfer(String keys,String actorId,String actorName){
    for(String no:split(keys)){ensureAccess(no);Map<String,Object>m=new HashMap<String,Object>();m.put("prcsSttsCd","CONFIRMED");m.put("idntyUserId",actorId);
      update(no,m);persistAction(no,"TRANSFER","장애 이관",new HashMap<String,Object>(),actorId,actorName);}
  }
  @Override @Transactional(rollbackFor=Exception.class)
  public void complete(Map<String,Object> p,String actorId,String actorName){
    String no=value(p.get("dsbltyNo"));ensureAccess(no);Map<String,Object>m=new HashMap<String,Object>();
    m.put("prcsSttsCd","COMPLETED");m.put("completeYn","Y");m.put("idntyUserId",actorId);update(no,m);
    persistAction(no,"COMPLETE",valueOr(p.get("actionCn"),"완료조치"),p,actorId,actorName);
  }
  @Override public Map<String,Object> selectTypes(Map<String,Object> p){Map<String,Object>r=common();r.put("types",faultMapper.selectFaultTypes(gatewayLiveService.scope(p)));return r;}
  @Override public Map<String,Object> selectType(Long sn){
    if(sn==null)throw new IllegalArgumentException("장애유형을 선택해 주세요.");
    Map<String,Object>p=new HashMap<String,Object>();p.put("eventSeq",sn);
    Map<String,Object>r=faultMapper.selectFaultType(gatewayLiveService.scope(p));
    if(r==null)throw new IllegalArgumentException("장애유형 정보가 없습니다.");return r;
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
    public Map<String, Object> searchExceptionEquipment(Map<String, Object> params) {
        Map<String,Object> result = new HashMap<String,Object>();
        result.put("rows", faultMapper.selectExceptionEquipmentCandidates(params == null ? new HashMap<String,Object>() : params));
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveExceptionGroup(Map<String, Object> params, String actorId) {
        String name = value(params.get("groupNm"));
        if (blank(name)) throw new IllegalArgumentException("그룹명을 입력해 주세요.");
        if (SystemDataScope.isLimited()) throw new SecurityException("시스템별 예외설정 변경은 관리자 권한에서 처리해 주세요.");
        Long sn = longValue(params.get("groupSn"));
        params.put("rgtrId", actorId); params.put("mdfrId", actorId); params.put("useYn", "N".equals(value(params.get("useYn"))) ? "N" : "Y");
        if (sn == null) { faultMapper.insertExceptionGroup(params); sn = longValue(params.get("groupSn")); }
        else { params.put("groupSn", sn); faultMapper.updateExceptionGroup(params); faultMapper.deleteExceptionGroupMemberIndicators(sn); faultMapper.deleteExceptionGroupMembers(sn); }
        String members = value(params.get("memberSns"));
        if (!blank(members)) for (String m : members.split(",")) {
            String[] parts=m.trim().split(":",2);if(parts.length!=2 || blank(parts[1]))continue;
            int ems;try{ems=Integer.parseInt(parts[0]);}catch(NumberFormatException invalid){continue;}
            Map<String,Object> rel = new HashMap<String,Object>(); rel.put("groupSn", sn); rel.put("emsId", ems); rel.put("deviceId",parts[1]); rel.put("allIdctYn", "Y");
            faultMapper.insertExceptionGroupMember(rel);
        }
        return sn;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteExceptionGroup(Long groupSn) {
        if (SystemDataScope.isLimited()) throw new SecurityException("시스템별 예외설정 변경은 관리자 권한에서 처리해 주세요.");
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
        result.put("schedule", row);
        result.put("grades", faultMapper.selectExceptionScheduleGrades(scheduleSn));
        result.put("members", faultMapper.selectExceptionGroupMembers(longValue(row.get("groupSn"))));
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveExceptionSchedule(Map<String, Object> params, String actorId) {
        if (SystemDataScope.isLimited()) throw new SecurityException("시스템별 예외설정 변경은 관리자 권한에서 처리해 주세요.");
        Long groupSn = longValue(params.get("groupSn"));
        if (groupSn == null) throw new IllegalArgumentException("예외그룹을 선택해 주세요.");
        if (blank(params.get("beginDt"))) throw new IllegalArgumentException("시작일시를 입력해 주세요.");
        if (blank(params.get("reason"))) throw new IllegalArgumentException("설명을 입력해 주세요.");

        Map<String,Object> group = faultMapper.selectExceptionGroup(groupSn);
        if (group == null) throw new IllegalArgumentException("선택한 예외그룹을 찾을 수 없습니다.");
        String scheduleNm = value(params.get("scheduleNm"));
        if (blank(scheduleNm)) {
            Long existingSn = longValue(params.get("scheduleSn"));
            if (existingSn != null) {
                Map<String,Object> existing = faultMapper.selectExceptionSchedule(existingSn);
                if (existing != null) scheduleNm = value(existing.get("scheduleNm"));
            }
        }
        if (blank(scheduleNm)) {
            String groupNm = valueOr(group.get("groupNm"), "장애 예외");
            String start = value(params.get("beginDt")).replace('T', ' ');
            String kind = "REPEAT".equalsIgnoreCase(value(params.get("runType"))) ? "반복" : "1회";
            scheduleNm = groupNm + " " + kind + " " + start;
        }
        if (scheduleNm.length() > 100) scheduleNm = scheduleNm.substring(0, 100);
        params.put("scheduleNm", scheduleNm);

        String runType = valueOr(params.get("runType"), "ONCE").toUpperCase();
        if (!("ONCE".equals(runType) || "REPEAT".equals(runType))) throw new IllegalArgumentException("실행구분을 확인해 주세요.");
        String noEndYn = "Y".equalsIgnoreCase(value(params.get("noEndYn"))) ? "Y" : "N";
        if ("ONCE".equals(runType)) noEndYn = "N";
        if ("N".equals(noEndYn) && blank(params.get("endDt"))) throw new IllegalArgumentException("종료일시를 입력하거나 종료일 제외를 선택해 주세요.");

        String repeatCycle = null;
        String repeatDays = null;
        if ("REPEAT".equals(runType)) {
            repeatCycle = valueOr(params.get("repeatCycle"), "DAILY").toUpperCase();
            if (!("DAILY".equals(repeatCycle) || "WEEKLY".equals(repeatCycle) || "MONTHLY".equals(repeatCycle)))
                throw new IllegalArgumentException("반복주기를 확인해 주세요.");
            repeatDays = value(params.get("repeatDays"));
            if ("WEEKLY".equals(repeatCycle) && blank(repeatDays)) throw new IllegalArgumentException("반복 요일을 하나 이상 선택해 주세요.");
            if (blank(params.get("startTime")) || blank(params.get("endTime"))) throw new IllegalArgumentException("반복 시작/종료 시간을 입력해 주세요.");
        }

        params.put("runType", runType);
        params.put("noEndYn", noEndYn);
        params.put("repeatCycle", repeatCycle);
        params.put("repeatDays", repeatDays);
        params.put("bgngDt", dateTimeValue(params.get("beginDt")));
        params.put("endDt", "Y".equals(noEndYn) ? null : dateTimeValue(params.get("endDt")));
        params.put("startTime", timeValue(params.get("startTime"), params.get("beginDt")));
        params.put("endTime", timeValue(params.get("endTime"), params.get("endDt")));
        params.put("reptCycleCn", "REPEAT".equals(runType) ? "REPEAT|" + repeatCycle + "|" + valueOr(repeatDays, "") : "ONCE");
        params.put("excpRsn", value(params.get("reason")));
        Long sn = longValue(params.get("scheduleSn"));
        params.put("rgtrId", actorId); params.put("mdfrId", actorId); params.put("useYn", "Y");
        if (sn == null) { faultMapper.insertExceptionSchedule(params); sn = longValue(params.get("scheduleSn")); }
        else { params.put("scheduleSn", sn); faultMapper.updateExceptionSchedule(params); faultMapper.deleteExceptionScheduleGrades(sn); }
        String grades=value(params.get("grades"));
        if (!blank(grades)) for(String gr:grades.split(",")){
            String grade=gr.trim(); if(!java.util.Arrays.asList("EMERGENCY","HIGH","LOW","WARNING","INFO").contains(grade))continue;
            Map<String,Object> row=new HashMap<String,Object>();row.put("scheduleSn",sn);row.put("grade",grade);
            faultMapper.insertExceptionScheduleGrade(row);
        }
        return sn;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteExceptionSchedule(Long scheduleSn) {
        if (SystemDataScope.isLimited()) throw new SecurityException("시스템별 예외설정 변경은 관리자 권한에서 처리해 주세요.");
        if (scheduleSn == null) throw new IllegalArgumentException("삭제할 일정을 선택해 주세요.");
        faultMapper.deleteExceptionScheduleGrades(scheduleSn);
        if (faultMapper.deleteExceptionSchedule(scheduleSn) != 1) throw new IllegalArgumentException("예외일정을 찾을 수 없습니다.");
    }

  private Map<String,Object> common(){Map<String,Object>r=new HashMap<String,Object>();
    r.put("systems",faultMapper.selectLinkSystems());r.put("stations",faultMapper.selectStations());
    r.put("gradeCodes",gatewayLiveService.faultGradeCodes());
    List<Map<String,Object>> statuses=new ArrayList<Map<String,Object>>();
    for(String[] x:new String[][]{{"UNCONFIRMED","미확인"},{"TEMP_ACTN","임시조치"},{"CONFIRMED","이관"},{"COMPLETED","완료"}}){
      Map<String,Object>v=new HashMap<String,Object>();v.put("code",x[0]);v.put("name",x[1]);statuses.add(v);}
    r.put("processCodes",statuses);return r;
  }
  private List<String> split(String csv){List<String>r=new ArrayList<String>();if(csv!=null)for(String s:csv.split(","))if(!blank(s))r.add(s.trim());if(r.isEmpty())throw new IllegalArgumentException("장애를 선택해 주세요.");return r;}
  private boolean blank(Object v){return v==null||String.valueOf(v).trim().length()==0;}
  private String value(Object v){return v==null?null:String.valueOf(v).trim();}
  private String valueOr(Object v,String def){String s=value(v);return blank(s)?def:s;}
  private Long longValue(Object v){try{return blank(v)?null:Long.valueOf(value(v));}catch(Exception x){return null;}}
  private String dateTimeValue(Object v){String s=value(v);if(s==null)return null;s=s.replace('T',' ');return s.length()==16?s+":00":s;}
  private String timeValue(Object explicit,Object dateTime){
    String s=value(explicit);if(!blank(s))return s.length()==5?s+":00":s;
    String dt=value(dateTime);if(blank(dt))return null;dt=dt.replace('T',' ');
    int idx=dt.indexOf(' ');return idx>=0&&dt.length()>idx+5?dt.substring(idx+1,Math.min(idx+9,dt.length())):null;
  }
}
