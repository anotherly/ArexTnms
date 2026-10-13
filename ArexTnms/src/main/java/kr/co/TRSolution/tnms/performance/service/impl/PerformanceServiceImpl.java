package kr.co.TRSolution.tnms.performance.service.impl;

import java.math.BigDecimal;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.performance.mapper.PerformanceMapper;
import kr.co.TRSolution.tnms.performance.service.PerformanceService;

@Service("performanceService")
public class PerformanceServiceImpl implements PerformanceService {
    @Resource(name = "performanceMapper") private PerformanceMapper performanceMapper;

    @Override
    public Map<String, Object> selectOverview(Map<String, Object> params) {
        Map<String, Object> result = common();
        result.put("indicatorStates", performanceMapper.selectPerformanceIndicatorStates(params));
        result.put("equipments", performanceMapper.selectPerformanceEquipmentList(params));
        result.put("trend", performanceMapper.selectPerformanceTrend(params));
        if (blank(params.get("topIndicator"))) params.put("topIndicator", "CPU_USGRT");
        result.put("top5", performanceMapper.selectPerformanceTop5(params));
        return result;
    }

    @Override
    public Map<String, Object> selectCycleData(Map<String, Object> params) {
        Map<String, Object> result = common();
        result.put("cycles", performanceMapper.selectCollectionCycles(params));
        result.put("heatmap", performanceMapper.selectCollectionHeatmap(params));
        return result;
    }

    @Override
    public Map<String, Object> selectThresholdData(Map<String, Object> params) {
        Map<String, Object> result = common();
        result.put("thresholds", performanceMapper.selectThresholds(params));
        return result;
    }

    @Override
    public Map<String, Object> selectRawData(Map<String, Object> params) {
        Map<String, Object> result = common();
        result.put("retention", performanceMapper.selectRawRetentionSummary());
        String tab = value(params.get("tab"));
        if ("interface".equalsIgnoreCase(tab)) result.put("rows", performanceMapper.selectInterfaceRawData(params));
        else result.put("rows", performanceMapper.selectEquipmentRawData(params));
        return result;
    }

    @Override
    public Map<String, Object> selectCycle(Long clctCycleSn) {
        if (clctCycleSn == null) throw new IllegalArgumentException("수정할 연동주기를 선택해 주세요.");
        Map<String, Object> row = performanceMapper.selectCollectionCycle(clctCycleSn);
        if (row == null) throw new IllegalArgumentException("연동주기 정보를 찾을 수 없습니다.");
        return row;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveCycle(Map<String, Object> params, String actorId) {
        Long sn = longValue(params.get("clctCycleSn"));
        if (sn == null) throw new IllegalArgumentException("수정할 수집주기를 선택해 주세요.");
        String perfUse = "N".equalsIgnoreCase(value(params.get("perfClctUseYn"))) ? "N" : "Y";
        String pingUse = "N".equalsIgnoreCase(value(params.get("pingMntrUseYn"))) ? "N" : "Y";
        int cycle = intValue(params.get("clctCycleSec"), 300);
        int ping = intValue(params.get("sttsMntrCycleSec"), 10);
        int timeout = intValue(params.get("timeoutSec"), 1);
        int retry = intValue(params.get("rtryNocs"), 3);
        int timeoutPoll = intValue(params.get("timeoutPollSec"), 1);
        if ("Y".equals(perfUse) && cycle < 60) throw new IllegalArgumentException("성능 수집주기는 1분 이상이어야 합니다.");
        if ("Y".equals(pingUse) && (ping < 1 || ping > 30)) throw new IllegalArgumentException("PING 상태감시 폴링주기는 1~30초로 입력해 주세요.");
        if (timeout < 1 || retry < 1 || timeoutPoll < 1) throw new IllegalArgumentException("타임아웃 시간·횟수·재확인 주기를 확인해 주세요.");
        params.put("clctCycleSn", sn);
        params.put("perfClctUseYn", perfUse); params.put("pingMntrUseYn", pingUse);
        params.put("clctCycleSec", cycle); params.put("sttsMntrCycleSec", ping);
        params.put("timeoutSec", timeout); params.put("rtryNocs", retry); params.put("timeoutPollSec", timeoutPoll);
        params.put("useYn", ("N".equals(perfUse) && "N".equals(pingUse)) ? "N" : "Y");
        params.put("mdfrId", actorId);
        if (performanceMapper.updateCollectionCycle(params) != 1) throw new IllegalArgumentException("수집주기 정보를 찾을 수 없습니다.");
    }

    @Override
    public Map<String, Object> selectThreshold(Long thrshldSn, String perfIdctCd) {
        Map<String, Object> row = thrshldSn == null ? null : performanceMapper.selectThreshold(thrshldSn);
        if (row == null && perfIdctCd != null && perfIdctCd.trim().length() > 0) row = performanceMapper.selectThresholdByIndicator(perfIdctCd);
        if (row == null) {
            row = new HashMap<String, Object>();
            row.put("perfIdctCd", perfIdctCd);
        }
        return row;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveThreshold(Map<String, Object> params, String actorId) {
        if (blank(params.get("perfIdctCd"))) throw new IllegalArgumentException("성능지표가 필요합니다.");
        Long sn = longValue(params.get("thrshldSn"));
        BigDecimal info = decimal(params.get("infoVl"));
        BigDecimal warning = decimal(params.get("warningVl"));
        BigDecimal low = decimal(params.get("lowVl"));
        BigDecimal high = decimal(params.get("highVl"));
        BigDecimal emergency = decimal(params.get("emergencyVl"));
        if (info == null || warning == null || low == null || high == null || emergency == null)
            throw new IllegalArgumentException("정보·경고·낮음·높음·긴급 임계치를 모두 입력해 주세요.");
        if (!(info.compareTo(warning) < 0 && warning.compareTo(low) < 0 && low.compareTo(high) < 0 && high.compareTo(emergency) < 0))
            throw new IllegalArgumentException("임계치는 정보 < 경고 < 낮음 < 높음 < 긴급 순으로 입력해 주세요.");
        int contnNocs = intValue(params.get("contnNocs"), 3);
        if (contnNocs < 1 || contnNocs > 100) throw new IllegalArgumentException("연속 발생 횟수는 1~100회로 입력해 주세요.");
        String profileNm = value(params.get("profileNm"));
        if (blank(profileNm)) profileNm = "CPU_USGRT".equals(value(params.get("perfIdctCd"))) ? "장비 CPU 임계치" : "장비 MEMORY 임계치";
        params.put("profileNm", profileNm);
        params.put("useYn", "N".equals(value(params.get("useYn"))) ? "N" : "Y");
        params.put("alrmUseYn", "Y");
        params.put("smsUseYn", "N");
        params.put("contnNocs", contnNocs);
        params.put("cmprOprtrCd", "GE");
        params.put("mdfrId", actorId);
        params.put("rgtrId", actorId);
        if (sn == null) {
            Map<String, Object> existing = performanceMapper.selectThresholdByIndicator(value(params.get("perfIdctCd")));
            if (existing != null && existing.get("thrshldSn") != null) sn = longValue(existing.get("thrshldSn"));
        }
        if (sn == null) {
            performanceMapper.insertThreshold(params);
            sn = longValue(params.get("thrshldSn"));
        } else {
            params.put("thrshldSn", sn);
            if (performanceMapper.updateThreshold(params) != 1) throw new IllegalArgumentException("임계치 정보를 찾을 수 없습니다.");
        }
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
