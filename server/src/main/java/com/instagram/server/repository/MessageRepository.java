package com.instagram.server.repository;

import com.instagram.server.entity.Message;
import com.instagram.server.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface MessageRepository extends JpaRepository<Message, Long> {
    List<Message> findBySenderAndReceiverOrderByCreatedAtDesc(User sender, User receiver);
    
    @Query("SELECT m FROM Message m WHERE (m.sender = ?1 AND m.receiver = ?2) OR (m.sender = ?2 AND m.receiver = ?1) ORDER BY m.createdAt DESC")
    List<Message> findConversation(User user1, User user2);
    
    List<Message> findByReceiverAndReadFalse(User receiver);
    
    @Query("SELECT COUNT(m) FROM Message m WHERE m.receiver = ?1 AND m.read = false")
    long countUnreadMessages(User user);
} 