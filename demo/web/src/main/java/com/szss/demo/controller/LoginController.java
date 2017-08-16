package com.szss.demo.controller;

import com.szss.demo.entity.User;
import com.szss.demo.interceptor.AuthInterceptor;
import com.szss.demo.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.RequestParam;

import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Created by zcg on 2017/8/15.
 */
@Slf4j
@Controller
public class LoginController {

    @Autowired
    private UserService userService;

    @RequestMapping(value = "/login", method = RequestMethod.GET)
    public String login() {
        return "login";
    }

    @RequestMapping(value = "/login", method = RequestMethod.POST)
    public String login(@RequestParam("username") String username,
                        @RequestParam("password") String password,
                        HttpServletRequest request,
                        HttpServletResponse response) throws Exception{
        log.debug("username:{} password:{}", username, password);
        User user = userService.find(username, password);
        if (user != null) {
            HttpSession session = request.getSession();
            session.setAttribute(AuthInterceptor.USER_KEY, user);
            response.sendRedirect("/index");
        }
        return "login";
    }
}
