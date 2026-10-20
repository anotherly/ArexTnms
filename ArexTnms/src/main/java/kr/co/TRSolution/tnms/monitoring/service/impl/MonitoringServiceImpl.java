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
    @Resource(name = "settingMapper") private SettingMapper settingMapper;

    @Override
    public Map<String, Object> selectDashboard() {
        Map<String, Object> result = new HashMap<String, Object>();
        EquipmentVO all = new EquipmentVO();
        List<String> priority = loadStatusPriority();
        List<EquipmentVO> systems = monitoringMapper.selectSystemSummary();
        applyEquipmentPriority(systems, priority);
        List<StationStatusVO> stations = monitoringMapper.selectStationSummary(all);
        applyStationPriority(stations, priority);
        result.put("systems", systems);
        result.put("stations", stations);
        result.put("statusCodes", settingMapper.selectCommonCodeList("SYS_STTS"));
        return result;
    }

    @Override
    public Map<String, Object> selectFacility(EquipmentVO searchVO) {
        validateSystem(searchVO == null ? null : searchVO.getLinkSysCd());
        Map<String, Object> result = new HashMap<String, Object>();
        List<StationStatusVO> stations = monitoringMapper.selectStationSummary(searchVO);
        applyStationPriority(stations, loadStatusPriority());
        List<EquipmentVO> equipments = monitoringMapper.selectEquipmentList(searchVO);
        result.put("stations", stations);
        result.put("equipments", equipments);
        result.put("summary", monitoringMapper.selectEquipmentSummary(searchVO));
        result.put("statusCodes", settingMapper.selectCommonCodeList("SYS_STTS"));
        result.put("equipmentClassifications", monitoringMapper.selectEquipmentClassifications(searchVO.getLinkSysCd()));
        if ("EMS_PIDS".equals(searchVO.getLinkSysCd())) {
            result.put("lseCandidates", monitoringMapper.selectPidsLseCandidates(searchVO));
        }
        if ("EMS_TX".equals(searchVO.getLinkSysCd())) {
            result.put("equipmentLinks", monitoringMapper.selectEquipmentLinks(searchVO));
        }
        if ("SCADA_SEC".equals(searchVO.getLinkSysCd())) {
            result.put("scadaEvents", monitoringMapper.selectRecentScadaEvents(searchVO));
        }
        return result;
    }

    @Override
    public List<StationStatusVO> selectStationSummary(EquipmentVO searchVO) {
        List<StationStatusVO> stations = monitoringMapper.selectStationSummary(searchVO == null ? new EquipmentVO() : searchVO);
        applyStationPriority(stations, loadStatusPriority());
        return stations;
    }

    @Override
    public List<EquipmentVO> selectStationSystemSummary(String stnCd) {
        if (stnCd == null || stnCd.trim().length() == 0) throw new IllegalArgumentException("역사코드가 필요합니다.");
        List<EquipmentVO> systems = monitoringMapper.selectStationSystemSummary(stnCd);
        applyEquipmentPriority(systems, loadStatusPriority());
        return systems;
    }

    @Override
    public EquipmentVO selectEquipment(Long eqpmntSn) {
        EquipmentVO equipment = monitoringMapper.selectEquipment(eqpmntSn);
        if (equipment == null) throw new IllegalArgumentException("장비 정보를 찾을 수 없습니다.");
        return equipment;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public Long saveEquipment(EquipmentVO equipmentVO, String actorId) {
        normalize(equipmentVO);
        if ("VMS".equals(equipmentVO.getLinkSysCd())) {
            normalizeCctv(equipmentVO);
            syncCctvMasterFields(equipmentVO);
        }
        validateEquipment(equipmentVO);
        SystemDataScope.requireSystem(equipmentVO.getLinkSysCd());
        if (equipmentVO.getEqpmntSn() != null && monitoringMapper.selectEquipment(equipmentVO.getEqpmntSn()) == null)
            throw new SecurityException("수정할 장비에 대한 데이터 접근 권한이 없습니다.");
        if (equipmentVO.getEqpmntSn() == null) {
            equipmentVO.setRgtrId(actorId);
            if (monitoringMapper.insertEquipment(equipmentVO) != 1) throw new IllegalStateException("장비 등록에 실패했습니다.");
        } else {
            equipmentVO.setMdfrId(actorId);
            if (monitoringMapper.updateEquipment(equipmentVO) != 1) throw new IllegalArgumentException("수정할 장비를 찾을 수 없습니다.");
        }
        if ("EMS_PIDS".equals(equipmentVO.getLinkSysCd())) {
            savePidsLseRelations(equipmentVO);
        }
        if ("VMS".equals(equipmentVO.getLinkSysCd())) {
            equipmentVO.setMdfrId(actorId);
            monitoringMapper.updateCctvEquipmentMirror(equipmentVO);
            monitoringMapper.upsertCctvInfo(equipmentVO);
        }
        return equipmentVO.getEqpmntSn();
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteEquipment(Long eqpmntSn, String actorId) {
        if (eqpmntSn == null) throw new IllegalArgumentException("삭제할 장비를 선택해 주세요.");
        if (monitoringMapper.selectEquipment(eqpmntSn) == null)
            throw new SecurityException("삭제할 장비에 대한 데이터 접근 권한이 없습니다.");
        EquipmentVO equipment = new EquipmentVO();
        equipment.setEqpmntSn(eqpmntSn);
        equipment.setMdfrId(actorId);
        if (monitoringMapper.disableEquipment(equipment) != 1) throw new IllegalArgumentException("삭제할 장비를 찾을 수 없습니다.");
    }

    private void validateSystem(String linkSysCd) {
        if (linkSysCd == null || linkSysCd.trim().length() == 0) throw new IllegalArgumentException("연계시스템 코드가 필요합니다.");
    }

    private void validateEquipment(EquipmentVO vo) {
        if (vo == null) throw new IllegalArgumentException("장비 정보가 없습니다.");
        validateSystem(vo.getLinkSysCd());
        if (blank(vo.getEqpmntMngNo())) throw new IllegalArgumentException("장비관리번호를 입력해 주세요.");
        if (blank(vo.getEqpmntNm())) throw new IllegalArgumentException("장비명을 입력해 주세요.");
        if (blank(vo.getEqpmntSeCd())) throw new IllegalArgumentException("장비구분코드를 입력해 주세요.");
        if ("VMS".equals(vo.getLinkSysCd())) validateCctv(vo);
        if (monitoringMapper.countEquipmentMngNo(vo) > 0) {
            throw new IllegalArgumentException("이미 사용 중인 장비관리번호입니다. 다른 번호를 입력해 주세요.");
        }
        if (!blank(vo.getEqpmntClsfCd()) && monitoringMapper.countEquipmentClassification(vo) == 0) {
            throw new IllegalArgumentException("선택한 장비분류가 현재 설비 시스템에 존재하지 않습니다. 장비분류를 다시 선택해 주세요.");
        }
        if (vo.getUseYn() == null) vo.setUseYn("Y");
    }

    private void normalize(EquipmentVO vo) {
        if (vo == null) return;
        vo.setEqpmntMngNo(trim(vo.getEqpmntMngNo()));
        vo.setEqpmntNm(trim(vo.getEqpmntNm()));
        vo.setEqpmntSeCd(trim(vo.getEqpmntSeCd()));
        vo.setEqpmntClsfCd(trim(vo.getEqpmntClsfCd()));
        vo.setLinkSysCd(trim(vo.getLinkSysCd()));
        vo.setStnCd(trim(vo.getStnCd()));
        vo.setEmsId(trim(vo.getEmsId()));
        vo.setInstlPlcNm(trim(vo.getInstlPlcNm()));
        vo.setEqpmntIpAddr(trim(vo.getEqpmntIpAddr()));
        vo.setMacAddr(trim(vo.getMacAddr()));
        vo.setEqpmntMdlNm(trim(vo.getEqpmntMdlNm()));
        vo.setEqpmntExpln(trim(vo.getEqpmntExpln()));
    }

    private void normalizeCctv(EquipmentVO vo) {
        vo.setVmsNm(trim(vo.getVmsNm()));
        vo.setStrgMthNm(trim(vo.getStrgMthNm()));
        vo.setCctvNm(trim(vo.getCctvNm()));
        vo.setCnsmrNm(trim(vo.getCnsmrNm()));
        vo.setCctvMdlNm(trim(vo.getCctvMdlNm()));
        vo.setFrmwrVerNo(trim(vo.getFrmwrVerNo()));
        vo.setCctvIpAddr(trim(vo.getCctvIpAddr()));
        vo.setCctvMacAddr(trim(vo.getCctvMacAddr()));
        vo.setAcntNm(trim(vo.getAcntNm()));
        vo.setVmsSrvrIpAddr(trim(vo.getVmsSrvrIpAddr()));
        vo.setFlrNm(trim(vo.getFlrNm()));
        if (vo.getCmraQty() == null || vo.getCmraQty().intValue() < 1) vo.setCmraQty(Integer.valueOf(1));
    }

    private void syncCctvMasterFields(EquipmentVO vo) {
        vo.setEqpmntSeCd("CCTV");
        vo.setEqpmntClsfCd(null);
        vo.setEqpmntNm(vo.getCctvNm());
        vo.setEqpmntIpAddr(vo.getCctvIpAddr());
        vo.setMacAddr(vo.getCctvMacAddr());
        vo.setEqpmntMdlNm(vo.getCctvMdlNm());
        vo.setInstlPlcNm(!blank(vo.getFlrNm()) ? vo.getFlrNm() : vo.getVmsNm());
    }

    private void validateCctv(EquipmentVO vo) {
        if (blank(vo.getVmsNm())) throw new IllegalArgumentException("역사_VMS 명을 입력해 주세요.");
        if (blank(vo.getStrgMthNm())) throw new IllegalArgumentException("저장방식을 입력해 주세요.");
        if (blank(vo.getCctvNm())) throw new IllegalArgumentException("CCTV 이름을 입력해 주세요.");
        if (blank(vo.getCnsmrNm())) throw new IllegalArgumentException("수요자를 입력해 주세요.");
        if (blank(vo.getCctvMdlNm())) throw new IllegalArgumentException("CCTV 모델을 입력해 주세요.");
        if (blank(vo.getCctvIpAddr())) throw new IllegalArgumentException("CCTV IP를 입력해 주세요.");
        if (blank(vo.getCctvMacAddr())) throw new IllegalArgumentException("CCTV MAC 주소를 입력해 주세요.");
        if (blank(vo.getVmsSrvrIpAddr())) throw new IllegalArgumentException("VMS 서버 IP를 입력해 주세요.");
    }

    private void savePidsLseRelations(EquipmentVO vo) {
        monitoringMapper.deletePidsLseRelations(vo.getEqpmntSn());
        if ("LSE".equalsIgnoreCase(vo.getEqpmntSeCd())) return;
        Long[] lseSns = vo.getLseEqpmntSns();
        if (lseSns == null || lseSns.length == 0) return;
        Set<Long> unique = new HashSet<Long>();
        for (Long lseSn : lseSns) {
            if (lseSn == null || lseSn.equals(vo.getEqpmntSn()) || !unique.add(lseSn)) continue;
            EquipmentVO rel = new EquipmentVO();
            rel.setEqpmntSn(vo.getEqpmntSn());
            rel.setLseEqpmntSn(lseSn);
            monitoringMapper.insertPidsLseRelation(rel);
        }
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
        for (String code : priority) {
            if ("CRITICAL".equals(code) && positive(critical)) return code;
            if ("CAUTION".equals(code) && positive(caution)) return code;
            if ("NORMAL".equals(code) && positive(normal)) return code;
        }
        return "UNKNOWN";
    }

    private boolean positive(Integer value) { return value != null && value.intValue() > 0; }
}
