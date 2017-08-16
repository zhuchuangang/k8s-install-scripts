package com.szss.demo.init;

import com.szss.demo.entity.User;
import com.szss.demo.service.UserService;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * Created by zcg on 2017/8/15.
 */
@Component
public class DBInitializer  implements ApplicationListener<ContextRefreshedEvent> {

    public void onApplicationEvent(ContextRefreshedEvent event) {
        if (event.getApplicationContext().getDisplayName().contains("AnnotationConfigEmbeddedWebApplicationContext")) {
            UserService service = event.getApplicationContext().getBean(UserService.class);
            List<User> list=service.findAll();
            if (list==null||list.isEmpty()) {
                service.save(new User(1, "admin", "123456", "admin"));
            }
        }
    }
}
