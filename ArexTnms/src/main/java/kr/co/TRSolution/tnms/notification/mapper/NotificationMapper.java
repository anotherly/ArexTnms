package kr.co.TRSolution.tnms.notification.mapper;

import java.util.List;

import egovframework.rte.psl.dataaccess.mapper.Mapper;
import kr.co.TRSolution.tnms.notification.vo.NotificationVO;

@Mapper("notificationMapper")
public interface NotificationMapper {
    List<NotificationVO> selectNotificationList(String userId);
    int upsertNotificationRead(NotificationVO notificationVO);
}
