package com.instagram.server.service;

import com.instagram.server.dto.ChatDTO;
import com.instagram.server.dto.MessageDTO;

import java.util.List;

public interface ChatService {
    List<ChatDTO> getUserChats(Long userId);
    ChatDTO getChatById(Long chatId, Long userId);
    ChatDTO getOrCreateChat(Long userId1, Long userId2);
    MessageDTO sendMessage(Long senderId, Long receiverId, String content);
    void markMessagesAsRead(Long chatId, Long userId);
    long getUnreadMessageCount(Long userId);
}
