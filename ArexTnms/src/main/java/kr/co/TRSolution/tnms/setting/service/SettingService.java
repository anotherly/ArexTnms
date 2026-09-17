package kr.co.TRSolution.tnms.setting.service;

import java.util.List;
import java.util.Map;

import kr.co.TRSolution.tnms.setting.vo.CommonCodeVO;
import kr.co.TRSolution.tnms.setting.vo.UiSettingVO;

public interface SettingService {
    Map<String, Object> selectSettings(String groupId);
    void saveUiSettings(List<UiSettingVO> list, String actorId);
    void saveCommonCode(CommonCodeVO vo, String actorId);
}
