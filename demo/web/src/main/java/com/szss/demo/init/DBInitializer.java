package com.szss.demo.init;

import com.szss.demo.entity.User;
import com.szss.demo.service.UserService;
import org.apache.tomcat.jdbc.pool.DataSource;
import org.springframework.context.ApplicationListener;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.stereotype.Component;

import java.sql.*;
import java.util.List;

/**
 * Created by zcg on 2017/8/15.
 */
@Component
public class DBInitializer implements ApplicationListener<ContextRefreshedEvent> {

    @Override
    public void onApplicationEvent(ContextRefreshedEvent event) {
        if (event.getApplicationContext().getDisplayName().contains("AnnotationConfigEmbeddedWebApplicationContext")) {
            UserService service = event.getApplicationContext().getBean(UserService.class);
            DataSource dataSource = event.getApplicationContext().getBean(DataSource.class);
            Connection connection = null;
            try {
                connection = dataSource.getConnection();
                DatabaseMetaData meta = connection.getMetaData();
                ResultSet rsTables = meta.getTables("test", null, "t_user",
                        new String[]{"TABLE"});
                if (!rsTables.next()) {
                    Statement stmt = connection.createStatement();

                    String sql = "CREATE TABLE t_user ( " +
                            "  id       INT PRIMARY KEY," +
                            "  username VARCHAR(20)," +
                            "  password VARCHAR(20)," +
                            "  name     VARCHAR(20))";

                    stmt.executeUpdate(sql);
                }
                rsTables.close();
            } catch (SQLException e) {
                e.printStackTrace();
            }
            List<User> list = service.findAll();
            if (list == null || list.isEmpty()) {
                service.save(new User(1, "admin", "123456", "admin"));
            }
        }
    }
}
