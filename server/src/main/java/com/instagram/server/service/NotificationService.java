package com.instagram.server.service;

public interface NotificationService {
    void sendLikeNotification(Long postId, Long likerUserId, Long postOwnerUserId);
    void sendCommentNotification(Long postId, Long commenterUserId, Long postOwnerUserId, String commentContent);
    void sendFollowNotification(Long followerUserId, Long followedUserId);
}
