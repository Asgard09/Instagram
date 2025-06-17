package com.instagram.server.entity;

import com.instagram.server.base.TypeOfNotification;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;

@Entity
@NoArgsConstructor
@AllArgsConstructor
@Getter
@Setter
@Builder
@Table(name = "notification")
public class Notification {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private TypeOfNotification type;

    @Column(nullable = false, length = 500)
    private String message;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "from_user_id", nullable = false)
    private User fromUser;

    @ManyToOne(fetch = FetchType.EAGER)
    /*Note: to_user_id --> name of a foreign key*/
    @JoinColumn(name = "to_user_id", nullable = false)
    private User toUser;

    @ManyToOne(fetch = FetchType.EAGER)
    @JoinColumn(name = "post_id")
    private Post post;

    @Column(nullable = false)
    private LocalDateTime createdAt;

    @Column(nullable = false)
    private boolean isRead = false;

    @Column
    private LocalDateTime readAt;

    @Column
    private LocalDateTime deliveredAt;
}
