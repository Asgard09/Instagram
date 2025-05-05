package com.instagram.server.repository;

import com.instagram.server.entity.Like;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface LikeRepository extends JpaRepository<Like, Long> {
    
    // Find likes by post
    List<Like> findByPost(Post post);
    
    // Find likes by user
    List<Like> findByUser(User user);
    
    // Find like by user and post (to check if a user has already liked a post)
    Optional<Like> findByUserAndPost(User user, Post post);
    
    // Count likes for a post
    Long countByPost(Post post);
    
    // Check if a user has liked a post
    boolean existsByUserAndPost(User user, Post post);
    
    // Delete a like by user and post
    void deleteByUserAndPost(User user, Post post);
    // Get users who liked a post
    @Query("SELECT l.user FROM Like l WHERE l.post.postId = :postId")
    List<User> findUsersByPostId(@Param("postId") Long postId);

}
