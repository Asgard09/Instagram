package com.instagram.server.entity;

import jakarta.persistence.*;
import lombok.Data;

import java.time.LocalDateTime;

@Entity
@Data
@Table(name = "follows")
public class Follow {
    @Id
    @ManyToOne
    @JoinColumn(name = "FollowerID", nullable = false)
    private User follower;

    @Id
    @ManyToOne
    @JoinColumn(name = "FolloweeID", nullable = false)
    private User followee;

    @Column(name = "CreatedAt", nullable = false, updatable = false, columnDefinition = "TIMESTAMP DEFAULT CURRENT_TIMESTAMP")
    private LocalDateTime createdAt = LocalDateTime.now();

    public Follow() {}

    public Follow(User follower, User followee) {
        this.follower = follower;
        this.followee = followee;
    }
}
