package com.instagram.server.dto.response;

import lombok.Builder;
import lombok.Setter;

import java.util.Date;
import java.util.List;

@Builder
@Setter
public class PostResponse {
    // Getters and setters
    private Long postId;
    private String content;
    private String caption;
    private String displayCaption; // Caption with "with tagged people" format
    private Date createdAt;
    private List<String> imageUrls;
    private Long userId;
    private String username;
    private List<String> taggedPeople;
    private boolean saved; // Indicates if the post is saved by the current user
}