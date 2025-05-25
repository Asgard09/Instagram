package com.instagram.server.service;

import com.instagram.server.dto.request.UpdateBioRequest;
import com.instagram.server.dto.request.UpdateProfileImageRequest;
import com.instagram.server.dto.request.UpdateUserRequest;
import com.instagram.server.entity.User;

import java.io.IOException;
import java.util.List;

public interface UserService {
    List<User> getFollowersForTagging(String username);
    User updateBio(UpdateBioRequest request);
    User updateUserInfo(UpdateUserRequest request);
    User updateProfileImage(UpdateProfileImageRequest request) throws IOException;
    User getCurrentUser();
    User getUserByUsername(String username);
    User getUserById(Long userId);
    List<User> searchUsers(String query);
}
