package com.instagram.server.service;

import com.instagram.server.dto.request.CreatePostRequest;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.PostSave;
import com.instagram.server.entity.User;
import com.instagram.server.repository.PostRepository;
import com.instagram.server.repository.PostSaveRepository;
import com.instagram.server.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;
import java.util.Optional;

@Service
public class PostService {

    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final FileStorageService fileStorageService;
    private final PostSaveRepository postSaveRepository;

    public PostService(PostRepository postRepository, UserRepository userRepository,
            FileStorageService fileStorageService, PostSaveRepository postSaveRepository) {
        this.postRepository = postRepository;
        this.userRepository = userRepository;
        this.fileStorageService = fileStorageService;
        this.postSaveRepository = postSaveRepository;
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
                String imageUrl = fileStorageService.storeImage(
                        imageBase64, 
                        "posts/" + user.getUserId()
                );
                imageUrls.add(imageUrl);
            }
        }
        post.setImageUrls(imageUrls);

        // Save tagged people if provided
        if (request.getTaggedPeople() != null && !request.getTaggedPeople().isEmpty()) {
            post.setTaggedPeople(request.getTaggedPeople());
        }

        // Save post
        return postRepository.save(post);
    }

    public List<Post> getUserPosts(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found"));
        return postRepository.findByUserOrderByCreatedAtDesc(user);
    }

    public List<Post> getAllPosts() {
        return postRepository.findAllByOrderByCreatedAtDesc();
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

    @Transactional
    public void savePost(Long postId, Long userId){
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with ID: " + userId));
        
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found with ID: " + postId));

        // Check if already saved to prevent duplicates
        if (postSaveRepository.existsByUserAndPost(user, post)) {
            // Post is already saved - we could return a flag or throw an exception
            // For now, we'll just return without creating a duplicate
            return;
        }
        
        PostSave postSave = new PostSave();
        postSave.setUser(user);
        postSave.setPost(post);
        postSave.setSavedAt(new Date());
        
        postSaveRepository.save(postSave);
    }
    
    @Transactional
    public void unSavePost(Long postId, Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with ID: " + userId));
        
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found with ID: " + postId));
        
        Optional<PostSave> postSave = postSaveRepository.findByUserAndPost(user, post);

        if (postSave.isPresent()) {
            postSaveRepository.delete(postSave.get());
        }
        // No need to throw exception if not found - it's already unsaved
    }
    
    public boolean isPostSaved(Long postId, Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with ID: " + userId));
        
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found with ID: " + postId));
        
        return postSaveRepository.existsByUserAndPost(user, post);
    }

    public List<PostSave> getAllPostSavedByUser(Long userId){
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found with ID: " + userId));
        
        return postSaveRepository.findByUserOrderBySavedAtDesc(user);
    }
} 