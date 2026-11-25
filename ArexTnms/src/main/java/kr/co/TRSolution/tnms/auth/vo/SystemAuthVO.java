package kr.co.TRSolution.tnms.auth.vo;

import java.io.Serializable;

/** 역할별 5개 연계시스템 조회 범위 (계정에는 역할코드로 적용). */
public class SystemAuthVO implements Serializable {
    private static final long serialVersionUID = 1L;
    private String linkSysCd;
    private String linkSysNm;
    private String readAuthrtYn;
    public String getLinkSysCd() { return linkSysCd; }
    public void setLinkSysCd(String value) { this.linkSysCd = value; }
    public String getLinkSysNm() { return linkSysNm; }
    public void setLinkSysNm(String value) { this.linkSysNm = value; }
    public String getReadAuthrtYn() { return readAuthrtYn; }
    public void setReadAuthrtYn(String value) { this.readAuthrtYn = value; }
}
