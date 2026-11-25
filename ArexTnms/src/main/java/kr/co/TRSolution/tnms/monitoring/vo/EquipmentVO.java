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
    // 게이트웨이의 실 장비 식별키 (ems_id, device_id).
    private String gatewayDeviceId;
    private String gatewayManaged;
    private String regId;
    private String modId;
    private String deviceMaker;
    private String serverIp;
    private Integer deviceCheck;
    private Double diskUsgrt;
    private String usageDt;
    private String usageFreshYn;
    private Integer pingAlive;
    private String testYn;
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

    // CCTV(VMS) 상세정보 - web_cctv_info (업체 엑셀 기준)
    private String vmsNm;
    private String strgMthNm;
    private String cctvNm;
    private String cnsmrNm;
    private String cctvMdlNm;
    private String frmwrVerNo;
    private String cctvIpAddr;
    private String cctvMacAddr;
    private String acntNm;
    private String vmsSrvrIpAddr;
    private String pbxEqpmNm;
    private String cmpntNm;
    private Long mtbfHr;

    // 게이트웨이 공통 성능값은 com_device_usage와 최신 수집시각을 기준으로 조회합니다.
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
    public String getGatewayDeviceId() { return gatewayDeviceId; }
    public void setGatewayDeviceId(String v) { this.gatewayDeviceId=v; }
    public String getRegId() { return regId; }
    public void setRegId(String v) { this.regId=v; }
    public String getModId() { return modId; }
    public void setModId(String v) { this.modId=v; }
    public String getServerIp() { return serverIp; }
    public void setServerIp(String v) { this.serverIp=v; }
    public String getDeviceMaker() { return deviceMaker; }
    public void setDeviceMaker(String v) { this.deviceMaker=v; }
    public Integer getDeviceCheck() { return deviceCheck; }
    public void setDeviceCheck(Integer v) { this.deviceCheck=v; }
    public String getGatewayManaged() { return gatewayManaged; }
    public void setGatewayManaged(String v) { this.gatewayManaged=v; }
    public Double getDiskUsgrt() { return diskUsgrt; }
    public void setDiskUsgrt(Double v) { this.diskUsgrt=v; }
    public String getUsageFreshYn() { return usageFreshYn; }
    public void setUsageFreshYn(String v) { this.usageFreshYn=v; }
    public String getUsageDt() { return usageDt; }
    public void setUsageDt(String v) { this.usageDt=v; }
    public Integer getPingAlive() { return pingAlive; }
    public void setPingAlive(Integer v) { this.pingAlive=v; }
    public String getTestYn() { return testYn; }
    public void setTestYn(String v) { this.testYn=v; }
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
    public String getVmsNm() { return vmsNm; }
    public void setVmsNm(String vmsNm) { this.vmsNm = vmsNm; }
    public String getStrgMthNm() { return strgMthNm; }
    public void setStrgMthNm(String strgMthNm) { this.strgMthNm = strgMthNm; }
    public String getCctvNm() { return cctvNm; }
    public void setCctvNm(String cctvNm) { this.cctvNm = cctvNm; }
    public String getCnsmrNm() { return cnsmrNm; }
    public void setCnsmrNm(String cnsmrNm) { this.cnsmrNm = cnsmrNm; }
    public String getCctvMdlNm() { return cctvMdlNm; }
    public void setCctvMdlNm(String cctvMdlNm) { this.cctvMdlNm = cctvMdlNm; }
    public String getFrmwrVerNo() { return frmwrVerNo; }
    public void setFrmwrVerNo(String frmwrVerNo) { this.frmwrVerNo = frmwrVerNo; }
    public String getCctvIpAddr() { return cctvIpAddr; }
    public void setCctvIpAddr(String cctvIpAddr) { this.cctvIpAddr = cctvIpAddr; }
    public String getCctvMacAddr() { return cctvMacAddr; }
    public void setCctvMacAddr(String cctvMacAddr) { this.cctvMacAddr = cctvMacAddr; }
    public String getAcntNm() { return acntNm; }
    public void setAcntNm(String acntNm) { this.acntNm = acntNm; }
    public String getVmsSrvrIpAddr() { return vmsSrvrIpAddr; }
    public void setVmsSrvrIpAddr(String vmsSrvrIpAddr) { this.vmsSrvrIpAddr = vmsSrvrIpAddr; }
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
