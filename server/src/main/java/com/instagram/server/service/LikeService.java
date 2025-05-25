package com.instagram.server.service;

import com.instagram.server.entity.Like;
import com.instagram.server.entity.User;

import java.util.List;

public interface LikeService {
    Like likePost(Long postId);
    void unlikePost(Long postId);
    boolean hasUserLikedPost(Long postId);
    Long getLikeCount(Long postId);
    List<User> getUsersWhoLikedPost(Long postId);
}
