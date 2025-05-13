package com.instagram.server.repository;

import com.instagram.server.entity.Comment;
import com.instagram.server.entity.Post;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface CommentRepository extends JpaRepository<Comment, Long> {
    List<Comment> findByPostOrderByCreatedAtDesc(Post post);
    Long countByPost(Post post);
} 