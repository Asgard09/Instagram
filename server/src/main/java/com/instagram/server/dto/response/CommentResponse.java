package com.instagram.server.dto.response;

import lombok.Getter;
import lombok.Setter;

@Setter
@Getter
public class CommentResponse {
    private Long commentId;
    private String comment;
    private String createdAt;
    private Long postId;
    private Long userId;
    private String username;
    private String profilePicture;

}