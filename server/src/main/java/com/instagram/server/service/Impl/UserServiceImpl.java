package com.instagram.server.service.Impl;

import com.instagram.server.dto.request.UpdateBioRequest;
import com.instagram.server.dto.request.UpdateProfileImageRequest;
import com.instagram.server.dto.request.UpdateUserRequest;
import com.instagram.server.entity.User;
import com.instagram.server.repository.UserRepository;
import com.instagram.server.service.FileStorageService;
import com.instagram.server.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.function.Consumer;

@Service
@SuppressWarnings("unused")
@RequiredArgsConstructor
public class UserServiceImpl implements UserService {
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;

    // Get followers for tagging
    public List<User> getFollowersForTagging(String username) {
        // For now, return some sample users since we don't have a full follower system
        // In a real system, we would fetch actual followers from a relationship table
        
        // Get current user as base
        User currentUser = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get some other users as "followers" (for demo purposes)
        List<User> allUsers = userRepository.findAll();
        List<User> followers = new ArrayList<>();
        
        // Add a few users as mock followers (excluding the current user)
        for (User user : allUsers) {
            if (!user.getUsername().equals(username)) {
                followers.add(user);
            }
            
            // Limit to 10 followers for the demo
            if (followers.size() >= 10) {
                break;
            }
        }
        
        return followers;
    }

    public User updateBio(UpdateBioRequest request) {
        // Get current authenticated user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        String username = userDetails.getUsername();

        // Find user and update bio
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        user.setBio(request.getBio());
        return userRepository.save(user);
    }

    public User updateUserInfo(UpdateUserRequest request) {
        // Get current authenticated user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        String currentUsername = userDetails.getUsername();

        // Find user
        User user = userRepository.findByUsername(currentUsername)
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Update fields if they are provided
        updateUserName(user, request.getUsername(), currentUsername);
        updateFieldIfPresent(request.getName(), user::setName);
        updateFieldIfPresent(request.getBio(), user::setBio);
        updateFieldIfPresent(request.getProfilePicture(), user::setProfilePicture);
        updateFieldIfPresent(request.getGender(), user::setGender);

        return userRepository.save(user);
    }

    private void updateUserName(User user, String newUsername, String currentUsername){
        if(newUsername != null && !newUsername.isEmpty()){
            if (userRepository.findByUsername(newUsername).isPresent()){
                throw new RuntimeException("Username is already taken");
            }
            user.setUsername(newUsername);
        }
    }

    private <T> void updateFieldIfPresent(T value, Consumer<T> setter){
        if (value != null){
            setter.accept(value);
        }
    }
    public User updateProfileImage(UpdateProfileImageRequest request) throws IOException {
        // Get current authenticated user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        String username = userDetails.getUsername();

        // Find user
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Delete old profile picture if exists
        if (user.getProfilePicture() != null && !user.getProfilePicture().isEmpty()) {
            try {
                fileStorageService.deleteFile(user.getProfilePicture());
            } catch (IOException e) {
                // Log error but continue (an old file might not exist)
                System.err.println("Failed to delete old profile picture: " + e.getMessage());
            }
        }
        
        // Store new profile picture
        String imageUrl = fileStorageService.storeImage(
                request.getImageBase64(), 
                "profiles/" + user.getUserId()
        );
        
        // Update user profile picture
        user.setProfilePicture(imageUrl);
        return userRepository.save(user);
    }

    /**
     * Get the currently authenticated user
     */
    public User getCurrentUser() {
        // Get current authenticated user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        String username = userDetails.getUsername();

        // Find and return user
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    // Get user by username
    public User getUserByUsername(String username) {
        return userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
    }
    
    // Get user by ID
    public User getUserById(Long userId) {
        return userRepository.findById((long) Math.toIntExact(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));
    }

    // Add this method to your UserService interface
    public List<User> searchUsers(String query){
        if (query == null || query.trim().isEmpty()) {
            return Collections.emptyList();
        }

        // Don't add wildcards - Spring's Containing keyword will do this automatically
        return userRepository.findByUsernameContainingIgnoreCaseOrNameContainingIgnoreCase(query, query);
    }
} 