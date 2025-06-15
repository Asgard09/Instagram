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
    public void deleteNotification(Long notificationId) {

    }

    @Override
    public void sendNotificationToUser(String username, Notification notification) {

    }

    @Override
    public void createLikeNotification(User fromUser, User toUser, Post post) {

    }

    @Override
    public void createCommentNotification(User fromUser, User toUser, Post post, String commentText) {

    }

    @Override
    public void createFollowNotification(User fromUser, User toUser) {

    }
}
