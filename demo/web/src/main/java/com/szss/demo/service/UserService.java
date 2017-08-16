package com.szss.demo.service;

import com.szss.demo.entity.User;
import com.szss.demo.mapper.UserMapper;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;

/**
 * Created by zcg on 2017/8/15.
 */
@Service
public class UserService {

    @Autowired
    public UserMapper userMapper;

    public void save(User user) {
        userMapper.save(user);
    }

    public User find(String username, String password) {
        return userMapper.find(username, password);
    }

    public List<User> findAll() {
        return userMapper.findAll();
    }
}
