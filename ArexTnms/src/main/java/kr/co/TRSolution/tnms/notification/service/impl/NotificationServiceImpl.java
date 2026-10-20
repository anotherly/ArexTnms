package kr.co.TRSolution.tnms.notification.service.impl;

import java.util.List;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.notification.mapper.NotificationMapper;
import kr.co.TRSolution.tnms.notification.service.NotificationService;
import kr.co.TRSolution.tnms.notification.vo.NotificationVO;

@Service("notificationService")
public class NotificationServiceImpl implements NotificationService {
    @Resource(name = "notificationMapper") private NotificationMapper notificationMapper;

    @Override
    public List<NotificationVO> selectNotificationList(String userId) {
        requireUser(userId);
        return notificationMapper.selectNotificationList(userId);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public void markRead(String userId, String notificationId) {
        requireUser(userId);
        if (notificationId == null || notificationId.trim().length() == 0 || notificationId.length() > 160) {
            throw new IllegalArgumentException("알림 식별값이 올바르지 않습니다.");
        }
        NotificationVO vo = new NotificationVO();
        vo.setUserId(userId);
        vo.setNotificationId(notificationId.trim());
        notificationMapper.upsertNotificationRead(vo);
    }

    @Override
    @Transactional(rollbackFor = Exception.class)
    public int markAllRead(String userId) {
        requireUser(userId);
        List<NotificationVO> list = notificationMapper.selectNotificationList(userId);
        int count = 0;
        for (NotificationVO item : list) {
            if (!"Y".equals(item.getReadYn())) {
                NotificationVO vo = new NotificationVO();
                vo.setUserId(userId);
                vo.setNotificationId(item.getNotificationId());
                count += notificationMapper.upsertNotificationRead(vo);
            }
        }
        return count;
    }

    private void requireUser(String userId) {
        if (userId == null || userId.trim().length() == 0) throw new IllegalStateException("로그인 세션이 필요합니다.");
    }
}
