import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';

import '../data/providers/auth_provider.dart';
import '../data/providers/user_provider.dart';
import '../services/user_service.dart';

// Model class for user who liked
class LikeUser {
  final int userId;
  final String username;
  final String profilePicture;

  LikeUser({
    required this.userId,
    required this.username,
    required this.profilePicture,
  });

  factory LikeUser.fromJson(Map<String, dynamic> json) {
    return LikeUser(
      userId: json['userId'],
      username: json['username'],
      profilePicture: json['profilePicture'] ?? 'https://via.placeholder.com/150',
    );
  }
}

class LikeListPopup extends StatefulWidget {
  final int postId;
  final VoidCallback onClose;

  const LikeListPopup({
    Key? key,
    required this.postId,
    required this.onClose,
  }) : super(key: key);

  @override
  State<LikeListPopup> createState() => _LikeListPopupState();
}

class _LikeListPopupState extends State<LikeListPopup> {
  List<LikeUser> _likes = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchLikes();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _fetchLikes() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.get(
        Uri.parse('http://192.168.1.6:8080/api/likes/users/post/${widget.postId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> likesJson = json.decode(response.body);
        setState(() {
          _likes = likesJson.map((json) => LikeUser.fromJson(json)).toList();
        });
      } else {
        _showErrorSnackBar('Failed to load likes');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading likes: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
          maxWidth: 400,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade800),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Likes',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: widget.onClose,
                    splashRadius: 20,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : _hasError
                  ? const Center(
                child: Text(
                  'Error loading likes',
                  style: TextStyle(color: Colors.white),
                ),
              )
                  : _likes.isEmpty
                  ? const Center(
                child: Text(
                  'No likes yet\nBe the first to like!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                  ),
                ),
              )
                  : RefreshIndicator(
                onRefresh: _fetchLikes,
                color: Colors.white,
                backgroundColor: Colors.blue,
                child: ListView.builder(
                  itemCount: _likes.length,
                  itemBuilder: (context, index) {
                    final user = _likes[index];
                    return LikeTile(
                      user: user,
                      serverBaseUrl: 'http://192.168.1.6:8080',
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class LikeTile extends StatefulWidget {
  final LikeUser user;
  final String serverBaseUrl;

  const LikeTile({
    Key? key,
    required this.user,
    required this.serverBaseUrl,
  }) : super(key: key);

  @override
  State<LikeTile> createState() => _LikeTileState();
}

class _LikeTileState extends State<LikeTile> {
  bool isFollowing = false;
  bool isProcessing = false;
  int? currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _checkFollowStatus();
  }

  Future<void> _getCurrentUser() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null || token.isEmpty) {
        print('Token is empty or null');
        return;
      }

      // Use the UserService to get the current user data
      final userService = UserService();
      final currentUser = await userService.getCurrentUser(token);

      if (currentUser != null && currentUser.userId != null) {
        setState(() {
          currentUserId = currentUser.userId;
        });
        print('Fetched current user ID: $currentUserId');
      } else {
        print('Failed to get current user or user ID is null');
      }
    } catch (e) {
      print('Error getting current user ID: $e');
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.get(
        Uri.parse('${widget.serverBaseUrl}/api/follows/check/${widget.user.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final followData = json.decode(response.body);
        setState(() {
          isFollowing = followData['following'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  Future<void> _toggleFollow() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final previousFollowState = isFollowing;

      setState(() {
        isFollowing = !isFollowing;
      });

      final response = await http.post(
        Uri.parse('${widget.serverBaseUrl}/api/follows/${widget.user.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          isFollowing = data['status'] == 'followed';
        });
      } else {
        setState(() {
          isFollowing = previousFollowState;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to ${isFollowing ? 'unfollow' : 'follow'} user'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      setState(() {
        isFollowing = !isFollowing; // Revert back on error
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if this is the current user by comparing IDs
    final isCurrentUser = currentUserId != null &&
        widget.user.userId.toString() == currentUserId.toString();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade800.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widget.user.profilePicture != null
              ? _buildAvatar(widget.user.profilePicture!)
              : const CircleAvatar(
            radius: 18,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (isCurrentUser)
                  const Text(
                    'Personal',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          if (!isCurrentUser)
            SizedBox(
              width: 90,
              child: ElevatedButton(
                onPressed: isProcessing ? null : _toggleFollow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.grey[800] : Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                child: isProcessing
                    ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : Text(
                  isFollowing ? 'Following' : 'Follow',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String profilePicture) {
    try {
      if (profilePicture.contains('data:image') || profilePicture.length > 100) {
        final base64String = profilePicture.contains(',')
            ? profilePicture.split(',')[1]
            : profilePicture;
        final imageBytes = base64Decode(base64String);
        return CircleAvatar(
          radius: 18,
          backgroundImage: MemoryImage(imageBytes),
          backgroundColor: Colors.grey,
        );
      }
    } catch (e) {
      print('Error decoding base64 image: $e');
    }

    String imageUrl = profilePicture;
    if (!imageUrl.startsWith('http')) {
      imageUrl = '${widget.serverBaseUrl}/uploads/$imageUrl';
    }
    return CircleAvatar(
      radius: 18,
      backgroundImage: NetworkImage(imageUrl),
      backgroundColor: Colors.grey,
      onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.white),
    );
  }
}