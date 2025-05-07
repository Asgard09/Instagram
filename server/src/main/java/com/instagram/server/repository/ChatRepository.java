package com.instagram.server.repository;

import com.instagram.server.entity.Chat;
import com.instagram.server.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ChatRepository extends JpaRepository<Chat, Long> {
    @Query("SELECT c FROM Chat c WHERE (c.user1 = ?1 AND c.user2 = ?2) OR (c.user1 = ?2 AND c.user2 = ?1)")
    Optional<Chat> findChatBetweenUsers(User user1, User user2);
    
    @Query("SELECT c FROM Chat c WHERE c.user1 = ?1 OR c.user2 = ?1 ORDER BY c.updatedAt DESC")
    List<Chat> findUserChats(User user);
} 