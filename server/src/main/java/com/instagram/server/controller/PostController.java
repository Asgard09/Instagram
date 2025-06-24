package com.instagram.server.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.instagram.server.dto.request.CreatePostRequest;
import com.instagram.server.dto.response.PostResponse;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.PostSave;
import com.instagram.server.service.PostService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/posts")
@CrossOrigin(origins = "*", maxAge = 3600)
@SuppressWarnings("unused")
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

            // Extract tagged people
            if (requestMap.containsKey("taggedPeople")) {
                Object taggedData = requestMap.get("taggedPeople");
                List<String> taggedPeople = new ArrayList<>();

                if (taggedData instanceof List) {
                    // List of tagged people
                    for (Object person : (List<?>) taggedData) {
                        if (person instanceof String) {
                            taggedPeople.add((String) person);
                        }
                    }
                    request.setTaggedPeople(taggedPeople);
                }

                // Log tagged people
                System.out.println("Tagged people: " + taggedPeople);
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

    @PostMapping("/save/{postId}/{userId}")
    public ResponseEntity<?> savePost(@PathVariable Long postId, @PathVariable Long userId){
        try {
            postService.savePost(postId, userId);
            return ResponseEntity.ok(Map.of("message", "Post saved successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    @DeleteMapping("/un-save/{postId}/{userId}")
    public ResponseEntity<?> unsavePost(@PathVariable Long postId, @PathVariable Long userId){
        try {
            postService.unSavePost(postId, userId);
            return ResponseEntity.ok(Map.of("message", "Post unsaved successfully"));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }
    
    @GetMapping("/is-saved/{postId}/{userId}")
    public ResponseEntity<?> isPostSaved(@PathVariable Long postId, @PathVariable Long userId){
        try {
            boolean isSaved = postService.isPostSaved(postId, userId);
            return ResponseEntity.ok(Map.of("saved", isSaved));
        } catch (Exception e) {
            return ResponseEntity.status(500).body(Map.of("error", e.getMessage()));
        }
    }

    @GetMapping("/getAll/{userId}")
    public ResponseEntity<List<PostResponse>> getAllPostSaved(@PathVariable Long userId){
        try {
            List<PostSave> postSaves = postService.getAllPostSavedByUser(userId);
            if (postSaves == null || postSaves.isEmpty()) {
                return ResponseEntity.ok(new ArrayList<>());
            }
            
            // Convert PostSave objects to PostResponse objects
            List<PostResponse> postResponses = postSaves.stream()
                    .map(postSave -> convertToPostResponse(postSave.getPost()))
                    .collect(Collectors.toList());
            
            return ResponseEntity.ok(postResponses);
        } catch (Exception e) {
            log.error("Error getting saved posts for user {}: {}", userId, e.getMessage());
            return ResponseEntity.status(500).body(new ArrayList<>());
        }
    }
    
    // Helper method to convert Post to PostResponse
    private PostResponse convertToPostResponse(Post post) {
        PostResponse response = PostResponse.builder()
                .postId(post.getPostId())
                .caption(post.getCaption())
                .content(post.getContent())
                .createdAt(post.getCreatedAt())
                .imageUrls(post.getImageUrls())
                .taggedPeople(post.getTaggedPeople())
                .build();
        
        // Extract user information
        extractUserInfo(response, post);
        
        // Create display caption with "@username" format instead of "with username"
        displayCaption(response, post);
        
        return response;
    }

    private void extractUserInfo(PostResponse response, Post post){
        if (post.getUser() != null) {
            response.setUserId(post.getUser().getUserId());
            response.setUsername(post.getUser().getUsername());
        }
    }

    private void displayCaption(PostResponse response, Post post){
        if (post.getTaggedPeople() != null && !post.getTaggedPeople().isEmpty()) {
            StringBuilder displayCaption = new StringBuilder(post.getCaption() != null ? post.getCaption() : "");

            // Add space if the caption doesn't end with a space
            if (!displayCaption.toString().isEmpty() && !displayCaption.toString().endsWith(" ")) {
                displayCaption.append(" ");
            }

            // Get the first tagged person
            String firstTagged = post.getTaggedPeople().get(0);

            // Add "@username" to the caption
            displayCaption.append("@").append(firstTagged);

            // If there are more than some tagged people, add "and X others"
            if (post.getTaggedPeople().size() > 1) {
                int othersCount = post.getTaggedPeople().size() - 1;
                displayCaption.append(" and ").append(othersCount).append(othersCount > 1 ? " others" : " other");
            }

            response.setDisplayCaption(displayCaption.toString());
        } else {
            // If no tagged people, display caption is the same as regular caption
            response.setDisplayCaption(post.getCaption());
        }
    }
}
