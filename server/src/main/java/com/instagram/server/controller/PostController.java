package com.instagram.server.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.instagram.server.dto.request.CreatePostRequest;
import com.instagram.server.dto.response.PostResponse;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;
import com.instagram.server.service.PostService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

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
            return ResponseEntity.ok(convertToPostResponse(createdPost));
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
    public ResponseEntity<List<PostResponse>> getAllPosts() {
        List<Post> posts = postService.getAllPosts();
        List<PostResponse> postResponses = posts.stream()
                .map(this::convertToPostResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(postResponses);
    }

    @GetMapping("/user/{username}")
    public ResponseEntity<List<PostResponse>> getUserPosts(@PathVariable String username) {
        List<Post> posts = postService.getUserPosts(username);
        List<PostResponse> postResponses = posts.stream()
                .map(this::convertToPostResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(postResponses);
    }

    @GetMapping("/feed")
    public ResponseEntity<List<PostResponse>> getNewsFeed() {
        List<Post> posts = postService.getNewsFeed();
        List<PostResponse> postResponses = posts.stream()
                .map(this::convertToPostResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(postResponses);
    }
    
    // Helper method to convert Post to PostResponse
    private PostResponse convertToPostResponse(Post post) {
        PostResponse response = new PostResponse();
        response.setPostId(post.getPostId());
        response.setCaption(post.getCaption());
        response.setContent(post.getContent());
        response.setCreatedAt(post.getCreatedAt());
        response.setImageUrls(post.getImageUrls());
        
        // Extract user information
        if (post.getUser() != null) {
            response.setUserId(post.getUser().getUserId());
            response.setUsername(post.getUser().getUsername());
        }
        
        return response;
    }
}
