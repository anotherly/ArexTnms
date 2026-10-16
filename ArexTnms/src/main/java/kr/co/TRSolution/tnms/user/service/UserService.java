package kr.co.TRSolution.tnms.user.service;

import java.util.List;

import kr.co.TRSolution.tnms.user.vo.UserVO;

public interface UserService {
    List<UserVO> selectUserList(UserVO searchVO);
    UserVO selectUser(String userId);
    UserVO selectLoginUser(String userId);
    boolean isUserIdAvailable(String userId);
    void createUser(UserVO userVO, UserVO actor);
    void updateUser(UserVO userVO, UserVO actor);
    void deleteUser(String userId, UserVO actor);
    void unlockUser(String userId, UserVO actor);
    void recordLoginFailure(UserVO userVO, String ip, String browser, String reason);
    void recordLoginSuccess(UserVO userVO, String ip, String browser);
    void recordLogout(UserVO userVO);
}
