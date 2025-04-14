package com.instagram.server.controller;

import com.instagram.server.dto.request.UpdateBioRequest;
import com.instagram.server.dto.request.UpdateProfileImageRequest;
import com.instagram.server.dto.request.UpdateUserRequest;
import com.instagram.server.entity.User;
import com.instagram.server.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;

@RestController
@RequestMapping("/api/users")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PutMapping("/bio")
    public ResponseEntity<User> updateBio(@RequestBody UpdateBioRequest request) {
        User updatedUser = userService.updateBio(request);
        return ResponseEntity.ok(updatedUser);
    }

    @PutMapping("/profile")
    public ResponseEntity<User> updateProfile(@RequestBody UpdateUserRequest request) {
        User updatedUser = userService.updateUserInfo(request);
        return ResponseEntity.ok(updatedUser);
    }

    @PutMapping("/profile-image")
    public ResponseEntity<User> updateProfileImage(@RequestBody UpdateProfileImageRequest request) {
        try {
            User updatedUser = userService.updateProfileImage(request);
            return ResponseEntity.ok(updatedUser);
        } catch (IOException e) {
            return ResponseEntity.badRequest().build();
        }
    }
}





