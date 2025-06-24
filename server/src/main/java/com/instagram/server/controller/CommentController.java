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
@SuppressWarnings("unused")
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
        return CommentResponse.builder()
                .commentId(comment.getCommentId())
                .comment(comment.getComment())
                .createdAt(comment.getCreatedAt())
                .postId(comment.getPost().getPostId())
                .userId(comment.getUser().getUserId())
                .username(comment.getUser().getUsername())
                .profilePicture(comment.getUser().getProfilePicture())
                .build();
    }

    /**
     *  Count comment from post
     */
    @GetMapping("/countFromPost/{postId}")
    private ResponseEntity<Long> countCommentFromPost(@PathVariable Long postId){
        Long res = commentService.countCommentFromPost(postId);
        return ResponseEntity.ok(res);
    }
}