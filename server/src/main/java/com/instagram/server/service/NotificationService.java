package com.instagram.server.service;

import com.instagram.server.base.TypeOfNotification;
import com.instagram.server.entity.Notification;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;

public interface NotificationService {
    Notification createNotification(TypeOfNotification type, String message, User fromUser, User toUser, Post post);
    void deleteNotification(Long notificationId);
    void sendNotificationToUser(String username, Notification notification);
    void createLikeNotification(User fromUser, User toUser, Post post);
    void createCommentNotification(User fromUser, User toUser, Post post, String commentText);
    void createFollowNotification(User fromUser, User toUser);
}
