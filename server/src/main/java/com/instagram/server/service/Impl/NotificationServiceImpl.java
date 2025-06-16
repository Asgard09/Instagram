package com.instagram.server.service.Impl;

import com.instagram.server.base.TypeOfNotification;
import com.instagram.server.entity.Notification;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;
import com.instagram.server.repository.NotificationRepository;
import com.instagram.server.service.NotificationService;
import com.instagram.server.service.UserService;
import jakarta.transaction.Transactional;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;

@Service
@Slf4j
@Transactional
public class NotificationServiceImpl implements NotificationService {
    private final NotificationRepository notificationRepository;
    private final UserService userService;
    private final SimpMessagingTemplate messagingTemplate;

    public NotificationServiceImpl(NotificationRepository notificationRepository, UserService userService, SimpMessagingTemplate messagingTemplate) {
        this.notificationRepository = notificationRepository;
        this.userService = userService;
        this.messagingTemplate = messagingTemplate;
    }

    @Override
    public Notification createNotification(TypeOfNotification type, String message, User fromUser, User toUser, Post post) {
        if (toUser.getUserId().equals(fromUser.getUserId())) return null;
        Notification notification = Notification.builder()
                .type(type)
                .message(message)
                .fromUser(fromUser)
                .toUser(toUser)
                .post(post)
                .createdAt(LocalDateTime.now())
                .isRead(false)
                .build();
        Notification savedNotification = notificationRepository.save(notification);

        sendNotificationToUser(toUser.getUsername(), savedNotification);

        log.info("Created notification: {} from {} to {}", type, fromUser.getUsername(), toUser.getUsername());

        return savedNotification;
    }

    @Override
    public List<Notification> getNotificationsForUser(String username) {
        User user = userService.getUserByUsername(username);
        return notificationRepository.findByToUserOrderByCreatedAtDesc(user);
    }

    @Override
    public List<Notification> getUnreadNotificationForUser(String username) {
        User user = userService.getUserByUsername(username);
        return notificationRepository.findByToUserAndIsReadFalseOrderByCreatedAtDesc(user);
    }

    @Override
    public long getUnreadNotificationCount(String username) {
        User user = userService.getUserByUsername(username);
        return notificationRepository.countUnreadNotifications(user);
    }

    @Override
    public Notification markAsRead(Long notificationId) {
        Notification notification = notificationRepository.findById(notificationId)
                .orElseThrow(() -> new RuntimeException("Notification not found"));

        if (!notification.isRead()) {
            notification.setRead(true);
            notification.setReadAt(LocalDateTime.now());
            notification = notificationRepository.save(notification);

            // Send updated notification count via WebSocket
            long unreadCount = getUnreadNotificationCount(notification.getToUser().getUsername());
            messagingTemplate.convertAndSendToUser(
                    notification.getToUser().getUsername(),
                    "/notifications/count",
                    unreadCount
            );
        }

        return notification;
    }

    @Override
    public void sendNotificationToUser(String username, Notification notification) {
        try {
            // Send the notification to the user's notification channel
            messagingTemplate.convertAndSendToUser(username, "/notifications", notification);

            // Send updated unread count
            long unreadCount = getUnreadNotificationCount(username);
            messagingTemplate.convertAndSendToUser(username, "/notifications/count", unreadCount);

            log.debug("Sent WebSocket notification to user: {}", username);
        } catch (Exception e) {
            log.error("Failed to send WebSocket notification to user: {}", username, e);
        }
    }

    @Override
    public void createLikeNotification(User fromUser, User toUser, Post post) {
        String message = String.format("%s liked your post", fromUser.getUsername());
        notificationRepository.save(createNotification(TypeOfNotification.LIKE, message, fromUser, toUser, post));
    }

    @Override
    public void createCommentNotification(User fromUser, User toUser, Post post, String commentText) {
        String message = String.format("%s commented on your post: \"%s\"",
                fromUser.getUsername(),
                commentText.length() > 50 ? commentText.substring(0, 50) + "..." : commentText);
        notificationRepository.save(createNotification(TypeOfNotification.COMMENT, message, fromUser, toUser, post));
    }

    @Override
    public void createFollowNotification(User fromUser, User toUser) {
        String message = String.format("%s started following you", fromUser.getUsername());
        notificationRepository.save(createNotification(TypeOfNotification.FOLLOW, message, fromUser, toUser, null));
    }
}
