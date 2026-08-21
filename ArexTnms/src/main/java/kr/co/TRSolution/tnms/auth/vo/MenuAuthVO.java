package kr.co.TRSolution.tnms.auth.vo;

import kr.co.TRSolution.tnms.common.BaseVO;

public class MenuAuthVO extends BaseVO {
    private static final long serialVersionUID = 1L;

    private Long authrtSn;
    private Long menuSn;
    private Long upMenuSn;
    private String menuNm;
    private String menuUrlAddr;
    private String screenKey;
    private Integer menuSeq;
    private String listAuthrtYn;
    private String dtlAuthrtYn;
    private String regAuthrtYn;
    private String mdfcnAuthrtYn;
    private String delAuthrtYn;
    private String ctrlAuthrtYn;

    public Long getAuthrtSn() { return authrtSn; }
    public void setAuthrtSn(Long authrtSn) { this.authrtSn = authrtSn; }
    public Long getMenuSn() { return menuSn; }
    public void setMenuSn(Long menuSn) { this.menuSn = menuSn; }
    public Long getUpMenuSn() { return upMenuSn; }
    public void setUpMenuSn(Long upMenuSn) { this.upMenuSn = upMenuSn; }
    public String getMenuNm() { return menuNm; }
    public void setMenuNm(String menuNm) { this.menuNm = menuNm; }
    public String getMenuUrlAddr() { return menuUrlAddr; }
    public void setMenuUrlAddr(String menuUrlAddr) { this.menuUrlAddr = menuUrlAddr; }
    public String getScreenKey() { return screenKey; }
    public void setScreenKey(String screenKey) { this.screenKey = screenKey; }
    public Integer getMenuSeq() { return menuSeq; }
    public void setMenuSeq(Integer menuSeq) { this.menuSeq = menuSeq; }
    public String getListAuthrtYn() { return listAuthrtYn; }
    public void setListAuthrtYn(String value) { this.listAuthrtYn = value; }
    public String getDtlAuthrtYn() { return dtlAuthrtYn; }
    public void setDtlAuthrtYn(String value) { this.dtlAuthrtYn = value; }
    public String getRegAuthrtYn() { return regAuthrtYn; }
    public void setRegAuthrtYn(String value) { this.regAuthrtYn = value; }
    public String getMdfcnAuthrtYn() { return mdfcnAuthrtYn; }
    public void setMdfcnAuthrtYn(String value) { this.mdfcnAuthrtYn = value; }
    public String getDelAuthrtYn() { return delAuthrtYn; }
    public void setDelAuthrtYn(String value) { this.delAuthrtYn = value; }
    public String getCtrlAuthrtYn() { return ctrlAuthrtYn; }
    public void setCtrlAuthrtYn(String value) { this.ctrlAuthrtYn = value; }

    public boolean permits(String action) {
        if ("LIST".equals(action)) return "Y".equals(listAuthrtYn);
        if ("DTL".equals(action)) return "Y".equals(dtlAuthrtYn);
        if ("REG".equals(action)) return "Y".equals(regAuthrtYn);
        if ("MDFCN".equals(action)) return "Y".equals(mdfcnAuthrtYn);
        if ("DEL".equals(action)) return "Y".equals(delAuthrtYn);
        if ("CTRL".equals(action)) return "Y".equals(ctrlAuthrtYn);
        return false;
    }
}
