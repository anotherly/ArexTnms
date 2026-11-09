package kr.co.TRSolution.tnms.monitoring.service.impl;

import kr.co.TRSolution.tnms.common.security.SystemDataScope;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.monitoring.mapper.MonitoringMapper;
import kr.co.TRSolution.tnms.gateway.service.GatewayLiveService;
import kr.co.TRSolution.tnms.monitoring.service.MonitoringService;
import kr.co.TRSolution.tnms.monitoring.vo.EquipmentVO;
import kr.co.TRSolution.tnms.monitoring.vo.StationStatusVO;
import kr.co.TRSolution.tnms.setting.mapper.SettingMapper;
import kr.co.TRSolution.tnms.setting.vo.UiSettingVO;

@Service("monitoringService")
public class MonitoringServiceImpl implements MonitoringService {
    private static final String STATION_STATUS_PRIORITY = "STATION_STATUS_PRIORITY";
    private static final List<String> DEFAULT_STATUS_PRIORITY = Arrays.asList("CRITICAL", "CAUTION", "NORMAL");
    @Resource(name = "monitoringMapper") private MonitoringMapper monitoringMapper;
    @Resource(name = "gatewayLiveService") private GatewayLiveService gatewayLiveService;
    @Resource(name = "settingMapper") private SettingMapper settingMapper;

    @Override
    public Map<String, Object> selectDashboard() {
        Map<String, Object> result = new HashMap<String, Object>();
        EquipmentVO all = new EquipmentVO();
        List<String> priority = loadStatusPriority();
        List<EquipmentVO> systems = gatewayLiveService.systems();
        applyEquipmentPriority(systems, priority);
        List<StationStatusVO> stations = gatewayLiveService.stations(all);
        applyStationPriority(stations, priority);
        result.put("systems", systems);
        result.put("stations", stations);
        result.put("statusCodes", dashboardStatusCodes());
        return result;
    }

    @Override
    public Map<String, Object> selectFacility(EquipmentVO searchVO) {
        validateSystem(searchVO == null ? null : searchVO.getLinkSysCd());
        Map<String, Object> result = new HashMap<String, Object>();
        List<StationStatusVO> stations = gatewayLiveService.stations(searchVO);
        applyStationPriority(stations, loadStatusPriority());
        List<EquipmentVO> equipments = gatewayLiveService.devices(searchVO);
        result.put("stations", stations);
        result.put("equipments", equipments);
        result.put("summary", gatewayLiveService.summary(searchVO));
        result.put("statusCodes", dashboardStatusCodes());
        result.put("equipmentClassifications", monitoringMapper.selectEquipmentClassifications(searchVO.getLinkSysCd()));
        if ("EMS_PIDS".equals(searchVO.getLinkSysCd())) {
            result.put("lseCandidates", java.util.Collections.<EquipmentVO>emptyList());
            // 장애 메시지는 raw_event_action에서 수신된 장애만 사용한다.
            Map<String,Object> faultArgs = new HashMap<String,Object>();
            faultArgs.put("linkSysCd", "EMS_PIDS");
            if (searchVO.getStnCd()!=null && !searchVO.getStnCd().trim().isEmpty())
                faultArgs.put("stnCd", searchVO.getStnCd());
            result.put("gatewayFaults", gatewayLiveService.activeFaults(faultArgs));
        }
        if ("EMS_TX".equals(searchVO.getLinkSysCd())) {
            result.put("equipmentLinks", java.util.Collections.<kr.co.TRSolution.tnms.monitoring.vo.EquipmentLinkVO>emptyList());
        }
        if ("SCADA_SEC".equals(searchVO.getLinkSysCd())) {
            result.put("scadaEvents", java.util.Collections.<kr.co.TRSolution.tnms.monitoring.vo.ScadaEventVO>emptyList());
        }
        return result;
    }

    @Override
    public List<StationStatusVO> selectStationSummary(EquipmentVO searchVO) {
        List<StationStatusVO> stations = gatewayLiveService.stations(searchVO == null ? new EquipmentVO() : searchVO);
        applyStationPriority(stations, loadStatusPriority());
        return stations;
    }

    @Override
    public List<EquipmentVO> selectStationSystemSummary(String stnCd) {
        if (stnCd == null || stnCd.trim().length() == 0) throw new IllegalArgumentException("역사코드가 필요합니다.");
        List<EquipmentVO> systems = gatewayLiveService.stationSystems(stnCd);
        applyEquipmentPriority(systems, loadStatusPriority());
        return systems;
    }

    @Override
    public EquipmentVO selectEquipment(Long eqpmntSn) {
        throw new UnsupportedOperationException("기존 EQPMNT_SN 상세조회는 종료되었습니다. (emsId, deviceId)로 /facility/gateway-detail.ajax를 사용하세요.");
    }

    /** Web edits only user-maintained equipment metadata; ping status/timestamps remain gateway-owned. */
    @Override
    @Transactional(rollbackFor=Exception.class)
    public Long saveEquipment(EquipmentVO vo, String actorId) {
        if (vo==null || blank(vo.getLinkSysCd())) throw new IllegalArgumentException("연계시스템을 선택해 주세요.");
        int ems=emsId(vo.getLinkSysCd());
        if (vo.getEmsId()!=null && !blank(vo.getEmsId()) && Integer.parseInt(vo.getEmsId())!=ems)
            throw new IllegalArgumentException("EMS ID와 화면의 연계시스템이 일치하지 않습니다.");
        kr.co.TRSolution.tnms.common.security.SystemDataScope.requireSystem(vo.getLinkSysCd());
        String key=vo.getGatewayDeviceId();
        boolean modify=!blank(key);
        if (!modify) key=vo.getEqpmntMngNo();
        if (blank(key) || key.length()>50 || blank(vo.getEqpmntNm()) || blank(vo.getEqpmntSeCd()) || blank(vo.getEqpmntIpAddr()) || blank(vo.getInstlPlcNm()))
            throw new IllegalArgumentException("장비 ID(50자 이하), 장비명, 종류, IP, 설치장소는 필수입니다.");
        if (vo.getEqpmntIpAddr().length()>20) throw new IllegalArgumentException("IP는 20자 이하여야 합니다.");
        vo.setEmsId(String.valueOf(ems));
        vo.setEqpmntMngNo(key);
        if (blank(vo.getStnCd())) vo.setStnCd("Unknown");
        if (vo.getDeviceCheck()==null) vo.setDeviceCheck(0);
        if (blank(vo.getTestYn())) vo.setTestYn("N");
        if (blank(vo.getUseYn())) vo.setUseYn("Y");
        if (!"Y".equals(vo.getTestYn()) && !"N".equals(vo.getTestYn())) throw new IllegalArgumentException("테스트 장비 여부가 올바르지 않습니다.");
        vo.setRegId(actorId);vo.setModId(actorId);
        if (modify) {
            if (monitoringMapper.updateGatewayDevice(vo)!=1) throw new IllegalArgumentException("수정 대상 장비가 없습니다.");
        } else {
            monitoringMapper.insertGatewayDevice(vo);
        }
        return Long.valueOf(1L);
    }

    @Override public void deleteEquipment(Long sn, String actorId) {
        throw new IllegalArgumentException("일련번호가 아니라 EMS ID와 장비 ID로 삭제해야 합니다.");
    }

    @Override
    @Transactional(rollbackFor=Exception.class)
    public void deleteEquipmentByKey(int ems, String key, String actorId) {
        String sys=systemCode(ems);
        kr.co.TRSolution.tnms.common.security.SystemDataScope.requireSystem(sys);
        if (blank(key)) throw new IllegalArgumentException("장비 ID가 필요합니다.");
        Map<String,Object> q=new HashMap<String,Object>();q.put("emsId",ems);q.put("deviceId",key);
        if (monitoringMapper.deleteGatewayDevice(q)!=1) throw new IllegalArgumentException("장비가 없거나 이미 삭제되었습니다.");
    }
    private int emsId(String code) {
        if ("EMS_TX".equals(code))return 1;if ("VMS".equals(code))return 4;
        if ("PBX".equals(code))return 11;if ("EMS_PIDS".equals(code))return 13;
        if ("SCADA_SEC".equals(code))return 16;
        throw new IllegalArgumentException("허용되지 않은 연계시스템입니다.");
    }
    private String systemCode(int id){
        if(id==1)return "EMS_TX";if(id==4)return "VMS";if(id==11)return "PBX";
        if(id==13)return "EMS_PIDS";if(id==16)return "SCADA_SEC";
        throw new IllegalArgumentException("허용되지 않은 EMS ID입니다.");
    }

    private void validateSystem(String linkSysCd) {
        if (blank(linkSysCd)) throw new IllegalArgumentException("연계시스템 코드가 필요합니다.");
    }

    /** 신규 CD_SYST_### 식별자를 화면 상태코드 NORMAL/CAUTION/CRITICAL/UNKNOWN으로 변환. */
    private List<kr.co.TRSolution.tnms.setting.vo.CommonCodeVO> dashboardStatusCodes() {
        List<kr.co.TRSolution.tnms.setting.vo.CommonCodeVO> codes = settingMapper.selectCommonCodeList("CD_SYST");
        for (kr.co.TRSolution.tnms.setting.vo.CommonCodeVO code : codes) {
            String id=code.getComCd();
            if ("CD_SYST_001".equals(id)) code.setComCd("CRITICAL");
            else if ("CD_SYST_002".equals(id)) code.setComCd("CAUTION");
            else if ("CD_SYST_003".equals(id)) code.setComCd("NORMAL");
            else if ("CD_SYST_004".equals(id)) code.setComCd("UNKNOWN");
        }
        return codes;
    }

    private String trim(String value) { return value == null || value.trim().length() == 0 ? null : value.trim(); }

    private boolean blank(String value) { return value == null || value.trim().length() == 0; }

    private String normalizeStatusCode(String value) {
        if (value == null) return "";
        String code = value.trim();
        if ("WARNING".equals(code)) return "CAUTION";
        return "OFFLINE".equals(code) ? "UNKNOWN" : code;
    }

    private List<String> loadStatusPriority() {
        UiSettingVO setting = settingMapper.selectUiSetting(STATION_STATUS_PRIORITY);
        if (setting == null || blank(setting.getUiStngVl())) return DEFAULT_STATUS_PRIORITY;
        String[] values = setting.getUiStngVl().split(",");
        List<String> result = new ArrayList<String>();
        Set<String> unique = new HashSet<String>();
        for (String value : values) {
            String code = normalizeStatusCode(value);
            if (DEFAULT_STATUS_PRIORITY.contains(code) && unique.add(code)) result.add(code);
        }
        return result.size() == DEFAULT_STATUS_PRIORITY.size() ? result : DEFAULT_STATUS_PRIORITY;
    }


    private void applyEquipmentPriority(List<EquipmentVO> systems, List<String> priority) {
        if (systems == null) return;
        for (EquipmentVO system : systems) {
            system.setSttsCd(resolveStatus(system.getTotalNocs(), system.getNormalNocs(), system.getCautionNocs(),
                    system.getCriticalNocs(), system.getOfflineNocs(), system.getUnknownNocs(), priority));
        }
    }

    private void applyStationPriority(List<StationStatusVO> stations, List<String> priority) {
        if (stations == null) return;
        for (StationStatusVO station : stations) {
            station.setSttsCd(resolveStatus(station.getTotalNocs(), station.getNormalNocs(), station.getCautionNocs(),
                    station.getCriticalNocs(), station.getOfflineNocs(), station.getUnknownNocs(), priority));
        }
    }

    private String resolveStatus(Integer total, Integer normal, Integer caution, Integer critical,
                                 Integer offline, Integer unknown, List<String> priority) {
        if (!positive(total)) return "UNKNOWN";
        // 실제 장애·주의가 있을 경우 우선 반영; 그 외에는 PING 실패 및 수집 지연을 정상으로 표시하지 않음.
        if (positive(critical)) return "CRITICAL";
        if (positive(caution)) return "CAUTION";
        if (positive(offline)) return "OFFLINE";
        if (positive(unknown)) return "UNKNOWN";
        for (String code : priority) {
            if ("CRITICAL".equals(code) && positive(critical)) return code;
            if ("CAUTION".equals(code) && positive(caution)) return code;
            if ("NORMAL".equals(code) && positive(normal)) return code;
        }
        return "UNKNOWN";
    }

    private boolean positive(Integer value) { return value != null && value.intValue() > 0; }
}
