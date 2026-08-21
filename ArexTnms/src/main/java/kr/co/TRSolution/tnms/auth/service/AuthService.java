package kr.co.TRSolution.tnms.auth.service;

import java.util.List;
import java.util.Map;

import kr.co.TRSolution.tnms.auth.vo.AuthVO;
import kr.co.TRSolution.tnms.auth.vo.MenuAuthVO;

public interface AuthService {
    List<AuthVO> selectAuthList();
    AuthVO selectAuth(Long authrtSn);
    AuthVO createAuth(AuthVO authVO, Long actorSn);
    void updateAuth(AuthVO authVO, Long actorSn);
    void deleteAuth(Long authrtSn);
    void saveMenuPermissions(Long authrtSn, List<MenuAuthVO> permissions);
    Map<String, MenuAuthVO> selectPermissionMap(Long authrtSn);
}
