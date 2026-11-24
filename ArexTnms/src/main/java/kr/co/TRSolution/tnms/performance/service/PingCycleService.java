package kr.co.TRSolution.tnms.performance.service;

import java.util.HashMap;
import java.util.Map;

import javax.annotation.Resource;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.common.security.SystemDataScope;
import kr.co.TRSolution.tnms.gateway.service.GatewayLiveService;
import kr.co.TRSolution.tnms.performance.mapper.PingCycleMapper;

/** 수집주기관리 전용 저장소. 설정(com_ping_info)만 변경하고 게이트웨이 원천 로그/장비는 변경하지 않음. */
@Service("pingCycleService")
public class PingCycleService {
    @Resource(name="pingCycleMapper") private PingCycleMapper mapper;
    @Resource(name="gatewayLiveService") private GatewayLiveService gatewayLiveService;
    @Resource(name="systemCodeRegistry") private kr.co.TRSolution.tnms.gateway.service.SystemCodeRegistry codes;

    public Map<String,Object> selectData(Map<String,String> request) {
        Map<String,Object> scope = new HashMap<String,Object>();
        if (request != null) scope.putAll(request);
        scope = gatewayLiveService.scope(scope);
        Map<String,Object> result = new HashMap<String,Object>();
        result.put("systems", mapper.selectSystems(scope));
        result.put("cycles", mapper.selectCycles(scope));
        result.put("heatmap", mapper.selectHeatmap(scope));
        return result;
    }

    public Map<String,Object> selectDetail(Integer emsId, String dataSeCd) {
        Map<String,Object> key = key(emsId, dataSeCd);
        Map<String,Object> row = mapper.selectCycle(key);
        if (row == null) throw new IllegalArgumentException("수집주기 설정이 존재하지 않습니다.");
        return row;
    }

    @Transactional(rollbackFor=Exception.class)
    public void save(Map<String,String> form, String actorId) {
        if (form == null || actorId == null || actorId.trim().isEmpty())
            throw new SecurityException("로그인이 필요합니다.");
        int emsId = number(form.get("emsId"), "시스템", 1, 99999);
        String kind = form.get("dataSeCd");
        Map<String,Object> args = key(Integer.valueOf(emsId), kind);
        String mode = form.get("mode");
        if (!"CREATE".equals(mode) && !"UPDATE".equals(mode))
            throw new IllegalArgumentException("등록/수정 요청 구분이 올바르지 않습니다.");
        args.put("useYn", yesNo(form.get("useYn")));
        args.put("excnTm", timeOrNull(form.get("excnTm")));
        String note = form.get("cycleCrtrCn");
        if (note != null && note.length() > 1000) throw new IllegalArgumentException("주기 근거는 최대 1000자입니다.");
        args.put("cycleCrtrCn", note == null || note.trim().isEmpty() ? null : note.trim());
        args.put("perfClctUseYn", yesNo(form.get("perfClctUseYn")));
        args.put("pingMntrUseYn", yesNo(form.get("pingMntrUseYn")));
        args.put("clctCycleSec", number(form.get("clctCycleSec"), "수집주기", 60, 31536000));
        args.put("sttsMntrCycleSec", number(form.get("sttsMntrCycleSec"), "PING 폴링주기", 1, 30));
        args.put("timeoutSec", number(form.get("timeoutSec"), "타임아웃 시간", 1, 3600));
        args.put("rtryNocs", number(form.get("rtryNocs"), "재시도 횟수", 1, 100));
        args.put("timeoutPollSec", number(form.get("timeoutPollSec"), "재확인 주기", 1, 3600));
        args.put("actorId", actorId);
        Map<String,Object> old = mapper.selectCycle(args);
        if ("CREATE".equals(mode)) {
            if (old != null) throw new IllegalArgumentException("해당 시스템과 데이터 구분의 설정이 이미 있습니다. 수정 기능을 이용해 주세요.");
            if (mapper.insertCycle(args) != 1) throw new IllegalStateException("수집주기 등록에 실패했습니다.");
        } else {
            if (old == null) throw new IllegalArgumentException("수정할 수집주기 설정이 없습니다.");
            if (mapper.updateCycle(args) != 1) throw new IllegalStateException("수집주기 변경에 실패했습니다.");
        }
    }

    @Transactional(rollbackFor=Exception.class)
    public void delete(Integer emsId, String dataSeCd) {
        Map<String,Object> key = key(emsId, dataSeCd);
        if (mapper.deleteCycle(key) != 1) throw new IllegalArgumentException("삭제할 수집주기 설정이 없습니다.");
    }

    private Map<String,Object> key(Integer emsId, String dataSeCd) {
        if (emsId == null) throw new IllegalArgumentException("시스템을 선택해 주세요.");
        String system=codes.codeForEms(emsId.intValue());
        if(system==null) throw new IllegalArgumentException("관리대상이 아닌 EMS 시스템입니다.");
        SystemDataScope.requireSystem(system);
        if (!("P".equals(dataSeCd) || "C".equals(dataSeCd) || "F".equals(dataSeCd) || "S".equals(dataSeCd)))
            throw new IllegalArgumentException("데이터 구분은 P, C, F, S만 허용합니다.");
        Map<String,Object> result = new HashMap<String,Object>();
        result.put("emsId", emsId);
        result.put("dataSeCd", dataSeCd);
        return result;
    }

    private String timeOrNull(String value) {
        if (value == null || value.trim().isEmpty()) return null;
        String str = value.trim();
        if (!str.matches("(?:[01][0-9]|2[0-3]):[0-5][0-9](?::[0-5][0-9])?"))
            throw new IllegalArgumentException("실행시각은 HH:mm 형식으로 입력해 주세요.");
        return str.length() == 5 ? str + ":00" : str;
    }

    private String yesNo(String value) { return "Y".equalsIgnoreCase(value) ? "Y" : "N"; }
    private int number(String value, String name, int min, int max) {
        try {
            int n = Integer.parseInt(value);
            if (n >= min && n <= max) return n;
        } catch (Exception ignored) { }
        throw new IllegalArgumentException(name + "은(는) " + min + "~" + max + " 사이로 입력해 주세요.");
    }
}
