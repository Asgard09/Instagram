package com.instagram.server.service;

import com.instagram.server.dto.request.UpdateBioRequest;
import com.instagram.server.dto.request.UpdateProfileImageRequest;
import com.instagram.server.dto.request.UpdateUserRequest;
import com.instagram.server.entity.User;
import com.instagram.server.repository.UserRepository;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.io.IOException;

@Service
public class UserService {
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;

    public UserService(UserRepository userRepository, FileStorageService fileStorageService) {
        this.userRepository = userRepository;
        this.fileStorageService = fileStorageService;
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
        if (request.getUsername() != null && !request.getUsername().isEmpty()) {
            // Check if new username is already taken
            if (!request.getUsername().equals(currentUsername) && 
                userRepository.findByUsername(request.getUsername()).isPresent()) {
                throw new RuntimeException("Username is already taken");
            }
            user.setUsername(request.getUsername());
        }
        
        if (request.getName() != null) {
            user.setName(request.getName());
        }
        
        if (request.getBio() != null) {
            user.setBio(request.getBio());
        }
        
        if (request.getProfilePicture() != null) {
            user.setProfilePicture(request.getProfilePicture());
        }
        
        if (request.getGender() != null) {
            user.setGender(request.getGender());
        }

        return userRepository.save(user);
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
                // Log error but continue (old file might not exist)
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
} 