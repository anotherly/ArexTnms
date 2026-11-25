package kr.co.TRSolution.tnms.user.mapper;

import java.util.List;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Mapper("userMapper")
public interface UserMapper {
    List<UserVO> selectUserList(UserVO searchVO);
    UserVO selectUser(String userId);
    UserVO selectLoginUser(String userId);
    int countByUserId(String userId);
    int insertUser(UserVO userVO);
    int updateUser(UserVO userVO);
    int updatePassword(UserVO userVO);
    int softDeleteUser(UserVO userVO);
    int unlockUser(UserVO userVO);
    int increaseLoginFailure(String userId);
    int resetLoginFailure(String userId);
    int insertLoginLog(UserVO userVO);
    int updateLogoutLog(String userId);
}
