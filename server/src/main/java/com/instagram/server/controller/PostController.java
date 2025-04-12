package com.instagram.server.controller;

import com.instagram.server.dto.request.CreatePostRequest;
import com.instagram.server.entity.Post;
import com.instagram.server.service.PostService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.io.IOException;
import java.util.List;

@RestController
@RequestMapping("/api/posts")
public class PostController {

    private final PostService postService;

    public PostController(PostService postService) {
        this.postService = postService;
    }

    @PostMapping
    public ResponseEntity<Post> createPost(@RequestBody CreatePostRequest request) {
        try {
            Post createdPost = postService.createPost(request);
            return ResponseEntity.ok(createdPost);
        } catch (IOException e) {
            return ResponseEntity.badRequest().build();
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
