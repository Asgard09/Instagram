package com.instagram.server.service;

import com.instagram.server.dto.request.CreatePostRequest;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.PostSave;

import java.io.IOException;
import java.util.List;

public interface PostService {
    Post createPost(CreatePostRequest request) throws IOException;
    List<Post> getUserPosts(String username);
    List<Post> getAllPosts();
    List<Post> getNewsFeed();
    void savePost(Long postId, Long userId);
    void unSavePost(Long postId, Long userId);
    boolean isPostSaved(Long postId, Long userId);
    List<PostSave> getAllPostSavedByUser(Long userId);
}
