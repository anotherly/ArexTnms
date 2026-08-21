package kr.co.TRSolution.tnms.audit.vo;

import kr.co.TRSolution.tnms.common.BaseVO;

public class AuditVO extends BaseVO {
    private static final long serialVersionUID = 1L;
    private Long userSn;
    private String userId;
    private String userIpAddr;
    private String cntnMenuNm;
    private String jobSeCd;
    private String trgtKeyVal;
    private String logCn;
    private String chgBfrCn;
    private String chgAftrCn;
    private String jobRsltCd;

    public Long getUserSn() { return userSn; }
    public void setUserSn(Long userSn) { this.userSn = userSn; }
    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
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
}
