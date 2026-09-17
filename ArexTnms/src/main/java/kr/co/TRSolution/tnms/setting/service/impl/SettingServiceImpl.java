package kr.co.TRSolution.tnms.setting.service.impl;

import java.util.Arrays;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.setting.mapper.SettingMapper;
import kr.co.TRSolution.tnms.setting.service.SettingService;
import kr.co.TRSolution.tnms.setting.vo.CommonCodeVO;
import kr.co.TRSolution.tnms.setting.vo.UiSettingVO;

@Service("settingService")
public class SettingServiceImpl implements SettingService {
    private static final String STATION_STATUS_PRIORITY = "STATION_STATUS_PRIORITY";
    private static final Set<String> STATION_STATUS_CODES = new HashSet<String>(Arrays.asList("CRITICAL", "CAUTION", "UNKNOWN", "NORMAL"));
    @Resource(name = "settingMapper") private SettingMapper settingMapper;

    @Override
    public Map<String, Object> selectSettings(String groupId) {
        List<CommonCodeVO> groups = settingMapper.selectCodeGroupList();
        String selected = groupId;
        if ((selected == null || selected.trim().length() == 0) && !groups.isEmpty()) selected = groups.get(0).getComCdGroupId();
        Map<String, Object> result = new HashMap<String, Object>();
        result.put("uiSettings", settingMapper.selectUiSettingList());
        result.put("codeGroups", groups);
        result.put("selectedGroupId", selected);
        result.put("codes", selected == null ? java.util.Collections.emptyList() : settingMapper.selectCommonCodeList(selected));
        result.put("severityCodes", settingMapper.selectCommonCodeList("SYS_STTS"));
        return result;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveUiSettings(List<UiSettingVO> list, String actorId) {
        if (list == null || list.isEmpty()) throw new IllegalArgumentException("저장할 UI 설정이 없습니다.");
        for (UiSettingVO vo : list) {
            if (blank(vo.getUiStngCd()) || blank(vo.getUiStngVl())) throw new IllegalArgumentException("UI 설정 코드와 값을 확인해 주세요.");
            if (STATION_STATUS_PRIORITY.equals(vo.getUiStngCd())) {
                vo.setUiStngVl(normalizeStationStatusPriority(vo.getUiStngVl()));
                validateStationStatusPriority(vo.getUiStngVl());
            }
            vo.setMdfrId(actorId);
            if (settingMapper.updateUiSetting(vo) != 1) throw new IllegalArgumentException("존재하지 않는 UI 설정입니다: " + vo.getUiStngCd());
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveCommonCode(CommonCodeVO vo, String actorId) {
        if (vo == null || blank(vo.getComCdGroupId()) || blank(vo.getComCd()) || blank(vo.getComCdNm())) throw new IllegalArgumentException("코드 그룹, 코드, 코드명을 입력해 주세요.");
        if (vo.getComCdSeq() == null) vo.setComCdSeq(Integer.valueOf(1));
        if (blank(vo.getComCdUseYn())) vo.setComCdUseYn("Y");
        if (settingMapper.countCommonCode(vo) == 0) {
            vo.setRgtrId(actorId);
            settingMapper.insertCommonCode(vo);
        } else {
            vo.setMdfrId(actorId);
            settingMapper.updateCommonCode(vo);
        }
    }

    private boolean blank(String v) { return v == null || v.trim().length() == 0; }

    private String normalizeStatusCode(String value) {
        if (value == null) return "";
        String code = value.trim();
        if ("WARNING".equals(code)) return "CAUTION";
        return "OFFLINE".equals(code) ? "UNKNOWN" : code;
    }

    private String normalizeStationStatusPriority(String value) {
        String[] codes = value.split(",");
        java.util.List<String> normalized = new java.util.ArrayList<String>();
        Set<String> unique = new HashSet<String>();
        for (String code : codes) {
            String normalizedCode = normalizeStatusCode(code);
            if (unique.add(normalizedCode)) normalized.add(normalizedCode);
        }
        return String.join(",", normalized);
    }

    private void validateStationStatusPriority(String value) {
        String[] codes = value.split(",");
        Set<String> unique = new HashSet<String>();
        for (String code : codes) unique.add(normalizeStatusCode(code));
        if (codes.length != STATION_STATUS_CODES.size() || !unique.equals(STATION_STATUS_CODES)) {
            throw new IllegalArgumentException("역사 대표색 우선순위는 장애, 주의, 통신단절, 정상 항목을 중복 없이 모두 포함해야 합니다.");
        }
    }
}
