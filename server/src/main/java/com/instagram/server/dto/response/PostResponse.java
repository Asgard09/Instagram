package com.instagram.server.dto.response;

import java.util.Date;
import java.util.List;

public class PostResponse {
    private Long postId;
    private String content;
    private String caption;
    private String displayCaption; // Caption with "with tagged people" format
    private Date createdAt;
    private List<String> imageUrls;
    private Long userId;
    private String username;
    private List<String> taggedPeople;

    // Getters and setters
    public Long getPostId() {
        return postId;
    }

    public void setPostId(Long postId) {
        this.postId = postId;
    }

    public String getContent() {
        return content;
    }

    public void setContent(String content) {
        this.content = content;
    }

    public String getCaption() {
        return caption;
    }

    public void setCaption(String caption) {
        this.caption = caption;
    }
    
    public String getDisplayCaption() {
        return displayCaption;
    }

    public void setDisplayCaption(String displayCaption) {
        this.displayCaption = displayCaption;
    }

    public Date getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }

    public List<String> getImageUrls() {
        return imageUrls;
    }

    public void setImageUrls(List<String> imageUrls) {
        this.imageUrls = imageUrls;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public String getUsername() {
        return username;
    }

    public void setUsername(String username) {
        this.username = username;
    }
    
    public List<String> getTaggedPeople() {
        return taggedPeople;
    }

    public void setTaggedPeople(List<String> taggedPeople) {
        this.taggedPeople = taggedPeople;
    }
} 