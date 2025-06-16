package com.instagram.server.service;

import com.instagram.server.base.TypeOfNotification;
import com.instagram.server.entity.Notification;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;

import java.util.List;

public interface NotificationService {
    Notification createNotification(TypeOfNotification type, String message, User fromUser, User toUser, Post post);
    List<Notification> getUnreadNotificationForUser(String username);
    List<Notification> getNotificationsForUser(String username);
    long getUnreadNotificationCount(String username);
    Notification markAsRead(Long notificationId);
    void sendNotificationToUser(String username, Notification notification);
    void createLikeNotification(User fromUser, User toUser, Post post);
    void createCommentNotification(User fromUser, User toUser, Post post, String commentText);
    void createFollowNotification(User fromUser, User toUser);
}
