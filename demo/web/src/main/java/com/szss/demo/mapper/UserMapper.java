package com.szss.demo.mapper;

import com.szss.demo.entity.User;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;

/**
 * Created by zcg on 2017/8/15.
 */
@Mapper
public interface UserMapper {
    @Select("select id,username,name,password from t_user")
    List<User> findAll();

    @Select("select id,username,name,password from t_user where username=#{username} and password=#{password}")
    User find(@Param("username") String username, @Param("password") String password);

    @Insert("insert into t_user(id,username,name,password) values(#{id},#{username},#{name},#{password})")
    void save(User user);
}
