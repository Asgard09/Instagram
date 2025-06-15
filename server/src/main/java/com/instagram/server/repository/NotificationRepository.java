package com.instagram.server.repository;

import com.instagram.server.entity.Notification;
import com.instagram.server.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;

public interface NotificationRepository extends JpaRepository<Notification, Long> {
    List<Notification> findByToUserOrderByCreatedAtDesc(User toUser);
    List<Notification> findByToUserAndIsReadFalseOrderByCreatedAtDesc(User toUser);
    @Query("SELECT COUNT(n) FROM Notification n WHERE n.toUser = :user AND n.isRead = false")
    long countUnreadNotifications(@Param("user") User user);
    void deleteByToUserAndFromUser(User toUser, User fromUser);
}
