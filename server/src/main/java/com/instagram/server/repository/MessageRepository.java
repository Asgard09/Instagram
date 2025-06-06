package com.instagram.server.repository;

import com.instagram.server.entity.Message;
import com.instagram.server.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;


@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {
    @Query("SELECT COUNT(m) FROM Message m WHERE m.receiver = ?1 AND m.read = false")
    long countUnreadMessages(User user);
} 