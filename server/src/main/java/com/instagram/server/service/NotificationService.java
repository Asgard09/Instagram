package com.instagram.server.service;

import com.instagram.server.base.TypeOfNotification;
import com.instagram.server.entity.Notification;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;

import java.util.List;
/*Note
* Single Responsibility: NotificationService only handles notifications
* Loose Coupling: Business services control their own notification messages
*/
public interface NotificationService {
    void createNotification(TypeOfNotification type, String message, User fromUser, User toUser, Post post);
    List<Notification> getUnreadNotificationForUser(String username);
    List<Notification> getNotificationsForUser(String username);
    long getUnreadNotificationCount(String username);
    Notification markAsRead(Long notificationId);
    void sendNotificationToUser(String username, Notification notification);
}
