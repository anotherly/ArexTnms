package kr.co.TRSolution.tnms.user.service.impl;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.regex.Pattern;
import java.util.UUID;

import javax.annotation.Resource;

import org.mindrot.jbcrypt.BCrypt;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.user.mapper.UserAccountApplicationMapper;
import kr.co.TRSolution.tnms.user.mapper.UserMapper;
import kr.co.TRSolution.tnms.user.service.UserAccountApplicationService;
import kr.co.TRSolution.tnms.user.vo.UserAccountApplicationVO;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Service("userAccountApplicationService")
public class UserAccountApplicationServiceImpl implements UserAccountApplicationService {
    private static final Pattern USER_ID = Pattern.compile("^(?=.*[A-Za-z])(?=.*\\d)[A-Za-z\\d]{4,20}$");
    private static final Pattern PASSWORD = Pattern.compile("^(?=.*[A-Za-z])(?=.*\\d)(?=.*[^A-Za-z0-9]).{8,30}$");
    private static final Pattern MOBILE = Pattern.compile("^[0-9]{10,11}$");
    private static final Pattern TELEPHONE = Pattern.compile("^[0-9]{9,11}$");
    private static final Pattern EMAIL = Pattern.compile("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$");

    @Resource(name = "userAccountApplicationMapper")
    private UserAccountApplicationMapper applicationMapper;

    @Resource(name = "userMapper")
    private UserMapper userMapper;

    @Override
    @Transactional(rollbackFor = Exception.class)
    public String submit(UserAccountApplicationVO application) {
        normalize(application);
        validate(application);
        if (applicationMapper.countUnavailableUserId(application.getUserId()) > 0) {
            throw new IllegalArgumentException("이미 사용 중이거나 승인 대기 중인 사용자 아이디입니다.");
        }

        application.setAplyNo(createApplicationNumber());
        application.setUserEnpswd(BCrypt.hashpw(application.getPassword(), BCrypt.gensalt(10)));
        application.setDmndAuthrtNm("조회 사용자");
        application.setAplyRsn("로그인 화면 계정 신청");
        application.setAplySttsNm("승인대기");
        if ("내부".equals(application.getUserSeNm())) {
            application.setOgdpBzentyNm("공항철도");
            application.setDeptNm(application.getAffiliation());
        } else {
            application.setOgdpBzentyNm(application.getAffiliation());
            application.setDeptNm(null);
        }

        if (applicationMapper.insertAccountApplication(application) != 1) {
            throw new IllegalStateException("계정 신청 저장에 실패했습니다.");
        }
        application.setPassword(null);
        application.setPasswordConfirm(null);
        application.setUserEnpswd(null);
        return application.getAplyNo();
    }

    @Override
    public List<UserAccountApplicationVO> selectApplicationList(UserAccountApplicationVO searchVO) {
        if (searchVO == null) searchVO = new UserAccountApplicationVO();
        searchVO.setSearchKeyword(trim(searchVO.getSearchKeyword()));
        searchVO.setAplySttsNm(trim(searchVO.getAplySttsNm()));
        List<UserAccountApplicationVO> list = applicationMapper.selectApplicationList(searchVO);
        clearPasswordHashes(list);
        return list;
    }

    @Override
    public UserAccountApplicationVO selectApplication(Long aplySn) {
        if (aplySn == null) throw new IllegalArgumentException("계정 신청 정보가 없습니다.");
        UserAccountApplicationVO application = applicationMapper.selectApplication(aplySn);
        if (application == null) throw new IllegalArgumentException("존재하지 않는 계정 신청입니다.");
        application.setUserEnpswd(null);
        return application;
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void approve(Long aplySn, UserVO actor) {
        requireActor(actor);
        UserAccountApplicationVO application = getPendingApplicationForUpdate(aplySn);
        if (application.getUserEnpswd() == null || application.getUserEnpswd().trim().length() == 0) {
            throw new IllegalStateException("신청 계정의 비밀번호 정보가 없어 승인할 수 없습니다. 계정 신청 DB 마이그레이션을 확인해 주세요.");
        }
        if (userMapper.countByUserId(application.getUserId()) > 0) {
            throw new IllegalArgumentException("동일한 사용자 아이디의 계정이 이미 존재합니다.");
        }

        Long authrtSn = applicationMapper.selectAuthrtSnByName(application.getDmndAuthrtNm());
        if (authrtSn == null) {
            throw new IllegalStateException("신청된 권한 정보를 찾을 수 없습니다: " + application.getDmndAuthrtNm());
        }

        UserVO user = new UserVO();
        user.setUserId(application.getUserId());
        user.setUserNm(application.getUserNm());
        user.setUserEnpswd(application.getUserEnpswd());
        user.setOgdpBzentyNm(application.getOgdpBzentyNm());
        user.setDeptNm(application.getDeptNm());
        user.setTelno(firstNonBlank(application.getMobileNo(), application.getTelno()));
        user.setEmlAddr(application.getEmlAddr());
        user.setUserSttsNm("정상");
        user.setUseYn("Y");
        user.setAuthrtSn(authrtSn);
        user.setRgtrSn(actor.getUserSn());

        if (userMapper.insertUser(user) != 1 || userMapper.insertUserAuth(user) != 1) {
            throw new IllegalStateException("승인 계정 생성에 실패했습니다.");
        }

        application.setAprvUserSn(actor.getUserSn());
        if (applicationMapper.approveApplication(application) != 1) {
            throw new IllegalStateException("계정 신청 승인 상태 변경에 실패했습니다.");
        }
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void reject(Long aplySn, String reason, UserVO actor) {
        requireActor(actor);
        UserAccountApplicationVO application = getPendingApplicationForUpdate(aplySn);
        String normalizedReason = trim(reason);
        if (normalizedReason == null) throw new IllegalArgumentException("반려 사유를 입력해 주세요.");
        if (normalizedReason.length() > 4000) throw new IllegalArgumentException("반려 사유는 4000자 이내로 입력해 주세요.");
        application.setRfslRsn(normalizedReason);
        if (applicationMapper.rejectApplication(application) != 1) {
            throw new IllegalStateException("계정 신청 반려 상태 변경에 실패했습니다.");
        }
    }

    private UserAccountApplicationVO getPendingApplicationForUpdate(Long aplySn) {
        if (aplySn == null) throw new IllegalArgumentException("처리할 계정 신청을 선택해 주세요.");
        UserAccountApplicationVO application = applicationMapper.selectApplicationForUpdate(aplySn);
        if (application == null) throw new IllegalArgumentException("존재하지 않는 계정 신청입니다.");
        if (!"승인대기".equals(application.getAplySttsNm())) {
            throw new IllegalArgumentException("이미 처리된 계정 신청입니다.");
        }
        return application;
    }

    private void normalize(UserAccountApplicationVO application) {
        application.setUserId(trim(application.getUserId()));
        application.setUserNm(trim(application.getUserNm()));
        application.setUserSeNm(trim(application.getUserSeNm()));
        application.setAffiliation(trim(application.getAffiliation()));
        application.setMobileNo(digits(application.getMobileNo()));
        application.setTelno(digits(application.getTelno()));
        application.setEmlAddr(trim(application.getEmlAddr()));
    }

    private void validate(UserAccountApplicationVO application) {
        if (application.getUserId() == null || !USER_ID.matcher(application.getUserId()).matches()) {
            throw new IllegalArgumentException("아이디는 영문과 숫자를 조합해 4~20자로 입력해 주세요.");
        }
        if (application.getPassword() == null || !PASSWORD.matcher(application.getPassword()).matches()) {
            throw new IllegalArgumentException("비밀번호는 영문·숫자·특수문자를 포함해 8~30자로 입력해 주세요.");
        }
        if (application.getPassword().toLowerCase().contains(application.getUserId().toLowerCase())) {
            throw new IllegalArgumentException("비밀번호에 사용자 아이디를 포함할 수 없습니다.");
        }
        if (!application.getPassword().equals(application.getPasswordConfirm())) {
            throw new IllegalArgumentException("비밀번호 확인이 일치하지 않습니다.");
        }
        if (application.getUserNm() == null || application.getUserNm().length() > 100) {
            throw new IllegalArgumentException("이름을 입력해 주세요.");
        }
        if (!"내부".equals(application.getUserSeNm()) && !"외부".equals(application.getUserSeNm())) {
            throw new IllegalArgumentException("소속 구분을 선택해 주세요.");
        }
        if (application.getAffiliation() == null || application.getAffiliation().length() > 100) {
            throw new IllegalArgumentException("소속을 100자 이내로 입력해 주세요.");
        }
        if (application.getMobileNo() == null || !MOBILE.matcher(application.getMobileNo()).matches()) {
            throw new IllegalArgumentException("핸드폰번호는 하이픈 없이 숫자 10~11자로 입력해 주세요.");
        }
        if (application.getTelno() != null && !TELEPHONE.matcher(application.getTelno()).matches()) {
            throw new IllegalArgumentException("전화번호는 하이픈 없이 숫자 9~11자로 입력해 주세요.");
        }
        if (application.getEmlAddr() == null || application.getEmlAddr().length() > 320 ||
                !EMAIL.matcher(application.getEmlAddr()).matches()) {
            throw new IllegalArgumentException("이메일 주소 형식이 올바르지 않습니다.");
        }
    }

    private void clearPasswordHashes(List<UserAccountApplicationVO> list) {
        if (list == null) return;
        for (UserAccountApplicationVO application : list) application.setUserEnpswd(null);
    }

    private String createApplicationNumber() {
        String date = new SimpleDateFormat("yyyyMMdd").format(new Date());
        return "APLY-" + date + "-" + UUID.randomUUID().toString().substring(0, 8).toUpperCase();
    }

    private String trim(String value) {
        return value == null || value.trim().length() == 0 ? null : value.trim();
    }

    private String digits(String value) {
        String normalized = trim(value);
        return normalized == null ? null : normalized.replaceAll("[^0-9]", "");
    }

    private String firstNonBlank(String first, String second) {
        String normalizedFirst = trim(first);
        return normalizedFirst != null ? normalizedFirst : trim(second);
    }

    private void requireActor(UserVO actor) {
        if (actor == null || actor.getUserSn() == null) {
            throw new IllegalStateException("로그인 사용자 정보를 확인할 수 없습니다.");
        }
    }
}
