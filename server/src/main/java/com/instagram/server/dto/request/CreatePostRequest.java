package com.instagram.server.dto.request;

import lombok.Getter;
import lombok.Setter;

import java.util.ArrayList;
import java.util.List;

@Getter
@Setter
public class CreatePostRequest {
    private String content;
    private String caption;
    private List<String> imageBase64; // Can be base64 encoded images or URLs
    private List<String> taggedPeople; // List of tagged people usernames
    
    // Helper method to handle both single image or list of images
    public void setImage(String singleImage) {
        if (this.imageBase64 == null) {
            this.imageBase64 = new ArrayList<>();
        }
        this.imageBase64.add(singleImage);
    }
    
    // Helper method to handle tagged people
    public void addTaggedPerson(String username) {
        if (this.taggedPeople == null) {
            this.taggedPeople = new ArrayList<>();
        }
        this.taggedPeople.add(username);
    }
} 