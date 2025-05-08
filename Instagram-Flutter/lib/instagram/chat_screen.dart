import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../data/providers/auth_provider.dart';
import '../data/providers/chat_provider.dart';
import '../data/providers/user_provider.dart';
import '../models/message.dart';
import '../models/user.dart';

class ChatScreen extends StatefulWidget {
  final int chatId;
  
  const ChatScreen({
    Key? key,
    required this.chatId,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isInitialized = false;
  User? _currentUser;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadChat();
      _isInitialized = true;
    }
  }

  Future<void> _loadChat() async {
    try {
      setState(() {
        _error = null; // Clear any previous errors
      });
      
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      // Validate token and throw exception if invalid
      String token;
      try {
        token = authProvider.validateToken();
        print('Using valid token starting with: ${token.substring(0, 10)}...');
      } catch (e) {
        setState(() {
          _error = e.toString();
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 3),
          ),
        );
        
        // Navigate back after a short delay
        Future.delayed(Duration(seconds: 3), () {
          Navigator.of(context).pop();
        });
        
        return;
      }
      
      // Get current user or load if needed
      _currentUser = userProvider.user;
      if (_currentUser == null) {
        print('Current user is null, attempting to load user data');
        try {
          await userProvider.fetchCurrentUser(token);
          _currentUser = userProvider.user;
          
          if (_currentUser == null) {
            print('Failed to load user data');
            setState(() {
              _error = 'Unable to load your profile. Please try again.';
            });
            return;
          } else {
            print('Successfully loaded user: ${_currentUser!.username} (ID: ${_currentUser!.userId})');
          }
        } catch (e) {
          print('Error loading user data: $e');
          setState(() {
            _error = 'Error loading your profile: $e';
          });
          return;
        }
      } else {
        print('Using existing user: ${_currentUser!.username} (ID: ${_currentUser!.userId})');
      }

      // Now we have both a valid token and user, proceed to load the chat
      print('Loading chat with ID: ${widget.chatId}');
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      
      // Ensure WebSocket is connected
      final connected = await chatProvider.ensureWebSocketConnected(token, _currentUser!.userId!);
      if (!connected) {
        print('Failed to establish WebSocket connection');
        setState(() {
          _error = 'Failed to establish connection to chat server';
        });
        return;
      }
      
      // Load the chat data
      try {
        await chatProvider.getChatById(widget.chatId, token);
        
        if (chatProvider.currentChat != null) {
          print('Chat loaded successfully. Other user: ${chatProvider.currentChat!.otherUser.username}');
          print('Messages count: ${chatProvider.currentChat!.recentMessages.length}');
          
          // Successfully loaded, clear any error
          setState(() {
            _error = null;
          });
          
          // Print a sample of messages for debugging
          if (chatProvider.currentChat!.recentMessages.isNotEmpty) {
            for (var i = 0; i < chatProvider.currentChat!.recentMessages.length && i < 3; i++) {
              final msg = chatProvider.currentChat!.recentMessages[i];
              final fromMe = chatProvider.currentChat!.isMessageFromMe(msg, _currentUser!.userId!);
              print('Message ${i+1}: ${msg.content} - from me: $fromMe');
            }
          }
        } else {
          print('Chat is null after loading');
          setState(() {
            _error = 'Failed to load chat data';
          });
        }
      } catch (e) {
        print('Error loading chat: $e');
        setState(() {
          _error = 'Error loading chat: $e';
        });
      }
    } catch (e) {
      // Catch any unexpected errors
      print('Unexpected error during chat loading: $e');
      setState(() {
        _error = 'Unexpected error: $e';
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final token = authProvider.token;
    final currentChat = chatProvider.currentChat;

    // Check if token is valid
    if (!authProvider.isTokenValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Your session has expired. Please log in again.'),
          backgroundColor: Colors.red,
        ),
      );
      // Navigate to login screen
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    if (token != null && currentChat != null && _currentUser != null) {
      _messageController.clear();

      // Create a temporary message to display immediately
      final tempMessage = Message(
        messageId: null,
        content: message,
        senderId: _currentUser!.userId!,
        senderUsername: _currentUser!.username,
        senderProfilePicture: _currentUser!.profilePicture,
        receiverId: currentChat.otherUser.userId,
        createdAt: DateTime.now().toUtc(),
        isRead: false,
      );

      // Add temporary message to UI
      currentChat.recentMessages.add(tempMessage);
      // Force rebuild
      setState(() {});

      // Scroll to bottom after adding message
      _scrollToBottom();

      try {
        // Send actual message to server
        await chatProvider.sendMessage(
          currentChat.otherUser.userId,
          message,
          token,
        );
      } catch (e) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send message. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
        print('Error sending message: $e');
        
        // If it's an authorization error, suggest logging in again
        if (e.toString().contains('403')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Your session may have expired. Try logging in again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final currentChat = chatProvider.currentChat;
            if (currentChat == null) {
              return const Text('Chat', style: TextStyle(color: Colors.white));
            }
            return Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[800],
                  backgroundImage: currentChat.otherUser.profilePicture != null
                      ? NetworkImage(_getProfileImageUrl(currentChat.otherUser.profilePicture!))
                      : null,
                  child: currentChat.otherUser.profilePicture == null
                      ? Icon(Icons.person, color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 10),
                Text(
                  currentChat.otherUser.name ?? currentChat.otherUser.username,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.white),
            onPressed: () {
              // Show chat info
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                // Show local error if available
                if (_error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                children: [
                        Text(
                          'Error loading chat',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadChat,
                          child: Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                
                if (chatProvider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                if (chatProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Error loading chat',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 16),
                    Text(
                          chatProvider.error!,
                          style: TextStyle(color: Colors.grey),
                    ),
                        SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadChat,
                          child: Text('Retry'),
                ),
              ],
            ),
                  );
                }

                final currentChat = chatProvider.currentChat;
                if (currentChat == null) {
                  return const Center(
                    child: Text(
                      'Chat not found',
                      style: TextStyle(color: Colors.white),
                    ),
                  );
                }

                final messages = currentChat.recentMessages;
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No messages yet',
                          style: TextStyle(color: Colors.white, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                Text(
                          'Send a message to start the conversation',
                          style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
                  );
                }

                _scrollToBottom();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: false,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    
                    // Explicitly convert IDs to strings before comparison to avoid type issues
                    final currentUserId = _currentUser?.userId?.toString() ?? '';
                    final messageSenderId = message.senderId.toString();
                    
                    // Compare as strings to avoid integer/long type mismatches
                    final isMe = currentUserId == messageSenderId;
                    
                    // Debug info
                    print('Message: ${message.content}');
                    print('Current user ID: $currentUserId (${currentUserId.runtimeType})');
                    print('Message sender ID: $messageSenderId (${messageSenderId.runtimeType})');
                    print('Is sent by me: $isMe');
                    
                    return _buildMessageItem(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, bool isMe) {
    // Ensure proper message bubble styling
    print('Building message item for "${message.content}", isMe = $isMe');
    
    return Container(
      margin: EdgeInsets.only(
        bottom: 12,
        left: isMe ? 60 : 0,
        right: isMe ? 0 : 60,
      ),
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blue : Colors.grey[800],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(color: Colors.grey[400], fontSize: 11),
              ),
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    message.isRead ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.isRead ? Colors.blue : Colors.grey,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      color: Colors.grey[900],
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.camera_alt, color: Colors.white),
            onPressed: () {
              // Open camera or gallery
            },
          ),
          Expanded(
            child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Message...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.send, color: Colors.white),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    // Convert the UTC time from server to local time zone
    final localTime = time.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTime);
    
    // Format the time part
    final hour = localTime.hour.toString().padLeft(2, '0');
    final minute = localTime.minute.toString().padLeft(2, '0');
    final timeString = '$hour:$minute';
    
    // Today - show only time
    if (difference.inDays == 0 && now.day == localTime.day) {
      return timeString;
    }
    
    // Yesterday - show "Yesterday, HH:MM"
    if (difference.inDays == 1 || (difference.inHours >= 12 && now.day == localTime.day + 1)) {
      return 'Yesterday, $timeString';
    }
    
    // This week (within 7 days) - show day name, HH:MM
    if (difference.inDays < 7) {
      final dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
      final dayName = dayNames[localTime.weekday - 1];
      return '$dayName, $timeString';
    }
    
    // Older - show full date
    final day = localTime.day.toString().padLeft(2, '0');
    final month = localTime.month.toString().padLeft(2, '0');
    final year = localTime.year;
    
    return '$day/$month/$year, $timeString';
  }
  
  String _getProfileImageUrl(String profilePicture) {
    if (profilePicture.startsWith('http')) {
      return profilePicture;
    } else {
      final baseUrl = 'http://192.168.1.5:8080';
      return '$baseUrl/uploads/$profilePicture';
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}