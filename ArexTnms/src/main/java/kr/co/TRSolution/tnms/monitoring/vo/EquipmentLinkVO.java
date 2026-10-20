package kr.co.TRSolution.tnms.monitoring.vo;

import java.io.Serializable;

public class EquipmentLinkVO implements Serializable {
    private static final long serialVersionUID = 1L;
    private Long fromEqpmntSn;
    private String fromEqpmntNm;
    private Long toEqpmntSn;
    private String toEqpmntNm;
    private String linkTypeCd;
    private String linkNm;

    public Long getFromEqpmntSn() { return fromEqpmntSn; }
    public void setFromEqpmntSn(Long fromEqpmntSn) { this.fromEqpmntSn = fromEqpmntSn; }
    public String getFromEqpmntNm() { return fromEqpmntNm; }
    public void setFromEqpmntNm(String fromEqpmntNm) { this.fromEqpmntNm = fromEqpmntNm; }
    public Long getToEqpmntSn() { return toEqpmntSn; }
    public void setToEqpmntSn(Long toEqpmntSn) { this.toEqpmntSn = toEqpmntSn; }
    public String getToEqpmntNm() { return toEqpmntNm; }
    public void setToEqpmntNm(String toEqpmntNm) { this.toEqpmntNm = toEqpmntNm; }
    public String getLinkTypeCd() { return linkTypeCd; }
    public void setLinkTypeCd(String linkTypeCd) { this.linkTypeCd = linkTypeCd; }
    public String getLinkNm() { return linkNm; }
    public void setLinkNm(String linkNm) { this.linkNm = linkNm; }
}
