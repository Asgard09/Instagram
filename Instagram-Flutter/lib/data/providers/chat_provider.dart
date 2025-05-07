import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../../models/chat.dart';
import '../../models/message.dart';
import '../../services/chat_service.dart';
import '../../services/websocket_service.dart';

class ChatProvider extends ChangeNotifier {
  // Services
  final ChatService _chatService = ChatService();
  final WebSocketService _webSocketService = WebSocketService();
  
  // State
  bool _isLoading = false;
  String? _error;
  List<Chat> _chats = [];
  Chat? _currentChat;
  int _unreadCount = 0;
  
  // Getters
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<Chat> get chats => _chats;
  Chat? get currentChat => _currentChat;
  int get unreadCount => _unreadCount;
  bool get isWebSocketConnected => _webSocketService.isConnected;
  
  // Stream subscriptions
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<int>? _readReceiptSubscription;
  
  // Ensure WebSocket is connected with valid token
  Future<bool> ensureWebSocketConnected(String token, int userId) async {
    if (!_webSocketService.isConnected) {
      print('WebSocket not connected. Initializing...');
      return await initWebSocket(token, userId);
    }
    print('WebSocket already connected');
    return true;
  }
  
  // Initialize WebSocket connection
  Future<bool> initWebSocket(String token, int userId) async {
    if (token.isEmpty) {
      print('Cannot initialize WebSocket: Token is empty');
      return false;
    }
    
    print('Initializing WebSocket with token: ${token.substring(0, min(20, token.length))}...');
    
    // Dispose previous subscriptions
    _messageSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    
    try {
      // Connect WebSocket
      _webSocketService.connect(token, userId);
      
      // Listen for new messages
      _messageSubscription = _webSocketService.messageStream.listen((message) {
        print('Received message from senderId: ${message.senderId}, receiverId: ${message.receiverId}');
        // Add message to current chat if it's from the same chat
        if (_currentChat != null && 
            (_currentChat!.otherUser.userId == message.senderId || 
             _currentChat!.otherUser.userId == message.receiverId)) {
          print('Adding message to current chat: ${_currentChat!.chatId}');
          _currentChat!.recentMessages.insert(0, message);
          notifyListeners();
        }
        
        // Update chat list with new message
        _updateChatListWithNewMessage(message);
        
        // Increment unread count if message is not read and user is receiver
        if (!message.isRead && message.receiverId == userId) {
          _unreadCount++;
          notifyListeners();
        }
      });
      
      // Listen for read receipts
      _readReceiptSubscription = _webSocketService.readReceiptStream.listen((chatId) {
        // Update read status for the specified chat
        if (_currentChat != null && _currentChat!.chatId == chatId) {
          _currentChat!.recentMessages.forEach((message) {
            if (!message.isRead) {
              // Now directly modify the property since it's not final
              message.isRead = true;
            }
          });
          notifyListeners();
        }
      });
      
      return true;
    } catch (e) {
      print('Error initializing WebSocket: $e');
      _error = 'Failed to connect to chat service: $e';
      notifyListeners();
      return false;
    }
  }
  
  // Fetch user's chats
  Future<void> fetchUserChats(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _chats = await _chatService.getUserChats(token);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get chat by ID
  Future<void> getChatById(int chatId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentChat = await _chatService.getChatById(chatId, token);
      
      // Mark messages as read if there are unread messages
      if (_currentChat!.hasUnreadMessages) {
        markMessagesAsRead(chatId, token);
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Get or create chat with user
  Future<Chat?> getOrCreateChatWithUser(int otherUserId, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    
    try {
      _currentChat = await _chatService.getOrCreateChat(otherUserId, token);
      _isLoading = false;
      notifyListeners();
      return _currentChat;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }
  
  // Send message
  Future<Message?> sendMessage(int receiverId, String content, String token) async {
    _error = null;
    
    try {
      // Try to send message via WebSocket first if connected
      if (_webSocketService.isConnected) {
        print('Sending message via WebSocket');
        _webSocketService.sendMessage(receiverId, content);
        
        // For WebSockets, we don't immediately get the message back
        // We could create a temporary message here until the real one arrives
        return null;
      } else {
        // Fallback to HTTP if WebSocket is not connected
        print('WebSocket not connected, sending via HTTP');
        return await _chatService.sendMessage(receiverId, content, token);
      }
    } catch (e) {
      print('Error sending message: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }
  
  // Mark messages as read
  Future<void> markMessagesAsRead(int chatId, String token) async {
    _error = null;
    
    try {
      // Try WebSocket first
      if (_webSocketService.isConnected) {
        _webSocketService.markMessagesAsRead(chatId);
      } else {
        // Fallback to HTTP
        await _chatService.markMessagesAsRead(chatId, token);
      }
      
      // Update local state
      if (_currentChat != null && _currentChat!.chatId == chatId) {
        // Mark all messages as read
        for (var i = 0; i < _currentChat!.recentMessages.length; i++) {
          if (!_currentChat!.recentMessages[i].isRead) {
            // Now directly modify the property since it's not final
            _currentChat!.recentMessages[i].isRead = true;
          }
        }
        
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Fetch unread message count
  Future<void> fetchUnreadMessageCount(String token) async {
    _error = null;
    
    try {
      _unreadCount = await _chatService.getUnreadMessageCount(token);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }
  
  // Update the chat list with a new message
  void _updateChatListWithNewMessage(Message message) {
    // Find the chat for this message
    final chatIndex = _chats.indexWhere((chat) => 
      chat.otherUser.userId == message.senderId || 
      chat.otherUser.userId == message.receiverId
    );
    
    if (chatIndex >= 0) {
      // Chat exists, update it
      final updatedChat = Chat(
        chatId: _chats[chatIndex].chatId,
        otherUser: _chats[chatIndex].otherUser,
        lastMessageTime: message.createdAt,
        lastMessageContent: message.content,
        lastMessageSenderId: message.senderId,
        hasUnreadMessages: message.receiverId == _chats[chatIndex].otherUser.userId ? false : !message.isRead,
        recentMessages: [message, ..._chats[chatIndex].recentMessages],
      );
      
      // Move this chat to the top of the list
      _chats.removeAt(chatIndex);
      _chats.insert(0, updatedChat);
    }
    // Note: If the chat doesn't exist, the user should refresh the chat list
    
    notifyListeners();
  }
  
  // Dispose
  @override
  void dispose() {
    _messageSubscription?.cancel();
    _readReceiptSubscription?.cancel();
    _webSocketService.dispose();
    super.dispose();
  }
} 