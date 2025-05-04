import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:provider/provider.dart';

import '../data/providers/auth_provider.dart';

class CommentsBottomSheet extends StatefulWidget {
  final int postId;
  final Function(String)? onCommentSubmitted;
  final List<Comment>? initialComments;
  final String? currentUserAvatar;

  const CommentsBottomSheet({
    Key? key,
    required this.postId,
    this.onCommentSubmitted,
    this.initialComments,
    this.currentUserAvatar,
  }) : super(key: key);

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  final TextEditingController _commentController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _isSubmitting = false;
  bool _isLoading = false;
  List<Comment> _comments = [];
  String? _replyingTo;

  @override
  void initState() {
    super.initState();
    if (widget.initialComments != null) {
      _comments = widget.initialComments!;
    } else {
      _loadComments();
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.get(
        Uri.parse('http://192.168.1.3:8080/api/comments/post/${widget.postId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> commentsJson = json.decode(response.body);
        setState(() {
          _comments = commentsJson.map((json) => Comment.fromJson(json)).toList();
        });
      } else {
        _showErrorSnackBar('Failed to load comments');
      }
    } catch (e) {
      _showErrorSnackBar('Error loading comments: $e');
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

  Future<void> _submitComment() async {
    if (_commentController.text.trim().isEmpty || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final String commentText = _replyingTo != null
          ? '@$_replyingTo ${_commentController.text.trim()}'
          : _commentController.text.trim();

      final response = await http.post(
        Uri.parse('http://192.168.1.3:8080/api/comments/post/${widget.postId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'comment': commentText,
        }),
      );

      if (response.statusCode == 200) {
        final commentJson = json.decode(response.body);
        final newComment = Comment.fromJson(commentJson);

        setState(() {
          _comments.insert(0, newComment);
          _commentController.clear();
          _replyingTo = null;
        });

        if (widget.onCommentSubmitted != null) {
          widget.onCommentSubmitted!(commentText);
        }

        if (mounted) {
          Navigator.of(context).pop();
        }
      } else {
        _showErrorSnackBar('Failed to post comment');
      }
    } catch (e) {
      _showErrorSnackBar('Error posting comment: $e');
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _startReply(String username) {
    setState(() {
      _replyingTo = username;
    });
    _focusNode.requestFocus();
    _commentController.text = '@$username ';
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade600,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Colors.grey.shade800,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Comments',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
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
                    : RefreshIndicator(
                  onRefresh: _loadComments,
                  color: Colors.white,
                  backgroundColor: Colors.blue,
                  child: _comments.isEmpty
                      ? const Center(
                    child: Text(
                      'No comments yet\nBe the first to comment!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  )
                      : ListView.builder(
                    controller: scrollController,
                    itemCount: _comments.length,
                    itemBuilder: (context, index) {
                      final comment = _comments[index];
                      return CommentTile(
                        comment: comment,
                        index: index,
                        onReply: () => _startReply(comment.username),
                        serverBaseUrl: 'http://192.168.1.3:8080', // Pass base URL
                      );
                    },
                  ),
                ),
              ),
              if (_replyingTo != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  color: Colors.blue.withOpacity(0.1),
                  child: Row(
                    children: [
                      Text(
                        'Replying to @$_replyingTo',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          setState(() {
                            _replyingTo = null;
                            _commentController.clear();
                          });
                        },
                        color: Colors.blue,
                        splashRadius: 20,
                      ),
                    ],
                  ),
                ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                decoration: BoxDecoration(
                  color: Colors.black,
                  border: Border(
                    top: BorderSide(color: Colors.grey.shade800),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      widget.currentUserAvatar != null
                          ? _buildAvatar(widget.currentUserAvatar!, 'http://192.168.1.3:8080')
                          : const CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.person, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _commentController,
                          focusNode: _focusNode,
                          style: const TextStyle(color: Colors.white),
                          maxLines: 5,
                          minLines: 1,
                          textCapitalization: TextCapitalization.sentences,
                          decoration: InputDecoration(
                            hintText: 'Add a comment...',
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade900,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: _commentController.text.trim().isEmpty
                            ? null
                            : _submitComment,
                        style: TextButton.styleFrom(
                          backgroundColor: _commentController.text.trim().isEmpty
                              ? Colors.blue.withOpacity(0.3)
                              : Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                            : const Text(
                          'Post',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAvatar(String profilePicture, String serverBaseUrl) {
    try {
      // Check if the profilePicture is a base64 string
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

    // Handle URL image
    String imageUrl = profilePicture;
    if (!imageUrl.startsWith('http')) {
      imageUrl = '$serverBaseUrl/uploads/$imageUrl';
    }
    return CircleAvatar(
      radius: 18,
      backgroundImage: NetworkImage(imageUrl),
      backgroundColor: Colors.grey,
      onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.white),
    );
  }
}

class CommentTile extends StatelessWidget {
  final Comment comment;
  final int index;
  final VoidCallback onReply;
  final String serverBaseUrl;

  const CommentTile({
    Key? key,
    required this.comment,
    required this.index,
    required this.onReply,
    required this.serverBaseUrl,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          comment.userAvatar != null
              ? _buildAvatar(comment.userAvatar!)
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
                Row(
                  children: [
                    Text(
                      comment.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _timeAgo(comment.createdAt),
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  comment.text,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: onReply,
                      child: Text(
                        'Reply',
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            children: [
              IconButton(
                icon: Icon(
                  comment.likesCount > 0
                      ? Icons.favorite
                      : Icons.favorite_border,
                  color: comment.likesCount > 0 ? Colors.red : Colors.white,
                  size: 16,
                ),
                onPressed: () {},
                splashRadius: 20,
                constraints: const BoxConstraints(),
                padding: EdgeInsets.zero,
              ),
              if (comment.likesCount > 0)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${comment.likesCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String profilePicture) {
    try {
      // Check if the profilePicture is a base64 string
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

    // Handle URL image
    String imageUrl = profilePicture;
    if (!imageUrl.startsWith('http')) {
      imageUrl = '$serverBaseUrl/uploads/$imageUrl';
    }
    return CircleAvatar(
      radius: 18,
      backgroundImage: NetworkImage(imageUrl),
      backgroundColor: Colors.grey,
      onBackgroundImageError: (_, __) => const Icon(Icons.person, color: Colors.white),
    );
  }

  String _timeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inDays > 7) {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'now';
    }
  }
}

class Comment {
  final String id;
  final String postId;
  final String userId;
  final String username;
  final String text;
  final DateTime createdAt;
  final int likesCount;
  final String? userAvatar;

  Comment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.username,
    required this.text,
    required this.createdAt,
    required this.likesCount,
    this.userAvatar,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      id: json['commentId'].toString(),
      postId: json['postId'].toString(),
      userId: json['userId'].toString(),
      username: json['username'],
      text: json['comment'],
      createdAt: DateTime.tryParse(json['createdAt']) ?? DateTime.now(),
      likesCount: 0,
      userAvatar: json['profilePicture'],
    );
  }
}