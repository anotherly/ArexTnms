package kr.co.TRSolution.tnms.user.vo;

public class UserVO extends UserBaseVO {
    private static final long serialVersionUID = 1L;

    private Long userSn;
    private String userSttsNm;
    private String pswdExpryYmd;
    private String lastLgnDt;
    private Integer lgnFailNocs;
    private Long authrtSn;
    private String authrtNm;
    private String loginIp;
    private String browserNm;
    private String loginSuccessYn;
    private String failRsn;

    public Long getUserSn() { return userSn; }
    public void setUserSn(Long userSn) { this.userSn = userSn; }
    public String getUserSttsNm() { return userSttsNm; }
    public void setUserSttsNm(String userSttsNm) { this.userSttsNm = userSttsNm; }
    public String getPswdExpryYmd() { return pswdExpryYmd; }
    public void setPswdExpryYmd(String pswdExpryYmd) { this.pswdExpryYmd = pswdExpryYmd; }
    public String getLastLgnDt() { return lastLgnDt; }
    public void setLastLgnDt(String lastLgnDt) { this.lastLgnDt = lastLgnDt; }
    public Integer getLgnFailNocs() { return lgnFailNocs; }
    public void setLgnFailNocs(Integer lgnFailNocs) { this.lgnFailNocs = lgnFailNocs; }
    public Long getAuthrtSn() { return authrtSn; }
    public void setAuthrtSn(Long authrtSn) { this.authrtSn = authrtSn; }
    public String getAuthrtNm() { return authrtNm; }
    public void setAuthrtNm(String authrtNm) { this.authrtNm = authrtNm; }
    public String getLoginIp() { return loginIp; }
    public void setLoginIp(String loginIp) { this.loginIp = loginIp; }
    public String getBrowserNm() { return browserNm; }
    public void setBrowserNm(String browserNm) { this.browserNm = browserNm; }
    public String getLoginSuccessYn() { return loginSuccessYn; }
    public void setLoginSuccessYn(String loginSuccessYn) { this.loginSuccessYn = loginSuccessYn; }
    public String getFailRsn() { return failRsn; }
    public void setFailRsn(String failRsn) { this.failRsn = failRsn; }
}
