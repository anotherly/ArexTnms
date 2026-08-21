package kr.co.TRSolution.tnms.auth.vo;

import java.util.List;

import kr.co.TRSolution.tnms.common.BaseVO;

public class AuthVO extends BaseVO {
    private static final long serialVersionUID = 1L;

    private Long authrtSn;
    private String authrtNm;
    private String authrtExpln;
    private String authrtSttsNm;
    private Integer userNocs;
    private List<MenuAuthVO> menuAuthList;

    public Long getAuthrtSn() { return authrtSn; }
    public void setAuthrtSn(Long authrtSn) { this.authrtSn = authrtSn; }
    public String getAuthrtNm() { return authrtNm; }
    public void setAuthrtNm(String authrtNm) { this.authrtNm = authrtNm; }
    public String getAuthrtExpln() { return authrtExpln; }
    public void setAuthrtExpln(String authrtExpln) { this.authrtExpln = authrtExpln; }
    public String getAuthrtSttsNm() { return authrtSttsNm; }
    public void setAuthrtSttsNm(String authrtSttsNm) { this.authrtSttsNm = authrtSttsNm; }
    public Integer getUserNocs() { return userNocs; }
    public void setUserNocs(Integer userNocs) { this.userNocs = userNocs; }
    public List<MenuAuthVO> getMenuAuthList() { return menuAuthList; }
    public void setMenuAuthList(List<MenuAuthVO> menuAuthList) { this.menuAuthList = menuAuthList; }
}
