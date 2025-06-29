package com.instagram.server.controller;

import com.instagram.server.dto.ChatDTO;
import com.instagram.server.dto.MessageDTO;
import com.instagram.server.entity.User;
import com.instagram.server.repository.UserRepository;
import com.instagram.server.service.ChatService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.handler.annotation.MessageMapping;
import org.springframework.messaging.handler.annotation.Payload;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.security.Principal;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/chats")
@SuppressWarnings("unused")
@RequiredArgsConstructor
public class ChatController {

    private final ChatService chatService;
    private final UserRepository userRepository;
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
     * WebSocket endpoint to send a message
     */
    @MessageMapping("/chat.sendMessage")
    public void sendMessageWs(@Payload Map<String, Object> payload) {
        try {
            Long senderId = payload.get("senderId") != null ? Long.parseLong(payload.get("senderId").toString()) : 1L;
            Long receiverId = Long.valueOf(payload.get("receiverId").toString());
            String content = payload.get("content").toString();
            MessageDTO result = chatService.sendMessage(senderId, receiverId, content);
        } catch (Exception e) {
            throw new RuntimeException("Error in sendMessageWs: " + e.getMessage());
        }
    }

    /**
     * WebSocket endpoint to mark messages as read
     */
    @MessageMapping("/chat.markRead")
    public void markMessagesAsReadWs(@Payload Map<String, Object> payload, Principal principal) {
        Long chatId = Long.valueOf(payload.get("chatId").toString());
        /*Need review
        * to want to principal != null*/
        Long userId = payload.get("userId") != null ? Long.parseLong(payload.get("userId").toString()) : 1L;
        System.out.println("Using userId from payload : " + userId);
        
        chatService.markMessagesAsRead(chatId, userId);
    }
    
    // Helper method to get user ID from username
    private Long getUserIdFromUsername(String username) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new RuntimeException("User not found: " + username));
        return user.getUserId();
    }
} 