package com.instagram.server.controller;

import com.instagram.server.dto.response.LikeResponse;
import com.instagram.server.entity.Like;
import com.instagram.server.entity.User;
import com.instagram.server.service.LikeService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/likes")
@CrossOrigin(origins = "*", maxAge = 3600)
public class LikeController {
    
    private final LikeService likeService;
    
    public LikeController(LikeService likeService) {
        this.likeService = likeService;
    }
    
    /**
     * Like a post
     */
    @PostMapping("/post/{postId}")
    public ResponseEntity<LikeResponse> likePost(@PathVariable Long postId) {
        Like like = likeService.likePost(postId);
        return ResponseEntity.ok(convertToLikeResponse(like));
    }
    
    /**
     * Unlike a post
     */
    @DeleteMapping("/post/{postId}")
    public ResponseEntity<?> unlikePost(@PathVariable Long postId) {
        likeService.unlikePost(postId);
        return ResponseEntity.ok().build();
    }
    
    /**
     * Check if current user has liked a post
     */
    @GetMapping("/check/post/{postId}")
    public ResponseEntity<Map<String, Boolean>> checkLikeStatus(@PathVariable Long postId) {
        boolean hasLiked = likeService.hasUserLikedPost(postId);
        Map<String, Boolean> response = new HashMap<>();
        response.put("liked", hasLiked);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Get number of likes for a post
     */
    @GetMapping("/count/post/{postId}")
    public ResponseEntity<Map<String, Long>> getLikeCount(@PathVariable Long postId) {
        Long count = likeService.getLikeCount(postId);
        Map<String, Long> response = new HashMap<>();
        response.put("count", count);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Get users who liked a post
     */
    @GetMapping("/users/post/{postId}")
    public ResponseEntity<List<Map<String, Object>>> getUsersWhoLikedPost(@PathVariable Long postId) {
        List<User> users = likeService.getUsersWhoLikedPost(postId);
        
        // Map users to a simplified format
        List<Map<String, Object>> userResponses = users.stream()
                .map(user -> {
                    Map<String, Object> userResponse = new HashMap<>();
                    userResponse.put("userId", user.getUserId());
                    userResponse.put("username", user.getUsername());
                    userResponse.put("profilePicture", user.getProfilePicture());
                    return userResponse;
                })
                .collect(Collectors.toList());
        
        return ResponseEntity.ok(userResponses);
    }
    
    /**
     * Convert Like entity to response DTO
     */
    private LikeResponse convertToLikeResponse(Like like) {
        LikeResponse response = new LikeResponse();
        response.setLikeId(like.getLikeId());
        response.setPostId(like.getPost().getPostId());
        response.setUserId(like.getUser().getUserId());
        response.setUsername(like.getUser().getUsername());
        response.setCreatedAt(like.getCreatedAt());
        return response;
    }
}
