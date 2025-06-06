package com.instagram.server.controller;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.instagram.server.dto.request.UpdateBioRequest;
import com.instagram.server.dto.request.UpdateProfileImageRequest;
import com.instagram.server.dto.request.UpdateUserRequest;
import com.instagram.server.entity.User;
import com.instagram.server.service.UserService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;

import java.io.IOException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@RestController
@RequestMapping("/api/users")
@CrossOrigin(origins = "*", maxAge = 3600)
@SuppressWarnings("unused")
public class UserController {
    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @PutMapping("/bio")
    public ResponseEntity<User> updateBio(@RequestBody UpdateBioRequest request) {
        User updatedUser = userService.updateBio(request);
        return ResponseEntity.ok(updatedUser);
    }

    @PutMapping("/profile")
    public ResponseEntity<User> updateProfile(@RequestBody UpdateUserRequest request) {
        User updatedUser = userService.updateUserInfo(request);
        return ResponseEntity.ok(updatedUser);
    }

    @PutMapping("/profile-image")
    public ResponseEntity<?> updateProfileImage(@RequestBody String requestBody) {
        try {
            // Log the raw request
            System.out.println("Raw profile image request: " + requestBody);
            
            // Handle a direct URL string
            if (requestBody.startsWith("\"blob:") || requestBody.startsWith("\"http")) {
                String imageUrl = requestBody.replaceAll("^\"|\"$", ""); // Remove quotes
                UpdateProfileImageRequest request = new UpdateProfileImageRequest();
                request.setImageBase64(imageUrl);
                
                User updatedUser = userService.updateProfileImage(request);
                return ResponseEntity.ok(updatedUser);
            } else {
                // Parse JSON request
                ObjectMapper mapper = new ObjectMapper();
                UpdateProfileImageRequest request;
                
                try {
                    request = mapper.readValue(requestBody, UpdateProfileImageRequest.class);
                } catch (Exception ex) {
                    // Try alternate parsing if normal deserialization fails
                    try {
                        JsonNode node = mapper.readTree(requestBody);
                        request = new UpdateProfileImageRequest();
                        
                        if (node.has("imageBase64")) {
                            request.setImageBase64(node.get("imageBase64").asText());
                        }
                    } catch (Exception e) {
                        throw new RuntimeException("Invalid request format: " + e.getMessage());
                    }
                }
                
                // Log the processed request
                System.out.println("Updating profile image: " + 
                    (request.getImageBase64() != null ? 
                        request.getImageBase64().substring(0, Math.min(50, request.getImageBase64().length())) + "..." : "null"));
                
                User updatedUser = userService.updateProfileImage(request);
                return ResponseEntity.ok(updatedUser);
            }
        } catch (IOException e) {
            System.err.println("Error processing profile image: " + e.getMessage());
            return ResponseEntity.status(500)
                    .body("Error processing profile image: " + e.getMessage());
        } catch (Exception e) {
            System.err.println("Error updating profile: " + e.getMessage());
            log.error("Error updating profile: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body("Error updating profile: " + e.getMessage());
        }
    }

    @GetMapping("/me")
    public ResponseEntity<User> getCurrentUser() {
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userService.getUserByUsername(userDetails.getUsername());
        return ResponseEntity.ok(user);
    }

    @GetMapping("/by-username/{username}")
    public ResponseEntity<?> getUserByUsername(@PathVariable String username) {
        try {
            User user = userService.getUserByUsername(username);
            if (user != null) {
                // Create a clean copy without sensitive info
                User cleanUser = new User();
                cleanUser.setUserId(user.getUserId());
                cleanUser.setUsername(user.getUsername());
                cleanUser.setName(user.getName());
                cleanUser.setBio(user.getBio());
                cleanUser.setProfilePicture(user.getProfilePicture());
                cleanUser.setGender(user.getGender());
                cleanUser.setCreatedAt(user.getCreatedAt());
                // Don't include posts to avoid potential JSON issues
                
                return ResponseEntity.ok(cleanUser);
            } else {
                return ResponseEntity.notFound().build();
            }
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Error retrieving user: " + e.getMessage());
        }
    }

    @GetMapping("/followers")
    public ResponseEntity<?> getFollowersForTagging() {
        try {
            UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
            List<User> followers = userService.getFollowersForTagging(userDetails.getUsername());
            
            // Transform to a simpler representation for tagging
            List<Map<String, Object>> tagUsers = followers.stream()
                .map(follower -> {
                    Map<String, Object> userMap = new HashMap<>();
                    userMap.put("userId", follower.getUserId());
                    userMap.put("username", follower.getUsername());
                    userMap.put("name", follower.getName());
                    userMap.put("profilePicture", follower.getProfilePicture());
                    return userMap;
                })
                .collect(Collectors.toList());
            
            return ResponseEntity.ok(tagUsers);
        } catch (Exception e) {
            System.err.println("Error getting followers: " + e.getMessage());
            log.error("Error getting followers: {}", e.getMessage());
            return ResponseEntity.status(500)
                    .body("Error getting followers: " + e.getMessage());
        }
    }

    @GetMapping("/search")
    public ResponseEntity<List<Map<String, Object>>> searchUsers(@RequestParam String query) {
        try {
            System.out.println("Search request received with query: " + query);
            List<User> users = userService.searchUsers(query);
            System.out.println("Search results count: " + users.size());
            
            List<Map<String, Object>> results = users.stream()
                .map(user -> {
                    Map<String, Object> userMap = new HashMap<>();
                    userMap.put("userId", user.getUserId());
                    userMap.put("username", user.getUsername());
                    userMap.put("name", user.getName());
                    userMap.put("profilePicture", user.getProfilePicture());
                    return userMap;
                })
                .collect(Collectors.toList());
            
            return ResponseEntity.ok(results);
        } catch (Exception e) {
            log.error("Error: {}", e.getMessage());
            return ResponseEntity.status(500).body(null);
        }
    }
}





