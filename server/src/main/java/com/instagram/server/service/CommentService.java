package com.instagram.server.service;

import com.instagram.server.entity.Comment;

import java.util.List;

public interface CommentService {
    Comment createComment(Long postId, String commentText);
    List<Comment> getPostComments(Long postId);
    void deleteComment(Long commentId);
    long countCommentFromPost(Long postId);
}
