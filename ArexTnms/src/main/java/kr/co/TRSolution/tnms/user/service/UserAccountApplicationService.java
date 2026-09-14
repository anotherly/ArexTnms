package kr.co.TRSolution.tnms.user.service;

import java.util.List;

import kr.co.TRSolution.tnms.user.vo.UserAccountApplicationVO;
import kr.co.TRSolution.tnms.user.vo.UserVO;

public interface UserAccountApplicationService {
    String submit(UserAccountApplicationVO application);
    List<UserAccountApplicationVO> selectApplicationList(UserAccountApplicationVO searchVO);
    UserAccountApplicationVO selectApplication(String aplyNo);
    void approve(String aplyNo, UserVO actor);
    void reject(String aplyNo, String reason, UserVO actor);
}
