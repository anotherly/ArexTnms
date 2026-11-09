package kr.co.TRSolution.tnms.performance.service.impl;

import kr.co.TRSolution.tnms.common.security.SystemDataScope;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.performance.mapper.PerformanceMapper;
import kr.co.TRSolution.tnms.gateway.service.GatewayLiveService;
import kr.co.TRSolution.tnms.performance.service.PerformanceService;

@Service("performanceService")
public class PerformanceServiceImpl implements PerformanceService {
    @Resource(name = "performanceMapper") private PerformanceMapper performanceMapper;
    @Resource(name = "gatewayLiveService") private GatewayLiveService gatewayLiveService;

    @Override
    public Map<String, Object> selectOverview(Map<String, Object> params) {
        Map<String, Object> result = common();
        if (params.get("eqpmntSn") != null && !blank(params.get("eqpmntSn"))) {
            String key=String.valueOf(params.get("eqpmntSn"));
            if (!key.matches("[0-9a-fA-F]{64}")) throw new IllegalArgumentException("장비 식별자가 유효하지 않습니다.");
        }
        result.put("indicatorStates", gatewayLiveService.indicatorStates(params));
        result.put("equipments", gatewayLiveService.performance(params));
        result.put("trend", gatewayLiveService.trend(params));
        if (blank(params.get("topIndicator"))) params.put("topIndicator", "CPU_USGRT");
        result.put("top5", gatewayLiveService.top5(params));
        return result;
    }

    @Override
    public Map<String, Object> selectCycleData(Map<String, Object> params) {
        Map<String, Object> result = common();
        result.put("cycles", performanceMapper.selectCollectionCycles(gatewayLiveService.scope(params)));
        result.put("heatmap", performanceMapper.selectCollectionHeatmap(gatewayLiveService.scope(params)));
        return result;
    }

    @Override
    public Map<String,Object> selectThresholdData(Map<String,Object> params){
      Map<String,Object> r=common();r.put("thresholds",performanceMapper.selectThresholds(params));return r;
    }

    @Override
    public Map<String, Object> selectRawData(Map<String, Object> params) {
        Map<String, Object> result = common();
        result.put("retention", performanceMapper.selectRawRetentionSummary());
        String tab = value(params.get("tab"));
        if ("interface".equalsIgnoreCase(tab)) result.put("rows", performanceMapper.selectInterfaceRawData(gatewayLiveService.scope(params)));
        else result.put("rows", gatewayLiveService.rawUsage(params));
        return result;
    }

    /** 게이트웨이 수집 설정은 웹 DB에 저장하지 않습니다. */
    @Override
    public Map<String, Object> selectCycle(Long clctCycleSn) {
        throw new UnsupportedOperationException("게이트웨이 수집주기는 웹에서 수정할 수 없습니다. 수신 현황만 조회합니다.");
    }

    @Override
    public void saveCycle(Map<String, Object> params, String actorId) {
        throw new UnsupportedOperationException("게이트웨이 수집주기 변경은 게이트웨이 담당 설정에서 처리해 주세요.");
    }

    @Override
    public Map<String,Object> selectThreshold(Long sn,String perfIdctCd){
      if(sn!=null){Map<String,Object>x=performanceMapper.selectThreshold(sn);
        if(x==null)throw new IllegalArgumentException("임계치 설정이 없습니다.");return x;}
      if(!"CPU_USGRT".equals(perfIdctCd)&&!"MMRY_USGRT".equals(perfIdctCd))
        throw new IllegalArgumentException("CPU/MEMORY 성능지표만 허용합니다.");
      Map<String,Object> x=new HashMap<String,Object>();
      x.put("perfIdctCd",perfIdctCd);x.put("perfIdctNm","CPU_USGRT".equals(perfIdctCd)?"CPU 사용률":"MEMORY 사용률");
      x.put("unitNm","%");x.put("useYn","Y");x.put("contnNocs",3);return x;
    }
    @Override
    @Transactional(rollbackFor=Exception.class)
    public Long saveThreshold(Map<String,Object> p,String actorId){
      if(p==null)throw new IllegalArgumentException("임계치 데이터가 없습니다.");
      String metric=value(p.get("perfIdctCd"));
      if(!"CPU_USGRT".equals(metric)&&!"MMRY_USGRT".equals(metric))throw new IllegalArgumentException("허용되지 않는 성능지표입니다.");
      String system=value(p.get("linkSysCd"));
      if(system!=null&&!system.isEmpty())kr.co.TRSolution.tnms.common.security.SystemDataScope.requireSystem(system);
      BigDecimal prev=null;
      for(String field:new String[]{"infoVl","warningVl","lowVl","highVl","emergencyVl"}){
        BigDecimal d=decimal(p.get(field));
        if(d==null||d.compareTo(BigDecimal.ZERO)<0||d.compareTo(new BigDecimal("100"))>0||(prev!=null&&d.compareTo(prev)<=0))
          throw new IllegalArgumentException("임계치는 0~100 범위에서 정보 < 경고 < 낮음 < 높음 < 긴급 순서로 입력해야 합니다.");
        p.put(field,d);prev=d;
      }
      int count=intValue(p.get("contnNocs"),3);
      if(count<1||count>100)throw new IllegalArgumentException("지속조건은 1~100회입니다.");
      p.put("contnNocs",count);
      String profile=value(p.get("profileNm"));if(blank(profile)||profile.length()>100)throw new IllegalArgumentException("프로파일명(100자 이하)을 입력해 주세요.");
      p.put("useYn","N".equals(value(p.get("useYn")))?"N":"Y");p.put("rgtrId",actorId);p.put("mdfrId",actorId);
      Long sn=longValue(p.get("thrshldSn"));
      if(sn==null){performanceMapper.insertThreshold(p);sn=longValue(p.get("thrshldSn"));}
      else if(performanceMapper.updateThreshold(p)!=1)throw new IllegalArgumentException("수정할 임계치가 없습니다.");
      return sn;
    }

    private Map<String, Object> common() {
        Map<String, Object> result = new HashMap<String, Object>();
        result.put("systems", performanceMapper.selectLinkSystems());
        result.put("stations", performanceMapper.selectStations());
        return result;
    }

    private boolean blank(Object v) { return v == null || String.valueOf(v).trim().length() == 0; }
    private String value(Object v) { return v == null ? null : String.valueOf(v).trim(); }
    private Long longValue(Object v) { try { return blank(v) ? null : Long.valueOf(String.valueOf(v)); } catch (Exception e) { return null; } }
    private int intValue(Object v, int d) { try { return blank(v) ? d : Integer.parseInt(String.valueOf(v)); } catch (Exception e) { return d; } }
    private BigDecimal decimal(Object v) { try { return blank(v) ? null : new BigDecimal(String.valueOf(v)); } catch (Exception e) { return null; } }
}
