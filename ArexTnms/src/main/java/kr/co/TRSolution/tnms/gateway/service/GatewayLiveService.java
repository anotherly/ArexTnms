package kr.co.TRSolution.tnms.gateway.service;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import kr.co.TRSolution.tnms.common.security.SystemDataScope;
import kr.co.TRSolution.tnms.gateway.mapper.GatewayLiveMapper;
import kr.co.TRSolution.tnms.monitoring.vo.EquipmentVO;
import kr.co.TRSolution.tnms.monitoring.vo.StationStatusVO;

/**
 * 게이트웨이가 INSERT한 원천/공통 값을 웹에서 즉시 읽는 서비스.
 * 소스 테이블에 대한 INSERT/UPDATE/DELETE 작업을 수행하지 않습니다.
 * 전체/시스템별 조회 모두 서버의 SystemDataScope를 강제 적용합니다.
 */
@Service("gatewayLiveService")
public class GatewayLiveService {
    private static final String[] SYS_CODES = {"EMS_TX","VMS","PBX","EMS_PIDS","SCADA_SEC"};
    private static final int[] EMS_IDS = {1,4,11,13,16};
    @Resource(name="gatewayLiveMapper") private GatewayLiveMapper mapper;

    public Map<String,Object> scope(Map<String,?> request) {
        Map<String,Object> args=new HashMap<String,Object>();
        if(request!=null)args.putAll(request);
        Set<String> allowed=SystemDataScope.current();
        List<Integer> ids=new ArrayList<Integer>();
        List<String> codes=new ArrayList<String>();
        for(int i=0;i<SYS_CODES.length;i++) {
            if(allowed==null || allowed.contains(SYS_CODES[i])) {
                ids.add(Integer.valueOf(EMS_IDS[i])); codes.add(SYS_CODES[i]);
            }
        }
        // Never emit IN () -- no permissions map to an impossible EMS id.
        if(ids.isEmpty()) ids.add(Integer.valueOf(-1));
        if(codes.isEmpty()) codes.add("__DENIED__");
        args.put("allowedEmsIds",ids); args.put("allowedCodes",codes);
        Object code=args.get("linkSysCd");
        if(code!=null && String.valueOf(code).trim().length()>0) {
            String selected=String.valueOf(code).trim();
            if(!Arrays.asList(SYS_CODES).contains(selected))
                throw new IllegalArgumentException("알 수 없는 설비 시스템입니다.");
            SystemDataScope.requireSystem(selected);
        }
        return args;
    }
    public List<EquipmentVO> systems() { return mapper.selectSystemSummary(scope(null)); }
    public List<StationStatusVO> stations(EquipmentVO vo) {
        Map<String,Object> a=new HashMap<String,Object>();
        if(vo!=null)a.put("linkSysCd",vo.getLinkSysCd());
        return mapper.selectStationSummary(scope(a));
    }
    public List<EquipmentVO> stationSystems(String stnCd) {
        Map<String,Object> a=new HashMap<String,Object>(); a.put("stnCd",stnCd);
        return mapper.selectStationSystemSummary(scope(a));
    }
    public List<EquipmentVO> devices(EquipmentVO vo) {
        Map<String,Object> a=new HashMap<String,Object>();
        if(vo!=null) {
            a.put("linkSysCd",vo.getLinkSysCd()); a.put("stnCd",vo.getStnCd());
            a.put("keyword",vo.getSearchKeyword());
        }
        return mapper.selectEquipmentList(scope(a));
    }
    public EquipmentVO summary(EquipmentVO vo) {
        Map<String,Object> a=new HashMap<String,Object>();
        if(vo!=null) {
            a.put("linkSysCd",vo.getLinkSysCd()); a.put("stnCd",vo.getStnCd());
            a.put("keyword",vo.getSearchKeyword());
        }
        return mapper.selectEquipmentSummary(scope(a));
    }
    public EquipmentVO device(int emsId,String deviceId) {
        String system=systemCode(emsId);
        if(system==null || deviceId==null || deviceId.trim().length()==0) throw new IllegalArgumentException("장비 식별자가 필요합니다.");
        SystemDataScope.requireSystem(system);
        Map<String,Object> a=new HashMap<String,Object>();
        a.put("emsId",Integer.valueOf(emsId)); a.put("deviceId",deviceId);
        EquipmentVO device=mapper.selectEquipmentByKey(scope(a));
        if(device==null) throw new IllegalArgumentException("게이트웨이 장비를 찾을 수 없습니다.");
        return device;
    }
    private String systemCode(int id) {
        for(int i=0;i<EMS_IDS.length;i++)if(EMS_IDS[i]==id)return SYS_CODES[i];
        return null;
    }
    public List<Map<String,Object>> performance(Map<String,Object> params) { return mapper.selectPerformanceEquipmentList(scope(params)); }
    public List<Map<String,Object>> trend(Map<String,Object> params) { return mapper.selectPerformanceTrend(scope(params)); }
    public List<Map<String,Object>> top5(Map<String,Object> params) { return mapper.selectPerformanceTop5(scope(params)); }
    public List<Map<String,Object>> indicatorStates(Map<String,Object> params) { return mapper.selectIndicatorStates(scope(params)); }
    public List<Map<String,Object>> rawUsage(Map<String,Object> params) { return mapper.selectGatewayEquipmentRawData(scope(params)); }
    public List<Map<String,Object>> activeFaults(Map<String,Object> params) { return mapper.selectRealtimeFaults(scope(params)); }
    public Map<String,Object> activeFaultSummary(Map<String,Object> params) { return mapper.selectRealtimeFaultSummary(scope(params)); }
    public List<Map<String,Object>> history(Map<String,Object> params) { return history(params,true); }
    public List<Map<String,Object>> faultGradeCodes() { return mapper.selectFaultGrades(scope(null)); }
    public List<Map<String,Object>> history(Map<String,Object> params,boolean labelHistory) {
        List<Map<String,Object>> rows=mapper.selectFaultHistory(scope(params));
        for(Map<String,Object> row:rows)row.put("dsbltyNo","GW-H-"+String.valueOf(row.get("eventSeq")));
        return rows;
    }
    public Map<String,Object> faultDetail(String dsbltyNo) {
        long seq=seq(dsbltyNo);Map<String,Object> args=new HashMap<String,Object>();args.put("eventSeq",Long.valueOf(seq));
        return dsbltyNo.startsWith("GW-H-") ? mapper.selectFaultLogDetail(scope(args)) : mapper.selectFaultDetail(scope(args));
    }
    public List<Map<String,Object>> faultActions(String dsbltyNo) {
        if(dsbltyNo.startsWith("GW-H-"))return new ArrayList<Map<String,Object>>();
        long seq=seq(dsbltyNo);Map<String,Object> args=new HashMap<String,Object>();args.put("eventSeq",Long.valueOf(seq));
        return mapper.selectFaultAction(scope(args));
    }
    private long seq(String no) {
        if(no==null || !no.matches("GW-[AH]-[0-9]{1,18}"))throw new IllegalArgumentException("유효하지 않은 게이트웨이 장애번호입니다.");
        return Long.parseLong(no.substring(5));
    }
}
