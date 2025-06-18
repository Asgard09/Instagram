package com.instagram.server.service.Impl;

import com.instagram.server.entity.Follow;
import com.instagram.server.entity.User;
import com.instagram.server.repository.FollowRepository;
import com.instagram.server.repository.PostRepository;
import com.instagram.server.repository.UserRepository;
import com.instagram.server.service.FollowService;
import com.instagram.server.service.NotificationService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
public class FollowServiceImpl implements FollowService {
    private final FollowRepository followRepository;
    private final UserRepository userRepository;
    private final PostRepository postRepository;
    private final NotificationService notificationService;

    /**
     * Follow a user
     */
    @Transactional
    public Follow followUser(Long followeeId) {
        // Get current user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User follower = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get user to follow
        User followee = userRepository.findById((long) Math.toIntExact(followeeId))
                .orElseThrow(() -> new RuntimeException("User to follow not found"));
        
        // Check if already following
        if (follower.getUserId().equals(followee.getUserId())) {
            throw new RuntimeException("Cannot follow yourself");
        }

        notificationService.createFollowNotification(follower, followee);
        
        Optional<Follow> existingFollow = followRepository.findByFollowerAndFollowee(follower, followee);
        if (existingFollow.isPresent()) {
            // Already following, unfollow
            followRepository.delete(existingFollow.get());
            return null;
        } else {
            // Not following, create follow relationship
            Follow follow = new Follow(follower, followee);
            return followRepository.save(follow);
        }
    }

    /**
     * Unfollow a user
     */
    @Transactional
    public void unfollowUser(Long followeeId) {
        // Get current user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User follower = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get user to unfollow
        User followee = userRepository.findById((long) Math.toIntExact(followeeId))
                .orElseThrow(() -> new RuntimeException("User to unfollow not found"));
        
        // Delete follow relationship
        followRepository.deleteByFollowerAndFollowee(follower, followee);
    }

    /**
     * Check if user is following another user
     */
    public boolean isFollowing(Long followeeId) {
        // Get current user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User follower = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get user to check
        User followee = userRepository.findById((long) Math.toIntExact(followeeId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return followRepository.existsByFollowerAndFollowee(follower, followee);
    }

    /**
     * Check if a specific user is following another user
     */
    public boolean isUserFollowing(Long followerId, Long followeeId) {
        User follower = userRepository.findById((long) Math.toIntExact(followerId))
                .orElseThrow(() -> new RuntimeException("Follower user not found"));
        
        User followee = userRepository.findById((long) Math.toIntExact(followeeId))
                .orElseThrow(() -> new RuntimeException("Followee user not found"));
        
        return followRepository.existsByFollowerAndFollowee(follower, followee);
    }

    /**
     * Get followers to count for a user
     */
    public int getFollowersCount(Long userId) {
        User user = userRepository.findById((long) Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return followRepository.countByFollowee(user);
    }

    /**
     * Get the following count for a user
     */
    public int getFollowingCount(Long userId) {
        User user = userRepository.findById((long) Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return followRepository.countByFollower(user);
    }

    /**
     * Get posts to count for a user
     */
    public int getPostsCount(Long userId) {
        User user = userRepository.findById((long) Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return postRepository.countByUser(user);
    }

    /**
     * Get all followers of a user
     */
    public List<User> getFollowers(Long userId) {
        User user = userRepository.findById((long) Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return followRepository.findFollowersByUser(user);
    }

    /**
     * Get all users that a user is following
     */
    public List<User> getFollowing(Long userId) {
        User user = userRepository.findById((long) Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return followRepository.findFollowingByUser(user);
    }
}
