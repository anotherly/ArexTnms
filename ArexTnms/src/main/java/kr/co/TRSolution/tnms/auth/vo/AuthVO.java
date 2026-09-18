package kr.co.TRSolution.tnms.auth.vo;

import java.util.List;

import kr.co.TRSolution.tnms.common.BaseVO;

public class AuthVO extends BaseVO {
    private static final long serialVersionUID = 1L;

    private String authrtCd;
    private String authrtNm;
    private String authrtExpln;
    private Integer userNocs;
    private List<MenuAuthVO> menuAuthList;

    public String getAuthrtCd() { return authrtCd; }
    public void setAuthrtCd(String authrtCd) { this.authrtCd = authrtCd; }
    public String getAuthrtNm() { return authrtNm; }
    public void setAuthrtNm(String authrtNm) { this.authrtNm = authrtNm; }
    public String getAuthrtExpln() { return authrtExpln; }
    public void setAuthrtExpln(String authrtExpln) { this.authrtExpln = authrtExpln; }
    public Integer getUserNocs() { return userNocs; }
    public void setUserNocs(Integer userNocs) { this.userNocs = userNocs; }
    public List<MenuAuthVO> getMenuAuthList() { return menuAuthList; }
    public void setMenuAuthList(List<MenuAuthVO> menuAuthList) { this.menuAuthList = menuAuthList; }
}
