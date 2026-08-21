package kr.co.TRSolution.tnms.user.service;

import java.util.List;

import kr.co.TRSolution.tnms.user.vo.UserVO;

public interface UserService {
    List<UserVO> selectUserList(UserVO searchVO);
    UserVO selectUser(Long userSn);
    UserVO selectLoginUser(String userId);
    boolean isUserIdAvailable(String userId);
    void createUser(UserVO userVO, UserVO actor);
    void updateUser(UserVO userVO, UserVO actor);
    void deleteUser(Long userSn, UserVO actor);
    void unlockUser(Long userSn, UserVO actor);
    void recordLoginFailure(UserVO userVO, String ip, String browser, String reason);
    void recordLoginSuccess(UserVO userVO, String ip, String browser);
    void recordLogout(UserVO userVO);
}
