package kr.co.TRSolution.tnms.common;

import java.io.Serializable;

public class BaseVO implements Serializable {
    private static final long serialVersionUID = 1L;

    private String searchCondition;
    private String searchKeyword;
    private String useYn;
    private Integer pageIndex = Integer.valueOf(1);
    private Integer pageSize = Integer.valueOf(20);
    private Long rgtrSn;
    private Long mdfrSn;
    private String regDt;
    private String mdfcnDt;

    public String getSearchCondition() { return searchCondition; }
    public void setSearchCondition(String searchCondition) { this.searchCondition = searchCondition; }
    public String getSearchKeyword() { return searchKeyword; }
    public void setSearchKeyword(String searchKeyword) { this.searchKeyword = searchKeyword; }
    public String getUseYn() { return useYn; }
    public void setUseYn(String useYn) { this.useYn = useYn; }
    public Integer getPageIndex() { return pageIndex; }
    public void setPageIndex(Integer pageIndex) { this.pageIndex = pageIndex; }
    public Integer getPageSize() { return pageSize; }
    public void setPageSize(Integer pageSize) { this.pageSize = pageSize; }
    public Long getRgtrSn() { return rgtrSn; }
    public void setRgtrSn(Long rgtrSn) { this.rgtrSn = rgtrSn; }
    public Long getMdfrSn() { return mdfrSn; }
    public void setMdfrSn(Long mdfrSn) { this.mdfrSn = mdfrSn; }
    public String getRegDt() { return regDt; }
    public void setRegDt(String regDt) { this.regDt = regDt; }
    public String getMdfcnDt() { return mdfcnDt; }
    public void setMdfcnDt(String mdfcnDt) { this.mdfcnDt = mdfcnDt; }
}
