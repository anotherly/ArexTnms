package kr.co.TRSolution.tnms.auth.service.impl;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.regex.Pattern;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.auth.mapper.AuthMapper;
import kr.co.TRSolution.tnms.auth.service.AuthService;
import kr.co.TRSolution.tnms.auth.vo.AuthVO;
import kr.co.TRSolution.tnms.auth.vo.MenuAuthVO;

@Service("authService")
public class AuthServiceImpl implements AuthService {
    private static final String SYSTEM_ADMIN_AUTHRT_CD = "SYS_ADMIN";
    private static final Pattern AUTHRT_CD = Pattern.compile("^[A-Z][A-Z0-9_]{2,29}$");

    @Resource(name = "authMapper")
    private AuthMapper authMapper;

    @Override
    public List<AuthVO> selectAuthList() { return authMapper.selectAuthList(); }

    @Override
    public AuthVO selectAuth(String authrtCd) {
        String code = normalizeCode(authrtCd);
        AuthVO auth = authMapper.selectAuth(code);
        if (auth == null) throw new IllegalArgumentException("존재하지 않는 권한입니다.");
        auth.setMenuAuthList(authMapper.selectMenuAuthList(code));
        return auth;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public AuthVO createAuth(AuthVO authVO, String actorId) {
        normalizeAndValidate(authVO, true);
        authVO.setUseYn("Y");
        authVO.setRgtrId(actorId);
        if (authMapper.countAuthCode(authVO) > 0) throw new IllegalArgumentException("이미 사용 중인 권한코드입니다.");
        if (authMapper.countAuthName(authVO) > 0) throw new IllegalArgumentException("이미 사용 중인 권한명입니다.");
        if (authMapper.insertAuth(authVO) != 1) throw new IllegalStateException("권한 등록에 실패했습니다.");
        return authVO;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateAuth(AuthVO authVO, String actorId) {
        normalizeAndValidate(authVO, false);
        AuthVO existing = authMapper.selectAuth(authVO.getAuthrtCd());
        if (existing == null) throw new IllegalArgumentException("수정할 권한이 없습니다.");
        authVO.setMdfrId(actorId);
        authVO.setUseYn("Y");
        if (authMapper.countAuthName(authVO) > 0) throw new IllegalArgumentException("이미 사용 중인 권한명입니다.");
        if (authMapper.updateAuth(authVO) != 1) throw new IllegalStateException("권한 수정에 실패했습니다.");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteAuth(String authrtCd, String actorId) {
        String code = normalizeCode(authrtCd);
        if (SYSTEM_ADMIN_AUTHRT_CD.equals(code)) throw new IllegalArgumentException("시스템 관리자 권한은 삭제할 수 없습니다.");
        if (authMapper.selectAuth(code) == null) throw new IllegalArgumentException("삭제할 권한이 없습니다.");
        if (authMapper.countAuthUsers(code) > 0) throw new IllegalStateException("해당 권한을 사용 중인 사용자가 있습니다.");
        authMapper.deleteAuthMenus(code);
        AuthVO auth = new AuthVO();
        auth.setAuthrtCd(code);
        auth.setMdfrId(actorId);
        if (authMapper.disableAuth(auth) != 1) throw new IllegalStateException("권한 삭제에 실패했습니다.");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void saveMenuPermissions(String authrtCd, List<MenuAuthVO> permissions) {
        String code = normalizeCode(authrtCd);
        if (authMapper.selectAuth(code) == null) throw new IllegalArgumentException("권한 정보가 없습니다.");
        authMapper.deleteAuthMenus(code);
        if (permissions == null) return;
        for (MenuAuthVO permission : permissions) {
            permission.setAuthrtCd(code);
            normalizePermission(permission, SYSTEM_ADMIN_AUTHRT_CD.equals(code));
            authMapper.insertMenuAuth(permission);
        }
    }

    @Override
    public Map<String, MenuAuthVO> selectPermissionMap(String authrtCd) {
        Map<String, MenuAuthVO> map = new LinkedHashMap<String, MenuAuthVO>();
        String code = normalizeCode(authrtCd);
        for (MenuAuthVO item : authMapper.selectMenuAuthList(code)) {
            map.put(item.getScreenKey(), item);
        }
        return map;
    }

    private void normalizeAndValidate(AuthVO auth, boolean create) {
        String code = normalizeCode(auth.getAuthrtCd());
        if (code == null || !AUTHRT_CD.matcher(code).matches()) {
            throw new IllegalArgumentException("권한코드는 영문 대문자로 시작하고 영문 대문자·숫자·밑줄 조합 3~30자로 입력해 주세요.");
        }
        auth.setAuthrtCd(code);
        String name = auth.getAuthrtNm() == null ? "" : auth.getAuthrtNm().trim();
        if (name.length() == 0 || name.length() > 100) throw new IllegalArgumentException("권한명은 1~100자로 입력해 주세요.");
        auth.setAuthrtNm(name);
        if (auth.getAuthrtExpln() != null && auth.getAuthrtExpln().length() > 4000) {
            throw new IllegalArgumentException("권한설명은 4,000자 이내로 입력해 주세요.");
        }
        if (!create && SYSTEM_ADMIN_AUTHRT_CD.equals(code)) auth.setUseYn("Y");
    }

    private String normalizeCode(String value) {
        if (value == null) return null;
        String code = value.trim().toUpperCase();
        return code.length() == 0 ? null : code;
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
