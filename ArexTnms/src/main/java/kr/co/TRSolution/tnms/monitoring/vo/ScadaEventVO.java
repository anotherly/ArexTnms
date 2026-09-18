package kr.co.TRSolution.tnms.monitoring.vo;

import java.io.Serializable;

public class ScadaEventVO implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long enexEvntSn;
    private Long eqpmntSn;
    private String eqpmntNm;
    private String stnNm;
    private String evntCd;
    private String evntNm;
    private String enexDt;
    private String enexRsltCd;
    private String aprvYn;
    private String evntCn;

    public Long getEnexEvntSn() { return enexEvntSn; }
    public void setEnexEvntSn(Long enexEvntSn) { this.enexEvntSn = enexEvntSn; }
    public Long getEqpmntSn() { return eqpmntSn; }
    public void setEqpmntSn(Long eqpmntSn) { this.eqpmntSn = eqpmntSn; }
    public String getEqpmntNm() { return eqpmntNm; }
    public void setEqpmntNm(String eqpmntNm) { this.eqpmntNm = eqpmntNm; }
    public String getStnNm() { return stnNm; }
    public void setStnNm(String stnNm) { this.stnNm = stnNm; }
    public String getEvntCd() { return evntCd; }
    public void setEvntCd(String evntCd) { this.evntCd = evntCd; }
    public String getEvntNm() { return evntNm; }
    public void setEvntNm(String evntNm) { this.evntNm = evntNm; }
    public String getEnexDt() { return enexDt; }
    public void setEnexDt(String enexDt) { this.enexDt = enexDt; }
    public String getEnexRsltCd() { return enexRsltCd; }
    public void setEnexRsltCd(String enexRsltCd) { this.enexRsltCd = enexRsltCd; }
    public String getAprvYn() { return aprvYn; }
    public void setAprvYn(String aprvYn) { this.aprvYn = aprvYn; }
    public String getEvntCn() { return evntCn; }
    public void setEvntCn(String evntCn) { this.evntCn = evntCn; }
}
