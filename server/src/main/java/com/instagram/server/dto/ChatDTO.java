package com.instagram.server.dto;

import com.instagram.server.entity.Chat;
import com.instagram.server.entity.Message;
import com.instagram.server.entity.User;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;
import java.util.List;
import java.util.stream.Collectors;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class ChatDTO {
    private Long chatId;
    private UserSummaryDTO otherUser;
    private Date lastMessageTime;
    private String lastMessageContent;
    private Long lastMessageSenderId;
    private boolean hasUnreadMessages;
    private List<MessageDTO> recentMessages;
    
    public static ChatDTO fromEntity(Chat chat, User currentUser, boolean includeMessages) {
        ChatDTO dto = new ChatDTO();
        dto.setChatId(chat.getChatId());
        
        // Determine which user is the "other" user from the current user's perspective
        User otherUser = chat.getUser1().getUserId().equals(currentUser.getUserId()) 
                ? chat.getUser2() : chat.getUser1();
        dto.setOtherUser(new UserSummaryDTO(
                otherUser.getUserId(),
                otherUser.getUsername(),
                otherUser.getProfilePicture(),
                otherUser.getName()
        ));
        
        // Set last message info if chat has messages
        List<Message> messages = chat.getMessages();
        if (messages != null && !messages.isEmpty()) {
            Message lastMessage = messages.get(0); // Assuming messages are ordered by date desc
            dto.setLastMessageTime(lastMessage.getCreatedAt());
            dto.setLastMessageContent(lastMessage.getContent());
            dto.setLastMessageSenderId(lastMessage.getSender().getUserId());
            
            // Check if there are unread messages for the current user
            dto.setHasUnreadMessages(messages.stream()
                    .anyMatch(m -> m.getReceiver().getUserId().equals(currentUser.getUserId()) && !m.isRead()));
            
            // Include recent messages if requested
            if (includeMessages) {
                dto.setRecentMessages(messages.stream()
                        .limit(100) // Only get the 100 most recent messages
                        .map(MessageDTO::fromEntity)
                        .collect(Collectors.toList()));
            }
        }
        
        return dto;
    }
    
    @Data
    @NoArgsConstructor
    @AllArgsConstructor
    public static class UserSummaryDTO {
        private Long userId;
        private String username;
        private String profilePicture;
        private String name;
    }
} 