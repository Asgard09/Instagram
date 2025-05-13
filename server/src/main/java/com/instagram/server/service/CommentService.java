package com.instagram.server.service;

import com.instagram.server.entity.Comment;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;
import com.instagram.server.repository.CommentRepository;
import com.instagram.server.repository.PostRepository;
import com.instagram.server.repository.UserRepository;
import jakarta.transaction.Transactional;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Service;

import java.util.Date;
import java.util.List;

@Service
public class CommentService {
    
    private final CommentRepository commentRepository;
    private final PostRepository postRepository;
    private final UserRepository userRepository;
    
    public CommentService(CommentRepository commentRepository,
                         PostRepository postRepository,
                         UserRepository userRepository) {
        this.commentRepository = commentRepository;
        this.postRepository = postRepository;
        this.userRepository = userRepository;
    }
    
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
        
        return commentRepository.save(comment);
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
        
        // Check if user is the comment owner
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