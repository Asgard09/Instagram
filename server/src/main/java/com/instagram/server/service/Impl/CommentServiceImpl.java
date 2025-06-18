package com.instagram.server.service.Impl;

import com.instagram.server.base.TypeOfNotification;
import com.instagram.server.entity.Comment;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;
import com.instagram.server.repository.CommentRepository;
import com.instagram.server.repository.PostRepository;
import com.instagram.server.repository.UserRepository;
import com.instagram.server.service.CommentService;
import com.instagram.server.service.NotificationService;
import jakarta.transaction.Transactional;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
@SuppressWarnings("unused")
@RequiredArgsConstructor
public class CommentServiceImpl implements CommentService {
    
    private final CommentRepository commentRepository;
    private final PostRepository postRepository;
    private final UserRepository userRepository;
    private final NotificationService notificationService;
    
    /**
     * Create a new comment on a post
     */
    @Transactional
    public Comment createComment(Long postId, String commentText) {
        // Get current user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get post
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        
        // Create and save comment
        Comment comment = new Comment();
        comment.setComment(commentText);
        comment.setCreatedAt(new Date().toString());
        comment.setPost(post);
        comment.setUser(user);
        
        Comment savedComment = commentRepository.save(comment);
        
        // Create notification for a post-owner (if not commenting on own post)
        if (!user.getUserId().equals(post.getUser().getUserId())) {
            notificationService.createCommentNotification(user, post.getUser(), post, commentText);
        }
        
        return savedComment;
    }
    
    /**
     * Get all comments for a post
     */
    public List<Comment> getPostComments(Long postId) {
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        return commentRepository.findByPostOrderByCreatedAtDesc(post);
    }
    
    /**
     * Delete a comment
     */
    @Transactional
    public void deleteComment(Long commentId) {
        // Get current user
        UserDetails userDetails = (UserDetails) SecurityContextHolder.getContext().getAuthentication().getPrincipal();
        User user = userRepository.findByUsername(userDetails.getUsername())
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        // Get comment
        Comment comment = commentRepository.findById(commentId)
                .orElseThrow(() -> new RuntimeException("Comment not found"));
        
        // Check if the user is the comment owner
        if (!comment.getUser().getUserId().equals(user.getUserId())) {
            throw new RuntimeException("You can only delete your own comments");
        }
        
        commentRepository.delete(comment);
    }

    public long countCommentFromPost(Long postId){
        Post post = postRepository.findById(postId)
                .orElseThrow(() -> new RuntimeException("Post not found"));
        return commentRepository.countByPost(post);
    }


} 