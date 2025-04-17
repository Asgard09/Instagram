package com.instagram.server.dto.response;

import java.util.Date;

public class LikeResponse {
    private Long likeId;
    private Long postId;
    private Long userId;
    private String username;
    private Date createdAt;
    
    // Getters and setters
    public Long getLikeId() {
        return likeId;
    }
    
    public void setLikeId(Long likeId) {
        this.likeId = likeId;
    }
    
    public Long getPostId() {
        return postId;
    }
    
    public void setPostId(Long postId) {
        this.postId = postId;
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
    
    public Date getCreatedAt() {
        return createdAt;
    }
    
    public void setCreatedAt(Date createdAt) {
        this.createdAt = createdAt;
    }
} 