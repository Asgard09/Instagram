package com.instagram.server.repository;

import com.instagram.server.entity.Follow;
import com.instagram.server.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.Optional;

public interface FollowRepository extends JpaRepository<Follow, Follow.FollowId> {
    
    // Find if a user is following another user
    Optional<Follow> findByFollowerAndFollowee(User follower, User followee);
    
    // Check if a user is following another user
    boolean existsByFollowerAndFollowee(User follower, User followee);
    
    // Count followers of a user
    int countByFollowee(User followee);
    
    // Count users that a user is following
    int countByFollower(User follower);
    
    // Get all followers of a user
    @Query("SELECT f.follower FROM Follow f WHERE f.followee = :user")
    List<User> findFollowersByUser(@Param("user") User user);
    
    // Get all users that a user is following
    @Query("SELECT f.followee FROM Follow f WHERE f.follower = :user")
    List<User> findFollowingByUser(@Param("user") User user);
    
    // Delete a follow relationship
    void deleteByFollowerAndFollowee(User follower, User followee);
}
