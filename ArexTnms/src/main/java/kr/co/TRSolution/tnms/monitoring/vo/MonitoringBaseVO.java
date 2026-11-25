package kr.co.TRSolution.tnms.monitoring.vo;

import kr.co.TRSolution.tnms.common.BaseVO;

public class MonitoringBaseVO extends BaseVO {
    private static final long serialVersionUID = 1L;
    private String linkSysCd;
    private String linkSysNm;
    private String stnCd;
    private String stnNm;
    private String sttsCd;
    private String sttsNm;

    public String getLinkSysCd() { return linkSysCd; }
    public void setLinkSysCd(String linkSysCd) { this.linkSysCd = linkSysCd; }
    public String getLinkSysNm() { return linkSysNm; }
    public void setLinkSysNm(String linkSysNm) { this.linkSysNm = linkSysNm; }
    public String getStnCd() { return stnCd; }
    public void setStnCd(String stnCd) { this.stnCd = stnCd; }
    public String getStnNm() { return stnNm; }
    public void setStnNm(String stnNm) { this.stnNm = stnNm; }
    public String getSttsCd() { return sttsCd; }
    public void setSttsCd(String sttsCd) { this.sttsCd = sttsCd; }
    public String getSttsNm() { return sttsNm; }
    public void setSttsNm(String sttsNm) { this.sttsNm = sttsNm; }
}
