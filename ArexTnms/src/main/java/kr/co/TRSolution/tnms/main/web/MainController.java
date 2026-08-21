package kr.co.TRSolution.tnms.main.web;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpSession;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;

@Controller
public class MainController {
    @RequestMapping("/")
    public String root(HttpServletRequest request) {
        HttpSession session = request.getSession(false);
        return session != null && session.getAttribute("loginUser") != null
                ? "redirect:/main/dashboard.do" : "redirect:/login/login.do";
    }

    @RequestMapping("/main/dashboard.do")
    public String dashboard() { return "main/dashboard"; }
}
