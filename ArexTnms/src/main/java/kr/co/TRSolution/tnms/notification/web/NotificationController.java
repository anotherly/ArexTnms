package kr.co.TRSolution.tnms.notification.web;

import javax.annotation.Resource;
import javax.servlet.http.HttpServletRequest;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.common.BaseController;
import kr.co.TRSolution.tnms.notification.service.NotificationService;
import kr.co.TRSolution.tnms.user.vo.UserVO;

@Controller
public class NotificationController extends BaseController {
    @Resource(name = "notificationService") private NotificationService notificationService;

    @RequestMapping(value = "/notification/list.ajax", method = RequestMethod.GET)
    public ModelAndView list(HttpServletRequest request) {
        try { return success(notificationService.selectNotificationList(userId(request))); }
        catch (Exception e) { return fail(message(e, "알림을 조회하지 못했습니다.")); }
    }

    @RequestMapping(value = "/notification/read.ajax", method = RequestMethod.POST)
    public ModelAndView read(@RequestParam("notificationId") String notificationId, HttpServletRequest request) {
        try {
            notificationService.markRead(userId(request), notificationId);
            return success("알림을 읽음 처리했습니다.", null);
        } catch (Exception e) { return fail(message(e, "알림 읽음 처리에 실패했습니다.")); }
    }

    @RequestMapping(value = "/notification/read-all.ajax", method = RequestMethod.POST)
    public ModelAndView readAll(HttpServletRequest request) {
        try { return success("전체 알림을 읽음 처리했습니다.", notificationService.markAllRead(userId(request))); }
        catch (Exception e) { return fail(message(e, "전체 읽음 처리에 실패했습니다.")); }
    }

    private String userId(HttpServletRequest request) {
        UserVO user = loginUser(request);
        if (user == null || user.getUserId() == null) throw new IllegalStateException("로그인 세션이 필요합니다.");
        return user.getUserId();
    }

    private String message(Exception e, String fallback) {
        return e.getMessage() == null ? fallback : e.getMessage();
    }
}
