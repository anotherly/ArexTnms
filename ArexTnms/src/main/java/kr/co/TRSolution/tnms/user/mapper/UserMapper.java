package kr.co.TRSolution.tnms.user.mapper;

import java.util.List;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Mapper("userMapper")
public interface UserMapper {
    List<UserVO> selectUserList(UserVO searchVO);
    UserVO selectUser(Long userSn);
    UserVO selectLoginUser(String userId);
    int countByUserId(String userId);
    int insertUser(UserVO userVO);
    int insertUserAuth(UserVO userVO);
    int updateUser(UserVO userVO);
    int updatePassword(UserVO userVO);
    int deleteUserAuth(Long userSn);
    int softDeleteUser(UserVO userVO);
    int unlockUser(UserVO userVO);
    int increaseLoginFailure(Long userSn);
    int resetLoginFailure(Long userSn);
    int insertLoginLog(UserVO userVO);
    int updateLogoutLog(Long userSn);
}
