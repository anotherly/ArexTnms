package kr.co.TRSolution.tnms.setting.mapper;

import java.util.List;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.setting.vo.CommonCodeVO;
import kr.co.TRSolution.tnms.setting.vo.UiSettingVO;

@Mapper("settingMapper")
public interface SettingMapper {
    List<UiSettingVO> selectUiSettingList();
    UiSettingVO selectUiSetting(String uiStngCd);
    int updateUiSetting(UiSettingVO vo);
    List<CommonCodeVO> selectCodeGroupList();
    List<CommonCodeVO> selectCommonCodeList(String groupId);
    int countCommonCode(CommonCodeVO vo);
    int insertCommonCode(CommonCodeVO vo);
    int updateCommonCode(CommonCodeVO vo);
}
