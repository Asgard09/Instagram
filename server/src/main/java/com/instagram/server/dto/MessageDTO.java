package com.instagram.server.dto;

import com.instagram.server.entity.Message;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Date;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class MessageDTO {
    private Long messageId;
    private String content;
    private Long senderId;
    private String senderUsername;
    private String senderProfilePicture;
    private Long receiverId;
    private Date createdAt;
    private boolean isRead;
    
    public static MessageDTO fromEntity(Message message) {
        MessageDTO dto = new MessageDTO();
        dto.setMessageId(message.getMessageId());
        dto.setContent(message.getContent());
        dto.setSenderId(message.getSender().getUserId());
        dto.setSenderUsername(message.getSender().getUsername());
        dto.setSenderProfilePicture(message.getSender().getProfilePicture());
        dto.setReceiverId(message.getReceiver().getUserId());
        dto.setCreatedAt(message.getCreatedAt());
        dto.setRead(message.isRead());
        return dto;
    }
} 