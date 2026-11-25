package kr.co.TRSolution.tnms.notification.vo;

import java.io.Serializable;

public class NotificationVO implements Serializable {
    private static final long serialVersionUID = 1L;
    private String userId;
    private String notificationId;
    private String categoryCd;
    private String categoryNm;
    private String severityCd;
    private String title;
    private String message;
    private String sourceName;
    private String refKey;
    private String eventDt;
    private String targetUrl;
    private String readYn;
    private String readDt;

    public String getUserId() { return userId; }
    public void setUserId(String userId) { this.userId = userId; }
    public String getNotificationId() { return notificationId; }
    public void setNotificationId(String notificationId) { this.notificationId = notificationId; }
    public String getCategoryCd() { return categoryCd; }
    public void setCategoryCd(String categoryCd) { this.categoryCd = categoryCd; }
    public String getCategoryNm() { return categoryNm; }
    public void setCategoryNm(String categoryNm) { this.categoryNm = categoryNm; }
    public String getSeverityCd() { return severityCd; }
    public void setSeverityCd(String severityCd) { this.severityCd = severityCd; }
    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }
    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
    public String getSourceName() { return sourceName; }
    public void setSourceName(String sourceName) { this.sourceName = sourceName; }
    public String getRefKey() { return refKey; }
    public void setRefKey(String refKey) { this.refKey = refKey; }
    public String getEventDt() { return eventDt; }
    public void setEventDt(String eventDt) { this.eventDt = eventDt; }
    public String getTargetUrl() { return targetUrl; }
    public void setTargetUrl(String targetUrl) { this.targetUrl = targetUrl; }
    public String getReadYn() { return readYn; }
    public void setReadYn(String readYn) { this.readYn = readYn; }
    public String getReadDt() { return readDt; }
    public void setReadDt(String readDt) { this.readDt = readDt; }
}
