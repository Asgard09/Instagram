package com.instagram.server.service;

import com.instagram.server.entity.Follow;
import com.instagram.server.entity.User;

import java.util.List;

public interface FollowService {
    Follow followUser(Long followeeId);
    void unfollowUser(Long followeeId);
    boolean isFollowing(Long followeeId);
    boolean isUserFollowing(Long followerId, Long followeeId);
    int getFollowersCount(Long userId);
    int getFollowingCount(Long userId);
    int getPostsCount(Long userId);
    List<User> getFollowers(Long userId);
    List<User> getFollowing(Long userId);
}
