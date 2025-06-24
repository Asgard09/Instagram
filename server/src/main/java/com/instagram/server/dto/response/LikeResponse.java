package com.instagram.server.dto.response;

import lombok.Builder;

import java.util.Date;

@Builder
public class LikeResponse {
    // Getters and setters
    private Long likeId;
    private Long postId;
    private Long userId;
    private String username;
    private Date createdAt;

}