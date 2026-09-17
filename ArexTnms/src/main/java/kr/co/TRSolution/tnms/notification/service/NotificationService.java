package kr.co.TRSolution.tnms.notification.service;

import java.util.List;

import kr.co.TRSolution.tnms.notification.vo.NotificationVO;

public interface NotificationService {
    List<NotificationVO> selectNotificationList(String userId);
    void markRead(String userId, String notificationId);
    int markAllRead(String userId);
}
