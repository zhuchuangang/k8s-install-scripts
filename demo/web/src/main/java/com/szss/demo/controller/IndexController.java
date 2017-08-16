package com.szss.demo.controller;

import com.szss.demo.interceptor.AuthInterceptor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;

import javax.servlet.http.HttpServletRequest;
import java.net.InetAddress;

/**
 * Created by zcg on 2017/8/15.
 */
@Slf4j
@Controller
public class IndexController {

    @RequestMapping(value = "/index", method = RequestMethod.GET)
    public String index(HttpServletRequest request, Model model) throws Exception {
        String ip = InetAddress.getLocalHost().getHostAddress();
        model.addAttribute("serverIP", ip);
        model.addAttribute("user", request.getSession().getAttribute(AuthInterceptor.USER_KEY));
        return "index";
    }
}
