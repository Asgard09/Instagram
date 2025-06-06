package com.instagram.server.entity;

import jakarta.persistence.*;
import lombok.Data;
import lombok.EqualsAndHashCode;
import lombok.NoArgsConstructor;

import java.io.Serializable;
import java.time.LocalDateTime;

@Entity
@Data
@Table(name = "follows")
@IdClass(Follow.FollowId.class)
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


    public Follow(User follower, User followee) {
        this.follower = follower;
        this.followee = followee;
    }

    @Data
    @NoArgsConstructor
    @EqualsAndHashCode
    /*Need to review*/
    public static class FollowId implements Serializable {
        private Long follower;
        private Long followee;
        
        public FollowId(Long follower, Long followee) {
            this.follower = follower;
            this.followee = followee;
        }
    }
}
