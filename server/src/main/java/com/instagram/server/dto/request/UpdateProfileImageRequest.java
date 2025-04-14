package com.instagram.server.dto.request;

import lombok.Getter;
import lombok.Setter;

@Getter
@Setter
public class UpdateProfileImageRequest {
    private String imageBase64; // Can be base64 encoded image or URL
} 