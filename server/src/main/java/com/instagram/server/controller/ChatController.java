package com.instagram.server.controller;

import com.instagram.server.dto.ChatDTO;
import com.instagram.server.dto.MessageDTO;
import com.instagram.server.entity.User;
import com.instagram.server.repository.UserRepository;
import com.instagram.server.service.ChatService;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/chats")
public class ChatController {

    private final ChatService chatService;
    private final SimpMessagingTemplate messagingTemplate;
    private final UserRepository userRepository;

    public ChatController(
            ChatService chatService,
            SimpMessagingTemplate messagingTemplate,
            UserRepository userRepository) {
        this.chatService = chatService;
        this.messagingTemplate = messagingTemplate;
        this.userRepository = userRepository;
    }

    /**
     * REST endpoint to get all chats for the current user
     */
    @GetMapping
    public ResponseEntity<List<ChatDTO>> getUserChats(Authentication authentication) {
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        Long userId = getUserIdFromUsername(userDetails.getUsername());
        return ResponseEntity.ok(chatService.getUserChats(userId));
    }

    /**
     * REST endpoint to get a specific chat by ID
     */
    @GetMapping("/{chatId}")
    public ResponseEntity<ChatDTO> getChatById(
            @PathVariable Long chatId,
            Authentication authentication) {
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        Long userId = getUserIdFromUsername(userDetails.getUsername());
        return ResponseEntity.ok(chatService.getChatById(chatId, userId));
    }

    /**
     * REST endpoint to get or create a chat with another user
     */
    @PostMapping("/with/{otherUserId}")
    public ResponseEntity<ChatDTO> getOrCreateChat(
            @PathVariable Long otherUserId,
            Authentication authentication) {
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        Long userId = getUserIdFromUsername(userDetails.getUsername());
        return ResponseEntity.ok(chatService.getOrCreateChat(userId, otherUserId));
    }

    /**
     * REST endpoint to send a message via HTTP (alternative to WebSocket)
     */
    @PostMapping("/message")
    public ResponseEntity<MessageDTO> sendMessage(
            @RequestBody Map<String, Object> payload,
            Authentication authentication) {
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        Long senderId = getUserIdFromUsername(userDetails.getUsername());
        Long receiverId = Long.valueOf(payload.get("receiverId").toString());
        String content = payload.get("content").toString();
        
        return ResponseEntity.ok(chatService.sendMessage(senderId, receiverId, content));
    }

    /**
     * REST endpoint to mark messages as read
     */
    @PostMapping("/{chatId}/read")
    public ResponseEntity<Void> markMessagesAsRead(
            @PathVariable Long chatId,
            Authentication authentication) {
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        Long userId = getUserIdFromUsername(userDetails.getUsername());
        chatService.markMessagesAsRead(chatId, userId);
        return ResponseEntity.ok().build();
    }

    /**
     * REST endpoint to get unread message count
     */
    @GetMapping("/unread/count")
    public ResponseEntity<Map<String, Long>> getUnreadMessageCount(Authentication authentication) {
        UserDetails userDetails = (UserDetails) authentication.getPrincipal();
        Long userId = getUserIdFromUsername(userDetails.getUsername());
        long count = chatService.getUnreadMessageCount(userId);
        return ResponseEntity.ok(Map.of("count", count));
    }

    /**
     * WebSocket endpoint to send message
     */
    @MessageMapping("/chat.sendMessage")
    public void sendMessageWs(@Payload Map<String, Object> payload, Principal principal) {
        try {
            System.out.println("Received WebSocket message payload: " + payload);
            System.out.println("Principal: " + (principal != null ? principal.getName() : "null"));
            
            // For testing purposes, if no principal, use senderId from payload
            Long senderId;
            if (principal != null) {
                senderId = getUserIdFromUsername(principal.getName());
                System.out.println("Using authenticated user ID: " + senderId);
            } else {
                // Fallback for testing - get senderId from payload
                senderId = payload.get("senderId") != null ? 
                    Long.valueOf(payload.get("senderId").toString()) : 1L;
                System.out.println("Using senderId from payload: " + senderId);
            }
            
            Long receiverId = Long.valueOf(payload.get("receiverId").toString());
            String content = payload.get("content").toString();
            
            System.out.println("Sending message from " + senderId + " to " + receiverId + ": " + content);
            
            MessageDTO result = chatService.sendMessage(senderId, receiverId, content);
            System.out.println("Message sent successfully with ID: " + result.getMessageId());
            
        } catch (Exception e) {
            System.err.println("Error in sendMessageWs: " + e.getMessage());
            e.printStackTrace();
        }
    }

    /**
     * WebSocket endpoint to mark messages as read
     */
    @MessageMapping("/chat.markRead")
    public void markMessagesAsReadWs(@Payload Map<String, Object> payload, Principal principal) {
        Long chatId = Long.valueOf(payload.get("chatId").toString());
        Long userId = getUserIdFromUsername(principal.getName());
        
        chatService.markMessagesAsRead(chatId, userId);
    }
    
    // Helper method to get user ID from username
    private Long getUserIdFromUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found: " + username));
        return user.getUserId();
    }
} 