package kr.co.TRSolution.tnms.auth.mapper;

import java.util.List;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.auth.vo.AuthVO;
import kr.co.TRSolution.tnms.auth.vo.MenuAuthVO;

@Mapper("authMapper")
public interface AuthMapper {
    List<AuthVO> selectAuthList();
    AuthVO selectAuth(Long authrtSn);
    int countAuthName(AuthVO authVO);
    int countAuthUsers(Long authrtSn);
    int insertAuth(AuthVO authVO);
    int updateAuth(AuthVO authVO);
    int deleteAuthMenus(Long authrtSn);
    int deleteAuth(Long authrtSn);
    List<MenuAuthVO> selectMenuAuthList(Long authrtSn);
    int insertMenuAuth(MenuAuthVO menuAuthVO);
}
