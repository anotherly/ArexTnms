package kr.co.TRSolution.tnms.monitoring.vo;

public class StationStatusVO extends MonitoringBaseVO {
    private static final long serialVersionUID = 1L;
    private Integer stnSeq;
    private String mnlsStnYn;
    private Integer totalNocs;
    private Integer normalNocs;
    private Integer cautionNocs;
    private Integer criticalNocs;
    private Integer offlineNocs;
    private Integer unknownNocs;
    private String lastClctDt;

    public Integer getStnSeq() { return stnSeq; }
    public void setStnSeq(Integer stnSeq) { this.stnSeq = stnSeq; }
    public String getMnlsStnYn() { return mnlsStnYn; }
    public void setMnlsStnYn(String mnlsStnYn) { this.mnlsStnYn = mnlsStnYn; }
    public Integer getTotalNocs() { return totalNocs; }
    public void setTotalNocs(Integer totalNocs) { this.totalNocs = totalNocs; }
    public Integer getNormalNocs() { return normalNocs; }
    public void setNormalNocs(Integer normalNocs) { this.normalNocs = normalNocs; }
    public Integer getCautionNocs() { return cautionNocs; }
    public void setCautionNocs(Integer cautionNocs) { this.cautionNocs = cautionNocs; }
    public Integer getCriticalNocs() { return criticalNocs; }
    public void setCriticalNocs(Integer criticalNocs) { this.criticalNocs = criticalNocs; }
    public Integer getOfflineNocs() { return offlineNocs; }
    public void setOfflineNocs(Integer offlineNocs) { this.offlineNocs = offlineNocs; }
    public Integer getUnknownNocs() { return unknownNocs; }
    public void setUnknownNocs(Integer unknownNocs) { this.unknownNocs = unknownNocs; }
    public String getLastClctDt() { return lastClctDt; }
    public void setLastClctDt(String lastClctDt) { this.lastClctDt = lastClctDt; }
}
