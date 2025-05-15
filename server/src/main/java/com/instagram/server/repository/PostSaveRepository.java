package com.instagram.server.repository;

import com.instagram.server.entity.Post;
import com.instagram.server.entity.PostSave;
import com.instagram.server.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface PostSaveRepository extends JpaRepository<PostSave, Long> {
    List<PostSave> findByUserOrderBySavedAtDesc(User user);
    Optional<PostSave> findByUserAndPost(User user, Post post);
    boolean existsByUserAndPost(User user, Post post);
} 