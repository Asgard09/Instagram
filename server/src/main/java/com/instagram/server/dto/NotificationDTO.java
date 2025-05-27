package com.instagram.server.dto;

import lombok.*;

import java.net.Proxy;
import java.time.LocalDateTime;

@Getter
@Setter
@Builder
@RequiredArgsConstructor
@AllArgsConstructor
public class NotificationDTO {
    private String type; // "LIKE", "COMMENT", "FOLLOW", etc.
    private String message;
    private Long fromUserId;
    private String fromUsername;
    private String fromUserProfilePicture;
    private Long postId;
    private String postImageUrl;
    private LocalDateTime createdAt;
    private boolean isRead;

}
