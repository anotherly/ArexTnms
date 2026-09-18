package kr.co.TRSolution.tnms.user.vo;

import kr.co.TRSolution.tnms.common.BaseVO;

/**
 * 사용자/계정신청에서 공통으로 사용하는 기본 사용자 정보 VO.
 */
public class UserBaseVO extends BaseVO {
    private static final long serialVersionUID = 1L;

    private String userId;
    private String userNm;
    private String userEnpswd;
    private String password;
    private String passwordConfirm;
    private String userSeCd;
    private String ogdpBzentyNm;
    private String deptNm;
    private String mobileNo;
    private String telno;
    private String emlAddr;

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getUserNm() { return userNm; }
    public void setUserNm(String userNm) { this.userNm = userNm; }
    public String getUserEnpswd() { return userEnpswd; }
    public void setUserEnpswd(String userEnpswd) { this.userEnpswd = userEnpswd; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getPasswordConfirm() { return passwordConfirm; }
    public void setPasswordConfirm(String passwordConfirm) { this.passwordConfirm = passwordConfirm; }
    public String getUserSeCd() { return userSeCd; }
    public void setUserSeCd(String userSeCd) { this.userSeCd = userSeCd; }
    public String getOgdpBzentyNm() { return ogdpBzentyNm; }
    public void setOgdpBzentyNm(String ogdpBzentyNm) { this.ogdpBzentyNm = ogdpBzentyNm; }
    public String getDeptNm() { return deptNm; }
    public void setDeptNm(String deptNm) { this.deptNm = deptNm; }
    public String getMobileNo() { return mobileNo; }
    public void setMobileNo(String mobileNo) { this.mobileNo = mobileNo; }
    public String getTelno() { return telno; }
    public void setTelno(String telno) { this.telno = telno; }
    public String getEmlAddr() { return emlAddr; }
    public void setEmlAddr(String emlAddr) { this.emlAddr = emlAddr; }
}
