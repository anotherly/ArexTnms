package kr.co.TRSolution.tnms.auth.mapper;

import java.util.List;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.auth.vo.AuthVO;
import kr.co.TRSolution.tnms.auth.vo.MenuAuthVO;

@Mapper("authMapper")
public interface AuthMapper {
    List<AuthVO> selectAuthList();
    AuthVO selectAuth(String authrtCd);
    int countAuthCode(AuthVO authVO);
    int countAuthName(AuthVO authVO);
    int countAuthUsers(String authrtCd);
    int insertAuth(AuthVO authVO);
    int updateAuth(AuthVO authVO);
    int deleteAuthMenus(String authrtCd);
    int disableAuth(AuthVO authVO);
    List<MenuAuthVO> selectMenuAuthList(String authrtCd);
    int insertMenuAuth(MenuAuthVO menuAuthVO);
}
