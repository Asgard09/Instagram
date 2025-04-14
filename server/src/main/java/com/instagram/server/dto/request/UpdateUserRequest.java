package com.instagram.server.dto.request;

import com.instagram.server.base.Gender;
import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateUserRequest {
    private String username;
    private String name;
    private String bio;
    private String profilePicture;
    private Gender gender;
} 