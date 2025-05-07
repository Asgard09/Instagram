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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _loadChat();
      _isInitialized = true;
    }
  }

  Future<void> _loadChat() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    _currentUser = Provider.of<UserProvider>(context, listen: false).user;

    if (token != null && _currentUser != null) {
      await Provider.of<ChatProvider>(context, listen: false)
          .getChatById(widget.chatId, token);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final currentChat = chatProvider.currentChat;

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
        createdAt: DateTime.now(),
        read: false,
      );

      // Add temporary message to UI
      currentChat.recentMessages.insert(0, tempMessage);
      // Force rebuild
      setState(() {});

      // Scroll to bottom after adding message
      _scrollToBottom();

      // Send actual message to server
      await chatProvider.sendMessage(
        currentChat.otherUser.userId,
        message,
        token,
      );
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
                  reverse: true,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == _currentUser?.userId;
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
            child: Text(
              message.content,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
              if (isMe)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(
                    message.read ? Icons.done_all : Icons.done,
                    size: 14,
                    color: message.read ? Colors.blue : Colors.grey,
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
    final now = DateTime.now();
    final difference = now.difference(time);
    
    if (difference.inDays > 0) {
      return '${time.day}/${time.month} ${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.hour}:${time.minute.toString().padLeft(2, '0')}';
    }
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