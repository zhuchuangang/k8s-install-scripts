package com.szss.demo.entity;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.Serializable;

/**
 * Created by zcg on 2017/8/15.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class User implements Serializable {
    private long id;
    private String username;
    private String password;
    private String name;
}
