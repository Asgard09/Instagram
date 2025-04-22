package com.instagram.server.service;

import com.instagram.server.entity.Follow;
import com.instagram.server.entity.User;
import com.instagram.server.repository.FollowRepository;
import com.instagram.server.repository.PostRepository;
import com.instagram.server.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

@Service
public class FollowService {

    private final FollowRepository followRepository;
    private final UserRepository userRepository;
    private final PostRepository postRepository;

    public FollowService(FollowRepository followRepository, UserRepository userRepository, PostRepository postRepository) {
        this.followRepository = followRepository;
        this.userRepository = userRepository;
        this.postRepository = postRepository;
    }

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
        User followee = userRepository.findById(Math.toIntExact(followeeId))
                .orElseThrow(() -> new RuntimeException("User to follow not found"));
        
        // Check if already following
        if (follower.getUserId().equals(followee.getUserId())) {
            throw new RuntimeException("Cannot follow yourself");
        }
        
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
        User followee = userRepository.findById(Math.toIntExact(followeeId))
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
        User followee = userRepository.findById(Math.toIntExact(followeeId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return followRepository.existsByFollowerAndFollowee(follower, followee);
    }

    /**
     * Check if specific user is following another user
     */
    public boolean isUserFollowing(Long followerId, Long followeeId) {
        User follower = userRepository.findById(Math.toIntExact(followerId))
                .orElseThrow(() -> new RuntimeException("Follower user not found"));
        
        User followee = userRepository.findById(Math.toIntExact(followeeId))
                .orElseThrow(() -> new RuntimeException("Followee user not found"));
        
        return followRepository.existsByFollowerAndFollowee(follower, followee);
    }

    /**
     * Get followers count for a user
     */
    public int getFollowersCount(Long userId) {
        User user = userRepository.findById(Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return followRepository.countByFollowee(user);
    }

    /**
     * Get following count for a user
     */
    public int getFollowingCount(Long userId) {
        User user = userRepository.findById(Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return followRepository.countByFollower(user);
    }

    /**
     * Get posts count for a user
     */
    public int getPostsCount(Long userId) {
        User user = userRepository.findById(Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return postRepository.countByUser(user);
    }

    /**
     * Get all followers of a user
     */
    public List<User> getFollowers(Long userId) {
        User user = userRepository.findById(Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return followRepository.findFollowersByUser(user);
    }

    /**
     * Get all users that a user is following
     */
    public List<User> getFollowing(Long userId) {
        User user = userRepository.findById(Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return followRepository.findFollowingByUser(user);
    }
}
