package kr.co.TRSolution.tnms.auth.service.impl;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.auth.mapper.AuthMapper;
import kr.co.TRSolution.tnms.auth.service.AuthService;
import kr.co.TRSolution.tnms.auth.vo.AuthVO;
import kr.co.TRSolution.tnms.auth.vo.MenuAuthVO;

@Service("authService")
public class AuthServiceImpl implements AuthService {
    @Resource(name = "authMapper")
    private AuthMapper authMapper;

    @Override
    public List<AuthVO> selectAuthList() { return authMapper.selectAuthList(); }

    @Override
    public AuthVO selectAuth(Long authrtSn) {
        AuthVO auth = authMapper.selectAuth(authrtSn);
        if (auth == null) throw new IllegalArgumentException("존재하지 않는 권한입니다.");
        auth.setMenuAuthList(authMapper.selectMenuAuthList(authrtSn));
        return auth;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AuthVO createAuth(AuthVO authVO, Long actorSn) {
        normalizeAndValidate(authVO);
        authVO.setUseYn("Y");
        authVO.setAuthrtSttsNm("사용");
        authVO.setRgtrSn(actorSn);
        if (authMapper.countAuthName(authVO) > 0) throw new IllegalArgumentException("이미 사용 중인 권한명입니다.");
        if (authMapper.insertAuth(authVO) != 1) throw new IllegalStateException("권한 등록에 실패했습니다.");
        return authVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateAuth(AuthVO authVO, Long actorSn) {
        normalizeAndValidate(authVO);
        if (authVO.getAuthrtSn() == null || authMapper.selectAuth(authVO.getAuthrtSn()) == null) {
            throw new IllegalArgumentException("수정할 권한이 없습니다.");
        }
        authVO.setMdfrSn(actorSn);
        if (authMapper.countAuthName(authVO) > 0) throw new IllegalArgumentException("이미 사용 중인 권한명입니다.");
        if (authMapper.updateAuth(authVO) != 1) throw new IllegalStateException("권한 수정에 실패했습니다.");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteAuth(Long authrtSn) {
        if (Long.valueOf(1L).equals(authrtSn)) throw new IllegalArgumentException("시스템 관리자 권한은 삭제할 수 없습니다.");
        if (authMapper.countAuthUsers(authrtSn) > 0) throw new IllegalStateException("해당 권한을 사용 중인 사용자가 있습니다.");
        authMapper.deleteAuthMenus(authrtSn);
        if (authMapper.deleteAuth(authrtSn) != 1) throw new IllegalArgumentException("삭제할 권한이 없습니다.");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveMenuPermissions(Long authrtSn, List<MenuAuthVO> permissions) {
        if (authMapper.selectAuth(authrtSn) == null) throw new IllegalArgumentException("권한 정보가 없습니다.");
        authMapper.deleteAuthMenus(authrtSn);
        if (permissions == null) return;
        for (MenuAuthVO permission : permissions) {
            permission.setAuthrtSn(authrtSn);
            normalizePermission(permission, Long.valueOf(1L).equals(authrtSn));
            authMapper.insertMenuAuth(permission);
        }
    }

    @Override
    public Map<String, MenuAuthVO> selectPermissionMap(Long authrtSn) {
        Map<String, MenuAuthVO> map = new LinkedHashMap<String, MenuAuthVO>();
        for (MenuAuthVO item : authMapper.selectMenuAuthList(authrtSn)) {
            map.put(item.getScreenKey(), item);
        }
        return map;
    }

    private void normalizeAndValidate(AuthVO auth) {
        String name = auth.getAuthrtNm() == null ? "" : auth.getAuthrtNm().trim();
        if (name.length() == 0 || name.length() > 100) throw new IllegalArgumentException("권한명은 1~100자로 입력해 주세요.");
        auth.setAuthrtNm(name);
        if (auth.getAuthrtExpln() != null && auth.getAuthrtExpln().length() > 4000) {
            throw new IllegalArgumentException("권한설명은 4,000자 이내로 입력해 주세요.");
        }
        if (auth.getUseYn() == null) auth.setUseYn("Y");
        auth.setAuthrtSttsNm("Y".equals(auth.getUseYn()) ? "사용" : "미사용");
    }

    private void normalizePermission(MenuAuthVO item, boolean systemAdmin) {
        if (systemAdmin) {
            item.setListAuthrtYn("Y"); item.setDtlAuthrtYn("Y"); item.setRegAuthrtYn("Y");
            item.setMdfcnAuthrtYn("Y"); item.setDelAuthrtYn("Y"); item.setCtrlAuthrtYn("Y");
            return;
        }
        item.setListAuthrtYn(yn(item.getListAuthrtYn()));
        item.setDtlAuthrtYn(yn(item.getDtlAuthrtYn()));
        item.setRegAuthrtYn(yn(item.getRegAuthrtYn()));
        item.setMdfcnAuthrtYn(yn(item.getMdfcnAuthrtYn()));
        item.setDelAuthrtYn(yn(item.getDelAuthrtYn()));
        item.setCtrlAuthrtYn(yn(item.getCtrlAuthrtYn()));
        if ("Y".equals(item.getMdfcnAuthrtYn()) || "Y".equals(item.getDelAuthrtYn())) item.setDtlAuthrtYn("Y");
        if ("Y".equals(item.getDtlAuthrtYn()) || "Y".equals(item.getRegAuthrtYn()) ||
            "Y".equals(item.getMdfcnAuthrtYn()) || "Y".equals(item.getDelAuthrtYn()) ||
            "Y".equals(item.getCtrlAuthrtYn())) item.setListAuthrtYn("Y");
    }

    private String yn(String value) { return "Y".equals(value) ? "Y" : "N"; }
}
