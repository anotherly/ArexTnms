package kr.co.TRSolution.tnms.user.vo;

public class UserAccountApplicationVO extends UserBaseVO {
    private static final long serialVersionUID = 1L;

    private String aplyNo;
    private String affiliation;
    private String dmndAuthrtCd;
    private String dmndAuthrtNm;
    private String aplyRsn;
    private String aplyDt;
    private String aplySttsCd;
    private String aprvUserId;
    private String aprvDt;
    private String rfslRsn;

    public String getAplyNo() { return aplyNo; }
    public void setAplyNo(String aplyNo) { this.aplyNo = aplyNo; }
    public String getAffiliation() { return affiliation; }
    public void setAffiliation(String affiliation) { this.affiliation = affiliation; }
    public String getDmndAuthrtCd() { return dmndAuthrtCd; }
    public void setDmndAuthrtCd(String dmndAuthrtCd) { this.dmndAuthrtCd = dmndAuthrtCd; }
    public String getDmndAuthrtNm() { return dmndAuthrtNm; }
    public void setDmndAuthrtNm(String dmndAuthrtNm) { this.dmndAuthrtNm = dmndAuthrtNm; }
    public String getAplyRsn() { return aplyRsn; }
    public void setAplyRsn(String aplyRsn) { this.aplyRsn = aplyRsn; }
    public String getAplyDt() { return aplyDt; }
    public void setAplyDt(String aplyDt) { this.aplyDt = aplyDt; }
    public String getAplySttsCd() { return aplySttsCd; }
    public void setAplySttsCd(String aplySttsCd) { this.aplySttsCd = aplySttsCd; }
    public String getAprvUserId() { return aprvUserId; }
    public void setAprvUserId(String aprvUserId) { this.aprvUserId = aprvUserId; }
    public String getAprvDt() { return aprvDt; }
    public void setAprvDt(String aprvDt) { this.aprvDt = aprvDt; }
    public String getRfslRsn() { return rfslRsn; }
    public void setRfslRsn(String rfslRsn) { this.rfslRsn = rfslRsn; }
}
