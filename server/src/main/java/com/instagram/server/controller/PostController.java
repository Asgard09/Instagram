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

@RestController
@RequestMapping("/api/posts")
public class PostController {

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @PostMapping
    public ResponseEntity<?> createPost(@RequestBody String requestBody) {
        try {
            // Log the raw request to debug
            System.out.println("Raw request body: " + requestBody);
            
            // Check if it's a simple blob URL string (not a proper JSON)
            if (requestBody.startsWith("\"blob:") || requestBody.startsWith("\"http")) {
                // Create a post with just the URL as image
                String imageUrl = requestBody.replaceAll("^\"|\"$", ""); // Remove quotes
                CreatePostRequest request = new CreatePostRequest();
                List<String> images = new ArrayList<>();
                images.add(imageUrl);
                request.setImageBase64(images);
                
                Post createdPost = postService.createPost(request);
                return ResponseEntity.ok(createdPost);
            } else {
                // Normal JSON processing through ObjectMapper
                ObjectMapper mapper = new ObjectMapper();
                CreatePostRequest request;
                
                try {
                    request = mapper.readValue(requestBody, CreatePostRequest.class);
                } catch (Exception ex) {
                    // Try to handle case where imageBase64 is a string instead of array
                    try {
                        JsonNode node = mapper.readTree(requestBody);
                        request = new CreatePostRequest();
                        
                        if (node.has("content")) {
                            request.setContent(node.get("content").asText());
                        }
                        
                        if (node.has("caption")) {
                            request.setCaption(node.get("caption").asText());
                        }
                        
                        if (node.has("imageBase64")) {
                            JsonNode imageNode = node.get("imageBase64");
                            List<String> images = new ArrayList<>();
                            
                            if (imageNode.isTextual()) {
                                // Single string image
                                images.add(imageNode.asText());
                            } else if (imageNode.isArray()) {
                                // Array of images
                                for (JsonNode img : imageNode) {
                                    images.add(img.asText());
                                }
                            }
                            
                            request.setImageBase64(images);
                        }
                    } catch (Exception e) {
                        throw new RuntimeException("Invalid request format: " + e.getMessage());
                    }
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
            }
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

    @GetMapping("/user/{username}")
    public ResponseEntity<List<Post>> getUserPosts(@PathVariable String username) {
        return ResponseEntity.ok(postService.getUserPosts(username));
    }

    @GetMapping("/feed")
    public ResponseEntity<List<Post>> getNewsFeed() {
        return ResponseEntity.ok(postService.getNewsFeed());
    }
}
