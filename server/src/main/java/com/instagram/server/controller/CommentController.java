package com.instagram.server.controller;

import com.instagram.server.dto.request.CreateCommentRequest;
import com.instagram.server.dto.response.CommentResponse;
import com.instagram.server.entity.Comment;
import com.instagram.server.service.CommentService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/comments")
@CrossOrigin(origins = "*", maxAge = 3600)
public class CommentController {
    
    private final CommentService commentService;
    
    public CommentController(CommentService commentService) {
        this.commentService = commentService;
    }
    
    /**
     * Create a new comment on a post
     */
    @PostMapping("/post/{postId}")
    public ResponseEntity<CommentResponse> createComment(
            @PathVariable Long postId,
            @RequestBody CreateCommentRequest request) {
        Comment comment = commentService.createComment(postId, request.getComment());
        return ResponseEntity.ok(convertToCommentResponse(comment));
    }
    
    /**
     * Get all comments for a post
     */
    @GetMapping("/post/{postId}")
    public ResponseEntity<List<CommentResponse>> getPostComments(@PathVariable Long postId) {
        List<Comment> comments = commentService.getPostComments(postId);
        List<CommentResponse> commentResponses = comments.stream()
                .map(this::convertToCommentResponse)
                .collect(Collectors.toList());
        return ResponseEntity.ok(commentResponses);
    }
    
    /**
     * Delete a comment
     */
    @DeleteMapping("/{commentId}")
    public ResponseEntity<?> deleteComment(@PathVariable Long commentId) {
        commentService.deleteComment(commentId);
        return ResponseEntity.ok().build();
    }
    
    /**
     * Convert Comment entity to CommentResponse
     */
    private CommentResponse convertToCommentResponse(Comment comment) {
        CommentResponse response = new CommentResponse();
        response.setCommentId(comment.getCommentId());
        response.setComment(comment.getComment());
        response.setCreatedAt(comment.getCreatedAt());
        response.setPostId(comment.getPost().getPostId());
        response.setUserId(comment.getUser().getUserId());
        response.setUsername(comment.getUser().getUsername());
        response.setProfilePicture(comment.getUser().getProfilePicture());
        return response;
    }
} 