package com.instagram.server.entity;

import jakarta.persistence.*;
import lombok.*;

import java.io.Serializable;
import java.time.LocalDateTime;

@Entity
@Getter
@Setter
@Table(name = "follows")
@IdClass(Follow.FollowId.class)
/*Note
* JPA (Jakarta Persistence API) requires entities to have a default (no-argument) constructor
* First creates an instance of the entity class using the no-args constructor
* Postman just receives the JSON response and displays it
* Flutter app needs to deserialize the JSON into Dart objects
*/
@NoArgsConstructor
@SuppressWarnings("unused")
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
