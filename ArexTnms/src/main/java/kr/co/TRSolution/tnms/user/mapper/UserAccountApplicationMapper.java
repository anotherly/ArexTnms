package kr.co.TRSolution.tnms.user.mapper;

import java.util.List;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.user.vo.UserAccountApplicationVO;

@Mapper("userAccountApplicationMapper")
public interface UserAccountApplicationMapper {
    int countUnavailableUserId(String userId);
    int insertAccountApplication(UserAccountApplicationVO application);
    List<UserAccountApplicationVO> selectApplicationList(UserAccountApplicationVO searchVO);
    UserAccountApplicationVO selectApplication(Long aplySn);
    UserAccountApplicationVO selectApplicationForUpdate(Long aplySn);
    Long selectAuthrtSnByName(String authrtNm);
    int approveApplication(UserAccountApplicationVO application);
    int rejectApplication(UserAccountApplicationVO application);
}
