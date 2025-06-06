package com.instagram.server.service.Impl;

import com.instagram.server.dto.NotificationDTO;
import com.instagram.server.entity.Post;
import com.instagram.server.entity.User;
import com.instagram.server.repository.PostRepository;
import com.instagram.server.repository.UserRepository;
import com.instagram.server.service.NotificationService;
import lombok.extern.slf4j.Slf4j;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;

@Slf4j
@Service
@SuppressWarnings("unused")
public class NotificationServiceImpl implements NotificationService {
    private final UserRepository userRepository;
    private final PostRepository postRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public NotificationServiceImpl(UserRepository userRepository, PostRepository postRepository, SimpMessagingTemplate messagingTemplate) {
        this.userRepository = userRepository;
        this.postRepository = postRepository;
        this.messagingTemplate = messagingTemplate;
    }

    @Override
    public void sendLikeNotification(Long postId, Long likerUserId, Long postOwnerUserId) {
        try{
            // Don't send notification if user likes their own post
            if (likerUserId.equals(postOwnerUserId)) return;

            //Get user's information
            User liker = userRepository.findById(likerUserId)
                    .orElseThrow(() -> new RuntimeException("Liker user not found"));

            //Get post's information
            Post post = postRepository.findById(postId)
                    .orElseThrow(()-> new RuntimeException("Post liked not found"));

            //Create notification
            /*Note
            *Builder Pattern
            */
            NotificationDTO notification = NotificationDTO.builder()
                    .type("LIKE")
                    .message(liker.getUsername() + " liked your post")
                    .fromUserId(likerUserId)
                    .fromUsername(liker.getUsername())
                    .fromUserProfilePicture(liker.getProfilePicture())
                    .postId(postId)
                    .postImageUrl(getPostImageUrl(post))
                    .createdAt(LocalDateTime.now())
                    .isRead(false)
                    .build();

            // Send notification via WebSocket
            messagingTemplate.convertAndSendToUser(
                    postOwnerUserId.toString(),
                    "/queue/notifications",
                    notification
            );

            System.out.println("Like notification sent to user " + postOwnerUserId + " from user " + likerUserId);
        }catch (Exception e){
            /*Note
            *Easy Tracking when deploy application
            *Write Log base on level (info, warn, error, etc.) --> easy for classifying and filter when debug
            */
            log.error("Error sending like notification: {}", e.getMessage(), e);
        }
    }

    @Override
    public void sendCommentNotification(Long postId, Long commenterUserId, Long postOwnerUserId, String commentContent) {
        try{
            if (commenterUserId.equals(postOwnerUserId)) return;

            User commenter = userRepository.findById(commenterUserId)
                    .orElseThrow(()-> new RuntimeException("Commenter user not found"));

            Post post = postRepository.findById(postId)
                    .orElseThrow(() -> new RuntimeException("Post not found"));

            NotificationDTO notification = NotificationDTO.builder()
                    .type("COMMENT")
                    .message(commenter.getUsername() + " commented on your post: " +
                            (commentContent.length() > 50 ? commentContent.substring(0, 50) + "..." : commentContent))
                    .fromUserId(commenterUserId)
                    .fromUsername(commenter.getUsername())
                    .fromUserProfilePicture(commenter.getProfilePicture())
                    .postId(postId)
                    .postImageUrl(post.getImageUrls().toString())
                    .createdAt(LocalDateTime.now())
                    .isRead(false)
                    .build();

            messagingTemplate.convertAndSendToUser(
                    postOwnerUserId.toString(),
                    "/queue/notifications",
                    notification
            );

            System.out.println("Comment notification sent to user " + postOwnerUserId + " from user " + commenterUserId);

        }catch (Exception e){
            log.error("Error sending comment notification: {}", e.getMessage(), e);
        }
    }

    @Override
    public void sendFollowNotification(Long followerUserId, Long followedUserId) {
        try {
            // Get the follower user info
            User follower = userRepository.findById(followerUserId)
                    .orElseThrow(() -> new RuntimeException("Follower user not found"));

            // Create notification
            NotificationDTO notification = NotificationDTO.builder()
                    .type("FOLLOW")
                    .message(follower.getUsername() + " started following you")
                    .fromUserId(followedUserId)
                    .fromUsername(follower.getUsername())
                    .fromUserProfilePicture(follower.getProfilePicture())
                    .postId(null) // No post for follow notifications
                    .postImageUrl(null)// No post-image for follow notifications
                    .build();

            // Send notification via WebSocket
            messagingTemplate.convertAndSendToUser(
                    followedUserId.toString(),
                    "/queue/notifications",
                    notification
            );

            System.out.println("Follow notification sent to user " + followedUserId + " from user " + followerUserId);

        } catch (Exception e) {
            log.error("Error sending follow notification: {}",e.getMessage(), e);
        }
    }
    private String getPostImageUrl(Post post) {
        if (post.getImageUrls() != null && !post.getImageUrls().isEmpty()) {
            return post.getImageUrls().get(0);
        }
        return null;
    }
}
