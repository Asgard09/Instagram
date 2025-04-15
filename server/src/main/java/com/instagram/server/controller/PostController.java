package com.instagram.server.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.instagram.server.dto.request.CreatePostRequest;
import com.instagram.server.entity.Post;
import com.instagram.server.service.PostService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/posts")
@CrossOrigin(origins = "*", maxAge = 3600)
public class PostController {

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @PostMapping
    public ResponseEntity<?> createPost(@RequestBody Map<String, Object> requestMap) {
        try {
            // Log the raw request to debug
            System.out.println("Raw request: " + requestMap);
            
            ObjectMapper mapper = new ObjectMapper();
            CreatePostRequest request = new CreatePostRequest();
            
            // Extract caption/content
            if (requestMap.containsKey("caption")) {
                request.setCaption((String) requestMap.get("caption"));
            }
            
            if (requestMap.containsKey("content")) {
                request.setContent((String) requestMap.get("content"));
            }
            
            // Handle different image formats
            if (requestMap.containsKey("imageBase64")) {
                Object imageData = requestMap.get("imageBase64");
                List<String> images = new ArrayList<>();
                
                if (imageData instanceof String) {
                    // Single image as string
                    images.add((String) imageData);
                } else if (imageData instanceof List) {
                    // List of images
                    for (Object img : (List<?>) imageData) {
                        if (img instanceof String) {
                            images.add((String) img);
                        }
                    }
                }
                
                request.setImageBase64(images);
            } else if (requestMap.containsKey("imageUrl")) {
                // Handle imageUrl field
                String imageUrl = (String) requestMap.get("imageUrl");
                List<String> images = new ArrayList<>();
                images.add(imageUrl);
                request.setImageBase64(images);
            }
            
            // Log the processed request
            System.out.println("Creating post with caption: " + request.getCaption());
            if (request.getImageBase64() != null) {
                System.out.println("Number of images: " + request.getImageBase64().size());
            } else {
                System.out.println("No images provided");
            }
            
            Post createdPost = postService.createPost(request);
            return ResponseEntity.ok(createdPost);
        } catch (IOException e) {
            System.err.println("Error processing image: " + e.getMessage());
            return ResponseEntity.status(500)
                    .body("Error processing image: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("Error creating post: " + e.getMessage());
            e.printStackTrace();
            return ResponseEntity.status(500)
                    .body("Error creating post: " + e.getMessage());
        }
    }

    @GetMapping
    public ResponseEntity<List<Post>> getAllPosts() {
        return ResponseEntity.ok(postService.getAllPosts());
    }

    @GetMapping("/user/{username}")
    public ResponseEntity<List<Post>> getUserPosts(@PathVariable String username) {
        return ResponseEntity.ok(postService.getUserPosts(username));
    }

    @GetMapping("/feed")
    public ResponseEntity<List<Post>> getNewsFeed() {
        return ResponseEntity.ok(postService.getNewsFeed());
    }
}
