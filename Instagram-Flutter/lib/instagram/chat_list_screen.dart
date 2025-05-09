import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../data/providers/auth_provider.dart';
import '../data/providers/chat_provider.dart';
import '../data/providers/user_provider.dart';
import '../models/chat.dart';
import '../models/message.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  _ChatListScreenState createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  bool _isInitializing = false;

  @override
  void initState() {
    super.initState();
    // Schedule initialization after the first frame is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChats();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh when screen is revisited
    if (!_isInitializing) {
      _initializeChats();
    }
  }

  Future<void> _initializeChats() async {
    setState(() {
      _isInitializing = true;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final currentUser = userProvider.user;

    if (token != null) {
      // If user is not loaded yet, try to fetch it first
      if (currentUser == null || currentUser.userId == null) {
        try {
          print("User not loaded, attempting to fetch user data first");
          await userProvider.fetchCurrentUser(token);
        } catch (e) {
          print("Error fetching user: $e");
        }
      }

      // Now try again with the (hopefully) loaded user
      final updatedUser = Provider.of<UserProvider>(context, listen: false).user;
      
      if (updatedUser != null && updatedUser.userId != null) {
        print("Initializing chat with user ID: ${updatedUser.userId}");
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        
        try {
          // Initialize WebSocket connection
          await chatProvider.initWebSocket(token, updatedUser.userId!);
          
          // Fetch chats
          await chatProvider.fetchUserChats(token);
          
          // Fetch unread message count
          await chatProvider.fetchUnreadMessageCount(token);
        } catch (e) {
          print("Error initializing chat: $e");
        }
      } else {
        print("User data is still not available after fetch attempt");
      }
    } else {
      print("Token is null, cannot initialize chats");
    }

    setState(() {
      _isInitializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Messages', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () {
              // Navigate to new message screen
              // This would typically show a list of users to start a chat with
            },
          ),
        ],
      ),
      body: Consumer2<ChatProvider, UserProvider>(
        builder: (context, chatProvider, userProvider, child) {
          final currentUser = userProvider.user;
          
          // Show appropriate loading/error states
          if (_isInitializing || chatProvider.isLoading) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.white),
                  SizedBox(height: 16),
                  Text(
                    'Loading messages...',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            );
          }

          if (currentUser == null || currentUser.userId == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_off, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'User not logged in',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeChats,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (chatProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error loading chats',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 16),
                  Text(
                    chatProvider.error!,
                    style: TextStyle(color: Colors.grey),
                  ),
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _initializeChats,
                    child: Text('Retry'),
                  ),
                ],
              ),
            );
          }
          
          if (chatProvider.chats.isEmpty) {
            return RefreshIndicator(
              onRefresh: _initializeChats,
              child: ListView(
                children: [
                  SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                  Center(
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
                          'Start a conversation with someone',
                          style: TextStyle(color: Colors.grey),
                        ),
                        SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _initializeChats,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                          ),
                          child: Text('Refresh'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }
          
          return RefreshIndicator(
            onRefresh: _initializeChats,
            child: ListView.builder(
              itemCount: chatProvider.chats.length,
              itemBuilder: (context, index) {
                final chat = chatProvider.chats[index];
                return _buildChatItem(context, chat);
              },
            ),
          );
        },
      ),
    );
  }
  
  Widget _buildChatItem(BuildContext context, Chat chat) {
    final currentUser = Provider.of<UserProvider>(context, listen: false).user;
    
    // Get the earliest message if available
    String messageContent = 'Start a conversation';
    int? messageSenderId;
    DateTime? messageTime;
    
    if (chat.recentMessages.isNotEmpty) {
      // Sort messages by time (oldest first)
      final sortedMessages = List<Message>.from(chat.recentMessages)
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      
      // Get earliest message
      final earliestMessage = sortedMessages.first;
      messageContent = earliestMessage.content;
      messageSenderId = earliestMessage.senderId;
      messageTime = earliestMessage.createdAt;
    } else if (chat.lastMessageContent != null) {
      // Fallback to lastMessageContent if available
      messageContent = chat.lastMessageContent!;
      messageSenderId = chat.lastMessageSenderId;
      messageTime = chat.lastMessageTime;
    }
    
    return ListTile(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(chatId: chat.chatId),
          ),
        ).then((_) => _initializeChats()); // Refresh when returning
      },
      leading: CircleAvatar(
        backgroundColor: Colors.grey[800],
        backgroundImage: chat.otherUser.profilePicture != null
            ? NetworkImage(_getProfileImageUrl(chat.otherUser.profilePicture!))
            : null,
        child: chat.otherUser.profilePicture == null
            ? Icon(Icons.person, color: Colors.white)
            : null,
      ),
      title: Text(
        chat.otherUser.name ?? chat.otherUser.username,
        style: TextStyle(
          color: Colors.white,
          fontWeight: chat.hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      subtitle: Row(
        children: [
          if (messageSenderId == currentUser?.userId)
            Text(
              'You: ',
              style: TextStyle(
                color: Colors.grey,
                fontWeight: chat.hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          Expanded(
            child: Text(
              messageContent,
              style: TextStyle(
                color: chat.hasUnreadMessages ? Colors.white : Colors.grey,
                fontWeight: chat.hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (messageTime != null)
            Text(
              _formatTime(messageTime),
              style: TextStyle(
                color: chat.hasUnreadMessages ? Colors.blue : Colors.grey,
                fontSize: 12,
              ),
            ),
          if (chat.hasUnreadMessages)
            Container(
              margin: EdgeInsets.only(top: 4),
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }
  
  String _formatTime(DateTime time) {
    // Convert to local time zone for display
    final localTime = time.toLocal();
    final now = DateTime.now();
    final difference = now.difference(localTime);
    
    if (difference.inDays > 7) {
      return '${localTime.day}/${localTime.month}/${localTime.year}';
    } else {
      return timeago.format(localTime, locale: 'en_short');
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
} 