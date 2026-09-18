package kr.co.TRSolution.tnms.monitoring.vo;

public class EquipmentVO extends MonitoringBaseVO {
    private static final long serialVersionUID = 1L;
    private Long eqpmntSn;
    private String eqpmntMngNo;
    private String eqpmntNm;
    private String eqpmntSeCd;
    private String eqpmntClsfCd;
    private String eqpmntClsfNm;
    private String emsId;
    private String instlPlcNm;
    private String eqpmntIpAddr;
    private String macAddr;
    private String eqpmntMdlNm;
    private String eqpmntExpln;
    private String cntnYn;
    private Integer pingRspnsMs;
    private String sttsExpln;
    private String lastRspnsDt;
    private String clctDt;
    private Integer totalNocs;
    private Integer normalNocs;
    private Integer cautionNocs;
    private Integer criticalNocs;
    private Integer offlineNocs;
    private Integer unknownNocs;
    private String flrNm;
    private Integer cmraQty;
    private String pbxEqpmNm;
    private String cmpntNm;
    private Long mtbfHr;

    // eqpmnt_perf_stts 현재 성능값. 컬럼을 장비 테이블에 중복 생성하지 않고 지표 테이블에서 조회합니다.
    private Double cpuUsgrt;
    private Double mmryUsgrt;
    private Integer ifUseNocs;
    private Integer ifTotalNocs;

    // 행선안내 표시장치 ↔ LSE 다대다 관계
    private Long[] lseEqpmntSns;
    private Long lseEqpmntSn;
    private String lseEqpmntSnsCsv;
    private String lseEqpmntNms;

    public Long getEqpmntSn() { return eqpmntSn; }
    public void setEqpmntSn(Long eqpmntSn) { this.eqpmntSn = eqpmntSn; }
    public String getEqpmntMngNo() { return eqpmntMngNo; }
    public void setEqpmntMngNo(String eqpmntMngNo) { this.eqpmntMngNo = eqpmntMngNo; }
    public String getEqpmntNm() { return eqpmntNm; }
    public void setEqpmntNm(String eqpmntNm) { this.eqpmntNm = eqpmntNm; }
    public String getEqpmntSeCd() { return eqpmntSeCd; }
    public void setEqpmntSeCd(String eqpmntSeCd) { this.eqpmntSeCd = eqpmntSeCd; }
    public String getEqpmntClsfCd() { return eqpmntClsfCd; }
    public void setEqpmntClsfCd(String eqpmntClsfCd) { this.eqpmntClsfCd = eqpmntClsfCd; }
    public String getEqpmntClsfNm() { return eqpmntClsfNm; }
    public void setEqpmntClsfNm(String eqpmntClsfNm) { this.eqpmntClsfNm = eqpmntClsfNm; }
    public String getEmsId() { return emsId; }
    public void setEmsId(String emsId) { this.emsId = emsId; }
    public String getInstlPlcNm() { return instlPlcNm; }
    public void setInstlPlcNm(String instlPlcNm) { this.instlPlcNm = instlPlcNm; }
    public String getEqpmntIpAddr() { return eqpmntIpAddr; }
    public void setEqpmntIpAddr(String eqpmntIpAddr) { this.eqpmntIpAddr = eqpmntIpAddr; }
    public String getMacAddr() { return macAddr; }
    public void setMacAddr(String macAddr) { this.macAddr = macAddr; }
    public String getEqpmntMdlNm() { return eqpmntMdlNm; }
    public void setEqpmntMdlNm(String eqpmntMdlNm) { this.eqpmntMdlNm = eqpmntMdlNm; }
    public String getEqpmntExpln() { return eqpmntExpln; }
    public void setEqpmntExpln(String eqpmntExpln) { this.eqpmntExpln = eqpmntExpln; }
    public String getCntnYn() { return cntnYn; }
    public void setCntnYn(String cntnYn) { this.cntnYn = cntnYn; }
    public Integer getPingRspnsMs() { return pingRspnsMs; }
    public void setPingRspnsMs(Integer pingRspnsMs) { this.pingRspnsMs = pingRspnsMs; }
    public String getSttsExpln() { return sttsExpln; }
    public void setSttsExpln(String sttsExpln) { this.sttsExpln = sttsExpln; }
    public String getLastRspnsDt() { return lastRspnsDt; }
    public void setLastRspnsDt(String lastRspnsDt) { this.lastRspnsDt = lastRspnsDt; }
    public String getClctDt() { return clctDt; }
    public void setClctDt(String clctDt) { this.clctDt = clctDt; }
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
    public String getFlrNm() { return flrNm; }
    public void setFlrNm(String flrNm) { this.flrNm = flrNm; }
    public Integer getCmraQty() { return cmraQty; }
    public void setCmraQty(Integer cmraQty) { this.cmraQty = cmraQty; }
    public String getPbxEqpmNm() { return pbxEqpmNm; }
    public void setPbxEqpmNm(String pbxEqpmNm) { this.pbxEqpmNm = pbxEqpmNm; }
    public String getCmpntNm() { return cmpntNm; }
    public void setCmpntNm(String cmpntNm) { this.cmpntNm = cmpntNm; }
    public Long getMtbfHr() { return mtbfHr; }
    public void setMtbfHr(Long mtbfHr) { this.mtbfHr = mtbfHr; }
    public Double getCpuUsgrt() { return cpuUsgrt; }
    public void setCpuUsgrt(Double cpuUsgrt) { this.cpuUsgrt = cpuUsgrt; }
    public Double getMmryUsgrt() { return mmryUsgrt; }
    public void setMmryUsgrt(Double mmryUsgrt) { this.mmryUsgrt = mmryUsgrt; }
    public Integer getIfUseNocs() { return ifUseNocs; }
    public void setIfUseNocs(Integer ifUseNocs) { this.ifUseNocs = ifUseNocs; }
    public Integer getIfTotalNocs() { return ifTotalNocs; }
    public void setIfTotalNocs(Integer ifTotalNocs) { this.ifTotalNocs = ifTotalNocs; }
    public Long[] getLseEqpmntSns() { return lseEqpmntSns; }
    public void setLseEqpmntSns(Long[] lseEqpmntSns) { this.lseEqpmntSns = lseEqpmntSns; }
    public Long getLseEqpmntSn() { return lseEqpmntSn; }
    public void setLseEqpmntSn(Long lseEqpmntSn) { this.lseEqpmntSn = lseEqpmntSn; }
    public String getLseEqpmntSnsCsv() { return lseEqpmntSnsCsv; }
    public void setLseEqpmntSnsCsv(String lseEqpmntSnsCsv) { this.lseEqpmntSnsCsv = lseEqpmntSnsCsv; }
    public String getLseEqpmntNms() { return lseEqpmntNms; }
    public void setLseEqpmntNms(String lseEqpmntNms) { this.lseEqpmntNms = lseEqpmntNms; }
}
