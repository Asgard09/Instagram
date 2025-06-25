package com.instagram.server.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

import java.util.Date;

@Builder
@Getter
@Setter
public class LikeResponse {
    // Getters and setters
    private Long likeId;
    private Long postId;
    private Long userId;
    private String username;
    private Date createdAt;

}