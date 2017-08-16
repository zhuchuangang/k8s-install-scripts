package com.szss.demo;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.session.data.redis.config.annotation.web.http.EnableRedisHttpSession;

/**
 * Created by zcg on 2017/8/15.
 */
@SpringBootApplication
@EnableRedisHttpSession(maxInactiveIntervalInSeconds= 60)
public class Application {
    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }
}
