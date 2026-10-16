package kr.co.TRSolution.tnms.user.service.impl;

import java.util.Arrays;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.regex.Pattern;

import javax.annotation.Resource;

import org.mindrot.jbcrypt.BCrypt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.user.mapper.UserMapper;
import kr.co.TRSolution.tnms.user.service.UserService;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Service("userService")
public class UserServiceImpl implements UserService {
    private static final String SYSTEM_ADMIN_AUTHRT_CD = "SYS_ADMIN";
    private static final Pattern USER_ID = Pattern.compile("^[a-z0-9]{6,20}$");
    private static final Pattern PASSWORD = Pattern.compile("^(?=.*[A-Za-z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,20}$");
    private static final Pattern PHONE = Pattern.compile("^[0-9]{9,11}$");
    private static final Pattern MOBILE = Pattern.compile("^[0-9]{10,11}$");
    private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");
    private static final Set<String> USER_STATUSES = new HashSet<String>(Arrays.asList("NORMAL", "LOCKED", "SUSPENDED"));
    private static final Set<String> USER_TYPES = new HashSet<String>(Arrays.asList("INTERNAL", "EXTERNAL"));

    @Resource(name = "userMapper")
    private UserMapper userMapper;

    @Override
    public List<UserVO> selectUserList(UserVO searchVO) {
        List<UserVO> users = userMapper.selectUserList(searchVO);
        for (UserVO user : users) user.setUserEnpswd(null);
        return users;
    }

    @Override
    public UserVO selectUser(String userId) {
        String normalized = trim(userId);
        if (normalized == null) throw new IllegalArgumentException("사용자 정보가 없습니다.");
        UserVO user = userMapper.selectUser(normalized);
        if (user == null) throw new IllegalArgumentException("존재하지 않는 사용자입니다.");
        user.setUserEnpswd(null);
        return user;
    }

    @Override
    public UserVO selectLoginUser(String userId) {
        if (userId == null || userId.trim().length() == 0) return null;
        return userMapper.selectLoginUser(userId.trim());
    }

    @Override
    public boolean isUserIdAvailable(String userId) {
        String normalized = trim(userId);
        if (normalized == null || !USER_ID.matcher(normalized).matches()) {
            throw new IllegalArgumentException("아이디는 영문 소문자와 숫자 조합 6~20자로 입력해 주세요.");
        }
        return userMapper.countByUserId(normalized) == 0;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void createUser(UserVO userVO, UserVO actor) {
        requireActor(actor);
        normalize(userVO);
        validateUser(userVO, true);
        if (userMapper.countByUserId(userVO.getUserId()) > 0) {
            throw new IllegalArgumentException("이미 사용 중인 사용자 아이디입니다.");
        }
        userVO.setUserEnpswd(BCrypt.hashpw(userVO.getPassword(), BCrypt.gensalt(10)));
        userVO.setUserSttsCd("NORMAL");
        userVO.setUseYn("Y");
        userVO.setRgtrId(actor.getUserId());
        if (userMapper.insertUser(userVO) != 1) throw new IllegalStateException("사용자 등록에 실패했습니다.");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateUser(UserVO userVO, UserVO actor) {
        requireActor(actor);
        normalize(userVO);
        validateUser(userVO, false);
        UserVO existing = userVO.getUserId() == null ? null : userMapper.selectUser(userVO.getUserId());
        if (existing == null) throw new IllegalArgumentException("수정할 사용자가 없습니다.");
        if (SYSTEM_ADMIN_AUTHRT_CD.equals(existing.getAuthrtCd()) && !SYSTEM_ADMIN_AUTHRT_CD.equals(userVO.getAuthrtCd())) {
            throw new IllegalArgumentException("시스템 관리자 계정의 권한은 변경할 수 없습니다.");
        }
        if (SYSTEM_ADMIN_AUTHRT_CD.equals(existing.getAuthrtCd())) {
            userVO.setUseYn("Y");
            userVO.setUserSttsCd("NORMAL");
        }
        userVO.setMdfrId(actor.getUserId());
        if (userMapper.updateUser(userVO) != 1) throw new IllegalStateException("사용자 수정에 실패했습니다.");
        if (userVO.getPassword() != null && userVO.getPassword().length() > 0) {
            validatePassword(userVO);
            userVO.setUserEnpswd(BCrypt.hashpw(userVO.getPassword(), BCrypt.gensalt(10)));
            if (userMapper.updatePassword(userVO) != 1) throw new IllegalStateException("비밀번호 변경에 실패했습니다.");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteUser(String userId, UserVO actor) {
        requireActor(actor);
        String normalized = trim(userId);
        if (normalized == null) throw new IllegalArgumentException("삭제할 사용자를 선택해 주세요.");
        if (normalized.equals(actor.getUserId())) throw new IllegalArgumentException("현재 로그인한 계정은 삭제할 수 없습니다.");
        UserVO target = userMapper.selectUser(normalized);
        if (target == null) throw new IllegalArgumentException("삭제할 사용자가 없습니다.");
        if (SYSTEM_ADMIN_AUTHRT_CD.equals(target.getAuthrtCd())) throw new IllegalArgumentException("시스템 관리자 계정은 삭제할 수 없습니다.");
        UserVO update = new UserVO();
        update.setUserId(normalized);
        update.setMdfrId(actor.getUserId());
        if (userMapper.softDeleteUser(update) != 1) throw new IllegalStateException("사용자 삭제에 실패했습니다.");
    }

    @Override
    public void unlockUser(String userId, UserVO actor) {
        requireActor(actor);
        String normalized = trim(userId);
        if (normalized == null) throw new IllegalArgumentException("잠금 해제할 사용자를 선택해 주세요.");
        UserVO update = new UserVO();
        update.setUserId(normalized);
        update.setMdfrId(actor.getUserId());
        if (userMapper.unlockUser(update) != 1) throw new IllegalArgumentException("잠금 해제할 사용자가 없습니다.");
    }

    @Override
    public void recordLoginFailure(UserVO userVO, String ip, String browser, String reason) {
        if (userVO != null && "Y".equals(userVO.getUseYn()) && "NORMAL".equals(userVO.getUserSttsCd())) {
            userMapper.increaseLoginFailure(userVO.getUserId());
        }
        userMapper.insertLoginLog(loginLog(userVO, ip, browser, "N", reason));
    }

    @Override
    public void recordLoginSuccess(UserVO userVO, String ip, String browser) {
        userMapper.resetLoginFailure(userVO.getUserId());
        userMapper.insertLoginLog(loginLog(userVO, ip, browser, "Y", null));
    }

    @Override
    public void recordLogout(UserVO userVO) {
        if (userVO != null && userVO.getUserId() != null) userMapper.updateLogoutLog(userVO.getUserId());
    }

    private UserVO loginLog(UserVO user, String ip, String browser, String successYn, String reason) {
        UserVO log = new UserVO();
        if (user != null) log.setUserId(user.getUserId());
        log.setLoginIp(ip);
        log.setBrowserNm(browser == null ? null : browser.substring(0, Math.min(browser.length(), 300)));
        log.setLoginSuccessYn(successYn);
        log.setFailRsn(reason);
        return log;
    }

    private void normalize(UserVO user) {
        user.setUserId(trim(user.getUserId()));
        user.setUserNm(trim(user.getUserNm()));
        user.setUserSeCd(upper(trim(user.getUserSeCd())));
        user.setOgdpBzentyNm(trim(user.getOgdpBzentyNm()));
        user.setDeptNm(trim(user.getDeptNm()));
        user.setMobileNo(digits(user.getMobileNo()));
        user.setTelno(digits(user.getTelno()));
        user.setEmlAddr(trim(user.getEmlAddr()));
        user.setAuthrtCd(upper(trim(user.getAuthrtCd())));
        user.setUserSttsCd(upper(trim(user.getUserSttsCd())));
        if (user.getUseYn() == null) user.setUseYn("Y");
        if (user.getUserSttsCd() == null) user.setUserSttsCd("NORMAL");
        if (user.getUserSeCd() == null) user.setUserSeCd("INTERNAL");
    }

    private void validateUser(UserVO user, boolean create) {
        if (create && (user.getUserId() == null || !USER_ID.matcher(user.getUserId()).matches())) {
            throw new IllegalArgumentException("아이디는 영문 소문자와 숫자 조합 6~20자로 입력해 주세요.");
        }
        if (user.getUserNm() == null || user.getUserNm().length() == 0 || user.getUserNm().length() > 100) {
            throw new IllegalArgumentException("사용자명은 1~100자로 입력해 주세요.");
        }
        if (user.getAuthrtCd() == null) throw new IllegalArgumentException("권한을 선택해 주세요.");
        if (!USER_TYPES.contains(user.getUserSeCd())) throw new IllegalArgumentException("사용자 구분이 올바르지 않습니다.");
        if (user.getMobileNo() != null && !MOBILE.matcher(user.getMobileNo()).matches()) {
            throw new IllegalArgumentException("핸드폰번호는 하이픈 없이 숫자 10~11자로 입력해 주세요.");
        }
        if (user.getTelno() != null && !PHONE.matcher(user.getTelno()).matches()) {
            throw new IllegalArgumentException("전화번호는 하이픈 없이 숫자 9~11자로 입력해 주세요.");
        }
        if (user.getEmlAddr() != null && (user.getEmlAddr().length() > 320 || !EMAIL.matcher(user.getEmlAddr()).matches())) {
            throw new IllegalArgumentException("이메일 주소 형식이 올바르지 않습니다.");
        }
        if (!USER_STATUSES.contains(user.getUserSttsCd())) throw new IllegalArgumentException("계정 상태가 올바르지 않습니다.");
        if (create) validatePassword(user);
        if (!"Y".equals(user.getUseYn()) && !"N".equals(user.getUseYn())) user.setUseYn("Y");
    }

    private void validatePassword(UserVO user) {
        if (user.getPassword() == null || !PASSWORD.matcher(user.getPassword()).matches()) {
            throw new IllegalArgumentException("비밀번호는 영문·숫자·특수문자를 포함한 8~20자로 입력해 주세요.");
        }
        if (!user.getPassword().equals(user.getPasswordConfirm())) throw new IllegalArgumentException("비밀번호 확인이 일치하지 않습니다.");
    }

    private String trim(String value) { return value == null || value.trim().length() == 0 ? null : value.trim(); }
    private String upper(String value) { return value == null ? null : value.toUpperCase(); }
    private String digits(String value) {
        String normalized = trim(value);
        return normalized == null ? null : normalized.replaceAll("[^0-9]", "");
    }
    private void requireActor(UserVO actor) {
        if (actor == null || actor.getUserId() == null || actor.getUserId().trim().length() == 0) {
            throw new IllegalStateException("로그인 사용자 정보를 확인할 수 없습니다.");
        }
    }
}
