package com.instagram.server.service;

import com.instagram.server.dto.request.CreatePostRequest;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;
import com.instagram.server.repository.PostRepository;
import com.instagram.server.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

@Service
public class PostService {

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;

    public PostService(PostRepository postRepository, UserRepository userRepository,
            FileStorageService fileStorageService) {
        this.postRepository = postRepository;
        this.userRepository = userRepository;
        this.fileStorageService = fileStorageService;
    }

    @Transactional
    public Post createPost(CreatePostRequest request) throws IOException {
        // Get current user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));

        // Create post entity
        Post post = new Post();
        post.setContent(request.getContent());
        post.setCaption(request.getCaption());
        post.setCreatedAt(new Date());
        post.setUser(user);

        // Save images if provided
        List<String> imageUrls = new ArrayList<>();
        if (request.getImageBase64() != null && !request.getImageBase64().isEmpty()) {
            for (String imageBase64 : request.getImageBase64()) {
                // Store the image and get its URL
                String imageUrl = fileStorageService.storeBase64Image(imageBase64, "posts/" + user.getUserId());
                imageUrls.add(imageUrl);
            }
        }
        post.setImageUrls(imageUrls);

        // Save post
        return postRepository.save(post);
    }

    public List<Post> getUserPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return postRepository.findByUserOrderByCreatedAtDesc(user);
    }

    public List<Post> getNewsFeed() {
        // Get current user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Here you would typically get posts from users that the current user follows
        // For now, we'll just return all posts ordered by creation date
        return postRepository.findAllByOrderByCreatedAtDesc();
    }
} 