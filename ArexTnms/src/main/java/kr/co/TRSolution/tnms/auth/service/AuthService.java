package kr.co.TRSolution.tnms.auth.service;

import java.util.List;
import java.util.Map;

import kr.co.TRSolution.tnms.auth.vo.AuthVO;
import kr.co.TRSolution.tnms.auth.vo.MenuAuthVO;
import kr.co.TRSolution.tnms.auth.vo.SystemAuthVO;

public interface AuthService {
    List<AuthVO> selectAuthList();
    AuthVO selectAuth(String authrtCd);
    AuthVO createAuth(AuthVO authVO, String actorId);
    void updateAuth(AuthVO authVO, String actorId);
    void deleteAuth(String authrtCd, String actorId);
    void saveMenuPermissions(String authrtCd, List<MenuAuthVO> permissions, List<SystemAuthVO> systemAuthList);
    List<String> selectAllowedSystemCodes(String authrtCd);
    Map<String, MenuAuthVO> selectPermissionMap(String authrtCd);
}
