package kr.co.TRSolution.tnms.user.vo;

public class UserAccountApplicationVO extends UserBaseVO {
    private static final long serialVersionUID = 1L;

    private Long aplySn;
    private String aplyNo;
    private String userSeNm;
    private String affiliation;
    private String mobileNo;
    private String dmndAuthrtNm;
    private Long authrtSn;
    private String aplyRsn;
    private String aplyDt;
    private String aplySttsNm;
    private Long aprvUserSn;
    private String aprvDt;
    private String rfslRsn;

    public Long getAplySn() { return aplySn; }
    public void setAplySn(Long aplySn) { this.aplySn = aplySn; }
    public String getAplyNo() { return aplyNo; }
    public void setAplyNo(String aplyNo) { this.aplyNo = aplyNo; }
    public String getUserSeNm() { return userSeNm; }
    public void setUserSeNm(String userSeNm) { this.userSeNm = userSeNm; }
    public String getAffiliation() { return affiliation; }
    public void setAffiliation(String affiliation) { this.affiliation = affiliation; }
    public String getMobileNo() { return mobileNo; }
    public void setMobileNo(String mobileNo) { this.mobileNo = mobileNo; }
    public String getDmndAuthrtNm() { return dmndAuthrtNm; }
    public void setDmndAuthrtNm(String dmndAuthrtNm) { this.dmndAuthrtNm = dmndAuthrtNm; }
    public Long getAuthrtSn() { return authrtSn; }
    public void setAuthrtSn(Long authrtSn) { this.authrtSn = authrtSn; }
    public String getAplyRsn() { return aplyRsn; }
    public void setAplyRsn(String aplyRsn) { this.aplyRsn = aplyRsn; }
    public String getAplyDt() { return aplyDt; }
    public void setAplyDt(String aplyDt) { this.aplyDt = aplyDt; }
    public String getAplySttsNm() { return aplySttsNm; }
    public void setAplySttsNm(String aplySttsNm) { this.aplySttsNm = aplySttsNm; }
    public Long getAprvUserSn() { return aprvUserSn; }
    public void setAprvUserSn(Long aprvUserSn) { this.aprvUserSn = aprvUserSn; }
    public String getAprvDt() { return aprvDt; }
    public void setAprvDt(String aprvDt) { this.aprvDt = aprvDt; }
    public String getRfslRsn() { return rfslRsn; }
    public void setRfslRsn(String rfslRsn) { this.rfslRsn = rfslRsn; }
}
