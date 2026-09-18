package kr.co.TRSolution.tnms.report.vo;

import kr.co.TRSolution.tnms.common.BaseVO;

public class ReportVO extends BaseVO {
    private static final long serialVersionUID = 1L;
    private String startDate;
    private String endDate;
    private String linkSysCd;
    private String linkSysNm;
    private Integer totalNocs;
    private Integer criticalNocs;
    private Integer serviceNocs;
    private Integer completeNocs;
    private Long avgRecoverySec;
    private Double completeRate;
    public String getStartDate() { return startDate; }
    public void setStartDate(String v) { this.startDate = v; }
    public String getEndDate() { return endDate; }
    public void setEndDate(String v) { this.endDate = v; }
    public String getLinkSysCd() { return linkSysCd; }
    public void setLinkSysCd(String v) { this.linkSysCd = v; }
    public String getLinkSysNm() { return linkSysNm; }
    public void setLinkSysNm(String v) { this.linkSysNm = v; }
    public Integer getTotalNocs() { return totalNocs; }
    public void setTotalNocs(Integer v) { this.totalNocs = v; }
    public Integer getCriticalNocs() { return criticalNocs; }
    public void setCriticalNocs(Integer v) { this.criticalNocs = v; }
    public Integer getServiceNocs() { return serviceNocs; }
    public void setServiceNocs(Integer v) { this.serviceNocs = v; }
    public Integer getCompleteNocs() { return completeNocs; }
    public void setCompleteNocs(Integer v) { this.completeNocs = v; }
    public Long getAvgRecoverySec() { return avgRecoverySec; }
    public void setAvgRecoverySec(Long v) { this.avgRecoverySec = v; }
    public Double getCompleteRate() { return completeRate; }
    public void setCompleteRate(Double v) { this.completeRate = v; }
}
