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
    private static final Pattern USER_ID = Pattern.compile("^[a-z0-9]{6,20}$");
    private static final Pattern PASSWORD = Pattern.compile("^(?=.*[A-Za-z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,20}$");
    private static final Pattern PHONE = Pattern.compile("^[0-9]{9,11}$");
    private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");
    private static final Set<String> USER_STATUSES = new HashSet<String>(
            Arrays.asList("정상", "잠금", "중지"));

    @Resource(name = "userMapper")
    private UserMapper userMapper;

    @Override
    public List<UserVO> selectUserList(UserVO searchVO) {
        List<UserVO> users = userMapper.selectUserList(searchVO);
        for (UserVO user : users) user.setUserEnpswd(null);
        return users;
    }

    @Override
    public UserVO selectUser(Long userSn) {
        if (userSn == null) throw new IllegalArgumentException("사용자 정보가 없습니다.");
        UserVO user = userMapper.selectUser(userSn);
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
        userVO.setUserSttsNm("정상");
        userVO.setUseYn("Y");
        userVO.setRgtrSn(actor.getUserSn());
        if (userMapper.insertUser(userVO) != 1 || userMapper.insertUserAuth(userVO) != 1) {
            throw new IllegalStateException("사용자 등록에 실패했습니다.");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void updateUser(UserVO userVO, UserVO actor) {
        requireActor(actor);
        normalize(userVO);
        validateUser(userVO, false);
        UserVO existing = userVO.getUserSn() == null ? null : userMapper.selectUser(userVO.getUserSn());
        if (existing == null) {
            throw new IllegalArgumentException("수정할 사용자가 없습니다.");
        }
        if (Long.valueOf(1L).equals(existing.getAuthrtSn()) && !Long.valueOf(1L).equals(userVO.getAuthrtSn())) {
            throw new IllegalArgumentException("시스템 관리자 계정의 권한은 변경할 수 없습니다.");
        }
        if (Long.valueOf(1L).equals(existing.getAuthrtSn())) {
            userVO.setUseYn("Y");
            userVO.setUserSttsNm("정상");
        }
        userVO.setMdfrSn(actor.getUserSn());
        if (userMapper.updateUser(userVO) != 1) throw new IllegalStateException("사용자 수정에 실패했습니다.");
        if (userVO.getPassword() != null && userVO.getPassword().length() > 0) {
            validatePassword(userVO);
            userVO.setUserEnpswd(BCrypt.hashpw(userVO.getPassword(), BCrypt.gensalt(10)));
            if (userMapper.updatePassword(userVO) != 1) {
                throw new IllegalStateException("비밀번호 변경에 실패했습니다.");
            }
        }
        userMapper.deleteUserAuth(userVO.getUserSn());
        if (userMapper.insertUserAuth(userVO) != 1) throw new IllegalStateException("사용자 권한 변경에 실패했습니다.");
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void deleteUser(Long userSn, UserVO actor) {
        requireActor(actor);
        if (userSn == null) throw new IllegalArgumentException("삭제할 사용자를 선택해 주세요.");
        if (userSn.equals(actor.getUserSn())) throw new IllegalArgumentException("현재 로그인한 계정은 삭제할 수 없습니다.");
        UserVO target = userMapper.selectUser(userSn);
        if (target == null) throw new IllegalArgumentException("삭제할 사용자가 없습니다.");
        if (Long.valueOf(1L).equals(target.getAuthrtSn())) {
            throw new IllegalArgumentException("시스템 관리자 계정은 삭제할 수 없습니다.");
        }
        UserVO update = new UserVO();
        update.setUserSn(userSn);
        update.setMdfrSn(actor.getUserSn());
        userMapper.deleteUserAuth(userSn);
        if (userMapper.softDeleteUser(update) != 1) throw new IllegalStateException("사용자 삭제에 실패했습니다.");
    }

    @Override
    public void unlockUser(Long userSn, UserVO actor) {
        requireActor(actor);
        if (userSn == null) throw new IllegalArgumentException("잠금 해제할 사용자를 선택해 주세요.");
        UserVO update = new UserVO();
        update.setUserSn(userSn);
        update.setMdfrSn(actor.getUserSn());
        if (userMapper.unlockUser(update) != 1) throw new IllegalArgumentException("잠금 해제할 사용자가 없습니다.");
    }

    @Override
    public void recordLoginFailure(UserVO userVO, String ip, String browser, String reason) {
        if (userVO != null && "Y".equals(userVO.getUseYn()) &&
                "정상".equals(userVO.getUserSttsNm())) {
            userMapper.increaseLoginFailure(userVO.getUserSn());
        }
        UserVO log = loginLog(userVO, ip, browser, "N", reason);
        userMapper.insertLoginLog(log);
    }

    @Override
    public void recordLoginSuccess(UserVO userVO, String ip, String browser) {
        userMapper.resetLoginFailure(userVO.getUserSn());
        userMapper.insertLoginLog(loginLog(userVO, ip, browser, "Y", null));
    }

    @Override
    public void recordLogout(UserVO userVO) {
        if (userVO != null && userVO.getUserSn() != null) userMapper.updateLogoutLog(userVO.getUserSn());
    }

    private UserVO loginLog(UserVO user, String ip, String browser, String successYn, String reason) {
        UserVO log = new UserVO();
        if (user != null) {
            log.setUserSn(user.getUserSn());
            log.setUserId(user.getUserId());
        }
        log.setLoginIp(ip);
        log.setBrowserNm(browser == null ? null : browser.substring(0, Math.min(browser.length(), 300)));
        log.setLoginSuccessYn(successYn);
        log.setFailRsn(reason);
        return log;
    }

    private void normalize(UserVO user) {
        user.setUserId(trim(user.getUserId()));
        user.setUserNm(trim(user.getUserNm()));
        user.setOgdpBzentyNm(trim(user.getOgdpBzentyNm()));
        user.setDeptNm(trim(user.getDeptNm()));
        user.setTelno(trim(user.getTelno()));
        user.setEmlAddr(trim(user.getEmlAddr()));
        if (user.getUseYn() == null) user.setUseYn("Y");
        if (user.getUserSttsNm() == null) user.setUserSttsNm("정상");
    }

    private void validateUser(UserVO user, boolean create) {
        if (create && (user.getUserId() == null || !USER_ID.matcher(user.getUserId()).matches())) {
            throw new IllegalArgumentException("아이디는 영문 소문자와 숫자 조합 6~20자로 입력해 주세요.");
        }
        if (user.getUserNm() == null || user.getUserNm().length() == 0 || user.getUserNm().length() > 100) {
            throw new IllegalArgumentException("사용자명은 1~100자로 입력해 주세요.");
        }
        if (user.getAuthrtSn() == null) throw new IllegalArgumentException("권한을 선택해 주세요.");
        if (user.getTelno() != null && user.getTelno().length() > 0 && !PHONE.matcher(user.getTelno()).matches()) {
            throw new IllegalArgumentException("전화번호는 하이픈 없이 숫자 9~11자로 입력해 주세요.");
        }
        if (user.getEmlAddr() != null && user.getEmlAddr().length() > 0 &&
                (user.getEmlAddr().length() > 320 || !EMAIL.matcher(user.getEmlAddr()).matches())) {
            throw new IllegalArgumentException("이메일 주소 형식이 올바르지 않습니다.");
        }
        if (!USER_STATUSES.contains(user.getUserSttsNm())) {
            throw new IllegalArgumentException("계정 상태가 올바르지 않습니다.");
        }
        if (create) validatePassword(user);
        if (!"Y".equals(user.getUseYn()) && !"N".equals(user.getUseYn())) user.setUseYn("Y");
    }

    private void validatePassword(UserVO user) {
        if (user.getPassword() == null || !PASSWORD.matcher(user.getPassword()).matches()) {
            throw new IllegalArgumentException("비밀번호는 영문·숫자·특수문자를 포함한 8~20자로 입력해 주세요.");
        }
        if (!user.getPassword().equals(user.getPasswordConfirm())) {
            throw new IllegalArgumentException("비밀번호 확인이 일치하지 않습니다.");
        }
    }

    private String trim(String value) {
        return value == null || value.trim().length() == 0 ? null : value.trim();
    }

    private void requireActor(UserVO actor) {
        if (actor == null || actor.getUserSn() == null) {
            throw new IllegalStateException("로그인 사용자 정보를 확인할 수 없습니다.");
        }
    }
}
