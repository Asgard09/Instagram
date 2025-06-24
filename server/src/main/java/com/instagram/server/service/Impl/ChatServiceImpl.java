package com.instagram.server.service.Impl;

import com.instagram.server.dto.ChatDTO;
import com.instagram.server.dto.MessageDTO;
import com.instagram.server.entity.Chat;
import com.instagram.server.entity.Message;
import com.instagram.server.entity.User;
import com.instagram.server.repository.ChatRepository;
import com.instagram.server.repository.MessageRepository;
import com.instagram.server.repository.UserRepository;
import com.instagram.server.service.ChatService;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Date;
import java.util.List;
import java.util.Optional;
import java.util.stream.Collectors;

@Service
@SuppressWarnings("unused")
@RequiredArgsConstructor
public class ChatServiceImpl implements ChatService {

    private final ChatRepository chatRepository;
    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    /*Is the implement of websocket config*/
    private final SimpMessagingTemplate messagingTemplate;

    /**
     * Get all chats for a user
     */
    public List<ChatDTO> getUserChats(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        List<Chat> chats = chatRepository.findUserChats(user);
        
        return chats.stream()
                .map(chat -> ChatDTO.fromEntity(chat, user, false))
                .collect(Collectors.toList());
    }

    /**
     * Get a specific chat by ID
     */
    public ChatDTO getChatById(Long chatId, Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        Chat chat = chatRepository.findById(chatId)
                .orElseThrow(() -> new RuntimeException("Chat not found"));
        
        // Make sure the user is part of this chat
        if (!chat.getUser1().getUserId().equals(userId) && !chat.getUser2().getUserId().equals(userId)) {
            throw new RuntimeException("You don't have access to this chat");
        }
        
        return ChatDTO.fromEntity(chat, user, true);
    }

    /**
     * Get or create a chat between two users
     */
    @Transactional
    public ChatDTO getOrCreateChat(Long userId1, Long userId2) {
        if (userId1.equals(userId2)) {
            throw new RuntimeException("Cannot create chat with yourself");
        }
        
        User user1 = userRepository.findById(userId1)
                .orElseThrow(() -> new RuntimeException("User 1 not found"));
        
        User user2 = userRepository.findById(userId2)
                .orElseThrow(() -> new RuntimeException("User 2 not found"));
        
        // Check if chat already exists
        Optional<Chat> existingChat = chatRepository.findChatBetweenUsers(user1, user2);
        
        if (existingChat.isPresent()) {
            return ChatDTO.fromEntity(existingChat.get(), user1, true);
        }
        
        // Create new chat
        Chat newChat = new Chat();
        newChat.setUser1(user1);
        newChat.setUser2(user2);
        chatRepository.save(newChat);
        
        return ChatDTO.fromEntity(newChat, user1, true);
    }

    /**
     * Send a message
     */
    @Transactional
    public MessageDTO sendMessage(Long senderId, Long receiverId, String content) {
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new RuntimeException("Sender not found"));
        
        User receiver = userRepository.findById(receiverId)
                .orElseThrow(() -> new RuntimeException("Receiver not found"));
        
        // Get or create chat
        Chat chat = chatRepository.findChatBetweenUsers(sender, receiver)
                .orElseGet(() -> {
                    Chat newChat = new Chat();
                    newChat.setUser1(sender);
                    newChat.setUser2(receiver);
                    return chatRepository.save(newChat);
                });
        
        // Create a message
        Message message = Message.builder()
                .content(content)
                .sender(sender)
                .receiver(receiver)
                .createdAt(new Date())
                .read(false)
                .build();
        
        // Save message
        messageRepository.save(message);
        
        // Add a message to chat
        chat.getMessages().add(0, message); // Add at beginning for most recent first
        chat.setUpdatedAt(new Date());
        chatRepository.save(chat);
        
        // Convert to DTO
        MessageDTO messageDTO = MessageDTO.fromEntity(message);
        
        // Send a message via WebSocket
        messagingTemplate.convertAndSendToUser(
                receiverId.toString(),
                "/queue/messages",
                messageDTO
        );
        
        return messageDTO;
    }

    /**
     * Mark messages as read
     */
    @Transactional
    public void markMessagesAsRead(Long chatId, Long userId) {
        Chat chat = chatRepository.findById(chatId)
                .orElseThrow(() -> new RuntimeException("Chat not found"));
        
        // Make sure the user is part of this chat
        if (!chat.getUser1().getUserId().equals(userId) && !chat.getUser2().getUserId().equals(userId)) {
            throw new RuntimeException("You don't have access to this chat");
        }
        
        // Find unread messages for this user in this chat
        List<Message> unreadMessages = chat.getMessages().stream()
                .filter(message -> message.getReceiver().getUserId().equals(userId) && !message.isRead())
                .toList();
        
        // Mark messages as read
        unreadMessages.forEach(message -> {
            message.setRead(true);
            messageRepository.save(message);
        });
        
        // Notify the sender that messages were read if there were any unread messages
        if (!unreadMessages.isEmpty()) {
            Long otherUserId = chat.getUser1().getUserId().equals(userId) 
                    ? chat.getUser2().getUserId() 
                    : chat.getUser1().getUserId();
            
            messagingTemplate.convertAndSendToUser(
                    otherUserId.toString(),
                    "/queue/read-receipts",
                    chatId
            );
        }
    }

    /**
     * Get unread message count for a user
     */
    public long getUnreadMessageCount(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new RuntimeException("User not found"));
        
        return messageRepository.countUnreadMessages(user);
    }
} 