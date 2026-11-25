package kr.co.TRSolution.tnms.audit.vo;

import kr.co.TRSolution.tnms.common.BaseVO;

public class AuditVO extends BaseVO {
    private static final long serialVersionUID = 1L;
    private Long jobLogSn;
    private String userId;
    private String userNm;
    private String userIpAddr;
    private String cntnMenuNm;
    private String jobSeCd;
    private String trgtKeyVal;
    private String logCn;
    private String chgBfrCn;
    private String chgAftrCn;
    private String jobRsltCd;
    private String logCrtDt;
    private String lgnDt;
    private String startDate;
    private String endDate;

    public Long getJobLogSn() { return jobLogSn; }
    public void setJobLogSn(Long jobLogSn) { this.jobLogSn = jobLogSn; }

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getUserNm() { return userNm; }
    public void setUserNm(String userNm) { this.userNm = userNm; }
    public String getUserIpAddr() { return userIpAddr; }
    public void setUserIpAddr(String userIpAddr) { this.userIpAddr = userIpAddr; }
    public String getCntnMenuNm() { return cntnMenuNm; }
    public void setCntnMenuNm(String cntnMenuNm) { this.cntnMenuNm = cntnMenuNm; }
    public String getJobSeCd() { return jobSeCd; }
    public void setJobSeCd(String jobSeCd) { this.jobSeCd = jobSeCd; }
    public String getTrgtKeyVal() { return trgtKeyVal; }
    public void setTrgtKeyVal(String trgtKeyVal) { this.trgtKeyVal = trgtKeyVal; }
    public String getLogCn() { return logCn; }
    public void setLogCn(String logCn) { this.logCn = logCn; }
    public String getChgBfrCn() { return chgBfrCn; }
    public void setChgBfrCn(String chgBfrCn) { this.chgBfrCn = chgBfrCn; }
    public String getChgAftrCn() { return chgAftrCn; }
    public void setChgAftrCn(String chgAftrCn) { this.chgAftrCn = chgAftrCn; }
    public String getJobRsltCd() { return jobRsltCd; }
    public void setJobRsltCd(String jobRsltCd) { this.jobRsltCd = jobRsltCd; }
    public String getLogCrtDt() { return logCrtDt; }
    public void setLogCrtDt(String logCrtDt) { this.logCrtDt = logCrtDt; }
    public String getLgnDt() { return lgnDt; }
    public void setLgnDt(String lgnDt) { this.lgnDt = lgnDt; }
    public String getStartDate() { return startDate; }
    public void setStartDate(String startDate) { this.startDate = startDate; }
    public String getEndDate() { return endDate; }
    public void setEndDate(String endDate) { this.endDate = endDate; }
}
