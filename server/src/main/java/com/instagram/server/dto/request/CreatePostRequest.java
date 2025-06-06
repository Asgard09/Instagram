package com.instagram.server.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.util.List;

@Getter
@Setter
public class CreatePostRequest {
    private String content;
    private String caption;
    private List<String> imageBase64; // Can be base64 encoded images or URLs
    private List<String> taggedPeople; // List of tagged people usernames
} 