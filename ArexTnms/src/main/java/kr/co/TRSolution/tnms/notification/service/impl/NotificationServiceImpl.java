package kr.co.TRSolution.tnms.notification.service.impl;

import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.HashMap;
import java.util.ArrayList;
import java.util.Arrays;
import kr.co.TRSolution.tnms.common.security.SystemDataScope;

import javax.annotation.Resource;

import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import kr.co.TRSolution.tnms.notification.mapper.NotificationMapper;
import kr.co.TRSolution.tnms.notification.service.NotificationService;
import kr.co.TRSolution.tnms.notification.vo.NotificationVO;

@Service("notificationService")
public class NotificationServiceImpl implements NotificationService {
    @Resource(name = "notificationMapper") private NotificationMapper notificationMapper;
    @Resource(name="systemCodeRegistry") private kr.co.TRSolution.tnms.gateway.service.SystemCodeRegistry codes;

    @Override
    public List<NotificationVO> selectNotificationList(String userId) {
        requireUser(userId);
        return notificationMapper.selectNotificationList(notificationParams(userId));
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
        List<NotificationVO> list = notificationMapper.selectNotificationList(notificationParams(userId));
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

    /** 알림에서도 로그인한 사용자의 허용 EMS만 조회합니다. */
    private Map<String,Object> notificationParams(String userId) {
        Map<String,Object> args = new HashMap<String,Object>();
        args.put("userId",userId);
        Set<String> allowed = SystemDataScope.current();
        args.put("allowedEmsIds",codes.allowedEmsIds(allowed));
        return args;
    }

    private void requireUser(String userId) {
        if (userId == null || userId.trim().length() == 0) throw new IllegalStateException("로그인 세션이 필요합니다.");
    }
}
