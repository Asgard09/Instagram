package com.instagram.server.service;

import com.instagram.server.entity.Like;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;
import com.instagram.server.repository.LikeRepository;
import com.instagram.server.repository.PostRepository;
import com.instagram.server.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;
import java.util.Optional;

@Service
public class LikeService {
    
    private final LikeRepository likeRepository;
    private final PostRepository postRepository;
    private final UserRepository userRepository;

    public LikeService(LikeRepository likeRepository, PostRepository postRepository, UserRepository userRepository) {
        this.likeRepository = likeRepository;
        this.postRepository = postRepository;
        this.userRepository = userRepository;
    }
    
    /**
     * Like a post
     */
    @Transactional
    public Like likePost(Long postId) {
        // Get current user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get post
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        
        // Check if user already liked the post
        Optional<Like> existingLike = likeRepository.findByUserAndPost(user, post);
        if (existingLike.isPresent()) {
            return existingLike.get(); // Already liked
        }
        
        // Create new like
        Like like = new Like();
        like.setUser(user);
        like.setPost(post);
        like.setCreatedAt(new Date());
        
        return likeRepository.save(like);
    }
    
    /**
     * Unlike a post
     */
    @Transactional
    public void unlikePost(Long postId) {
        // Get current user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get post
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        
        // Delete like if exists
        likeRepository.deleteByUserAndPost(user, post);
    }
    
    /**
     * Check if user has liked a post
     */
    public boolean hasUserLikedPost(Long postId) {
        // Get current user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get post
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        
        return likeRepository.existsByUserAndPost(user, post);
    }
    
    /**
     * Get like count for a post
     */
    public Long getLikeCount(Long postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        
        return likeRepository.countByPost(post);
    }
    
    /**
     * Get users who liked a post
     */
    public List<User> getUsersWhoLikedPost(Long postId) {
        return likeRepository.findUsersByPostId(postId);
    }
}
