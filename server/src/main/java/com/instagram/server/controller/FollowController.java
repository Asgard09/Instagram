package com.instagram.server.controller;

import com.instagram.server.dto.response.FollowResponse;
import com.instagram.server.entity.Follow;
import com.instagram.server.entity.User;
import com.instagram.server.service.FollowService;
import com.instagram.server.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/follows")
@CrossOrigin(origins = "*", maxAge = 3600)
@SuppressWarnings("unused")
public class FollowController {
    
    private final FollowService followService;
    private final UserService userService;
    
    public FollowController(FollowService followService, UserService userService) {
        this.followService = followService;
        this.userService = userService;
    }
    
    /**
     * Follow or unfollow a user
     */
    @PostMapping("/{userId}")
    public ResponseEntity<?> toggleFollow(@PathVariable Long userId) {
        Follow follow = followService.followUser(userId);
        
        Map<String, Object> response = new HashMap<>();
        if (follow == null) {
            // User was unfollowed
            response.put("status", "unfollowed");
            response.put("followersCount", followService.getFollowersCount(userId));
        } else {
            // User was followed
            response.put("status", "followed");
            response.put("followersCount", followService.getFollowersCount(userId));
        }
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * Unfollow a user
     */
    @DeleteMapping("/{userId}")
    public ResponseEntity<?> unfollowUser(@PathVariable Long userId) {
        followService.unfollowUser(userId);
        return ResponseEntity.ok().build();
    }
    
    /**
     * Check if the current user is following a user
     */
    @GetMapping("/check/{userId}")
    public ResponseEntity<Map<String, Boolean>> checkFollowStatus(@PathVariable Long userId) {
        boolean isFollowing = followService.isFollowing(userId);
        Map<String, Boolean> response = new HashMap<>();
        response.put("following", isFollowing);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Get user information with follow counts
     */
    @GetMapping("/user/{userId}")
    public ResponseEntity<FollowResponse> getUserWithFollowCounts(@PathVariable Long userId) {
        User user = userService.getUserById(userId);
        FollowResponse response = convertToFollowResponse(user);
        
        return ResponseEntity.ok(response);
    }
    
    /**
     * Get followers count
     */
    @GetMapping("/followers/count/{userId}")
    public ResponseEntity<Map<String, Integer>> getFollowersCount(@PathVariable Long userId) {
        int count = followService.getFollowersCount(userId);
        Map<String, Integer> response = new HashMap<>();
        response.put("count", count);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Get the following count
     */
    @GetMapping("/following/count/{userId}")
    public ResponseEntity<Map<String, Integer>> getFollowingCount(@PathVariable Long userId) {
        int count = followService.getFollowingCount(userId);
        Map<String, Integer> response = new HashMap<>();
        response.put("count", count);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Get posts count
     */
    @GetMapping("/posts/count/{userId}")
    public ResponseEntity<Map<String, Integer>> getPostsCount(@PathVariable Long userId) {
        int count = followService.getPostsCount(userId);
        Map<String, Integer> response = new HashMap<>();
        response.put("count", count);
        return ResponseEntity.ok(response);
    }
    
    /**
     * Get followers
     */
    @GetMapping("/followers/{userId}")
    public ResponseEntity<List<FollowResponse>> getFollowers(@PathVariable Long userId) {
        List<User> followers = followService.getFollowers(userId);
        List<FollowResponse> response = followers.stream()
                .map(this::convertToFollowResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }
    
    /**
     * Get following
     */
    @GetMapping("/following/{userId}")
    public ResponseEntity<List<FollowResponse>> getFollowing(@PathVariable Long userId) {
        List<User> following = followService.getFollowing(userId);
        List<FollowResponse> response = following.stream()
                .map(this::convertToFollowResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(response);
    }
    
    /**
     * Convert User entity to FollowResponse DTO
     */
    private FollowResponse convertToFollowResponse(User user) {
        FollowResponse response = new FollowResponse();
        response.setUserId(user.getUserId());
        response.setUsername(user.getUsername());
        response.setProfilePicture(user.getProfilePicture());
        response.setFollowing(followService.isFollowing(user.getUserId()));
        response.setFollowersCount(followService.getFollowersCount(user.getUserId()));
        response.setFollowingCount(followService.getFollowingCount(user.getUserId()));
        response.setPostsCount(followService.getPostsCount(user.getUserId()));
        return response;
    }
}
