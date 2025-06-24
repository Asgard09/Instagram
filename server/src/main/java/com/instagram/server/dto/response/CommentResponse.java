package com.instagram.server.dto.response;

import lombok.Builder;
import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
@Builder
public class CommentResponse {
    private Long commentId;
    private String comment;
    private String createdAt;
    private Long postId;
    private Long userId;
    private String username;
    private String profilePicture;
}