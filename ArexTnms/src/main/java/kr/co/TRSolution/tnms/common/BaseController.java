package kr.co.TRSolution.tnms.common;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.springframework.web.servlet.ModelAndView;

import kr.co.TRSolution.tnms.user.vo.UserVO;

public abstract class BaseController {
    protected ModelAndView success(Object data) {
        ModelAndView mav = new ModelAndView("jsonView");
        mav.addObject("success", Boolean.TRUE);
        mav.addObject("data", data);
        return mav;
    }

    protected ModelAndView success(String message, Object data) {
        ModelAndView mav = success(data);
        mav.addObject("message", message);
        return mav;
    }

    protected ModelAndView fail(String message) {
        ModelAndView mav = new ModelAndView("jsonView");
        mav.addObject("success", Boolean.FALSE);
        mav.addObject("message", message);
        return mav;
    }

    protected UserVO loginUser(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session == null ? null : (UserVO) session.getAttribute("loginUser");
    }
}
