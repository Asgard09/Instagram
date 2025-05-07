import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/providers/auth_provider.dart';
import '../data/providers/posts_provider.dart';
import '../models/post.dart';
import '../widgets/popup_comment.dart';
import '../widgets/popup_listlike.dart';
import 'user_profile_screen.dart';
import '../data/providers/likes_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Helper method to get the base URL for server resources
  String get serverBaseUrl {
    if (kIsWeb) {
      // Use the specific IP for web
      return 'http://192.168.1.5:8080';
    } else {
      // For mobile platforms
      return 'http://192.168.1.5:8080';
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch posts when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadPosts();
    });
  }

  Future<void> _loadPosts() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await Provider.of<PostsProvider>(context, listen: false).fetchPosts(token);
    }
  }

  Future<void> _refreshPosts() async {
    await _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Instagram',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite_border, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshPosts,
        child: Consumer<PostsProvider>(
          builder: (context, postsProvider, child) {
            if (postsProvider.isLoading && postsProvider.posts.isEmpty) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }

            if (postsProvider.error != null && postsProvider.posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load posts',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: _loadPosts,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            final posts = postsProvider.posts;

            if (posts.isEmpty) {
              return Center(
                child: Text(
                  'No posts yet',
                  style: TextStyle(color: Colors.white),
                ),
              );
            }

            return ListView.builder(
              itemCount: posts.length,
              itemBuilder: (context, index) {
                return PostItem(
                  post: posts[index],
                  serverBaseUrl: serverBaseUrl,
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class PostItem extends StatefulWidget {
  final Post post;
  final String serverBaseUrl;

  const PostItem({
    Key? key,
    required this.post,
    required this.serverBaseUrl,
  }) : super(key: key);

  @override
  _PostItemState createState() => _PostItemState();
}

class _PostItemState extends State<PostItem> {
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchLikeData();
  }
  void _showLikesPopup() {
    showDialog(
      context: context,
      builder: (context) => LikeListPopup(
        postId: int.parse(widget.post.id.toString()),
        onClose: () => Navigator.pop(context),
      ),
    );
  }
  void _showCommentsSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        postId: int.parse(widget.post.id.toString()),
        onCommentSubmitted: (comment) {
        },
      ),
    );
  }
  Future<void> _fetchLikeData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null && widget.post.id != null) {
      int postId = int.parse(widget.post.id.toString());

      // Get the like status
      await Provider.of<LikesProvider>(context, listen: false)
          .fetchLikeStatus(token, postId);

      // Get the like count
      await Provider.of<LikesProvider>(context, listen: false)
          .fetchLikeCount(token, postId);

      // Update local state
      setState(() {
        _isLiked = Provider.of<LikesProvider>(context, listen: false)
            .isPostLiked(postId);
        _likeCount = Provider.of<LikesProvider>(context, listen: false)
            .getLikeCount(postId);
      });
    }
  }

  Future<void> _toggleLike() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null && widget.post.id != null) {
      int postId = int.parse(widget.post.id.toString());

      bool success = await Provider.of<LikesProvider>(context, listen: false)
          .toggleLike(token, postId);

      if (success) {
        setState(() {
          _isLiked = Provider.of<LikesProvider>(context, listen: false)
              .isPostLiked(postId);
          _likeCount = Provider.of<LikesProvider>(context, listen: false)
              .getLikeCount(postId);
        });
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Debug post data
    print('Building PostItem with post ID: ${widget.post.id}');
    print('Post username: ${widget.post.username}');
    print('Post userId: ${widget.post.userId}');

    // Determine username to display
    String displayName = "Instagram User";
    if (widget.post.username != null && widget.post.username!.isNotEmpty) {
      displayName = widget.post.username!;
      print('Using post.username: $displayName');
    } else if (widget.post.userId != null) {
      displayName = 'User ${widget.post.userId}';
      print('Using post.userId: $displayName');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Post header
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                _buildUserAvatar(),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: () {
                    if (widget.post.userId != null) {
                      final userId = widget.post.userId.toString();
                      print('Navigating to profile from username tap - userId: $userId, username: ${widget.post.username}');

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            userId: userId,
                            initialUsername: widget.post.username,
                          ),
                        ),
                      );
                    } else if (widget.post.username != null && widget.post.username!.isNotEmpty) {
                      // If no userId but we have username, try to navigate with just the username
                      print('No userId available, trying to navigate with just username: ${widget.post.username}');
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => UserProfileScreen(
                            userId: "0", // Use a placeholder
                            initialUsername: widget.post.username,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Cannot view profile: User ID not available'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: Text(
                    displayName,
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.more_vert, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Post image - handle both URL and Base64
          _buildPostImage(),

          // Post actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: _isLoading
                      ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleLike,
                ),
                if (_likeCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: GestureDetector(
                      onTap: _showLikesPopup,
                      child: Text(
                        '$_likeCount',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ),


                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline, color: Colors.white),
                  onPressed: _showCommentsSheet,
                ),
                IconButton(
                  icon: Icon(Icons.send_outlined, color: Colors.white),
                  onPressed: () {},
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.bookmark_border, color: Colors.white),
                  onPressed: () {},
                ),
              ],
            ),
          ),

          // Caption
          if (widget.post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                widget.post.caption,
                style: TextStyle(color: Colors.white),
              ),
            ),

          // Date
          if (widget.post.createdAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                '${widget.post.createdAt!.day}/${widget.post.createdAt!.month}/${widget.post.createdAt!.year}',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPostImage() {
    Post post = widget.post;
    // First check if we have URLs
    if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
      String imageUrl = post.imageUrls!.first;

      // Check if this is an error indicator path
      if (imageUrl.contains("ERROR_BASE64_DECODE") || imageUrl.contains("ERROR_")) {
        return Container(
          height: 300,
          color: Colors.grey[800],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, color: Colors.white54, size: 50),
                SizedBox(height: 10),
                Text('Image processing failed', style: TextStyle(color: Colors.white)),
                Text('Please try uploading again', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        );
      }

      // Add base URL if the image URL is a relative path
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${widget.serverBaseUrl}/uploads/$imageUrl';
      }

      print('Loading image from URL: $imageUrl');

      return Image.network(
        imageUrl,
        height: 300,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 300,
            color: Colors.grey[800],
            child: Center(child: CircularProgressIndicator()),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          print('Error loading image URL: $error');
          return Container(
            height: 300,
            color: Colors.grey[800],
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported, color: Colors.white54, size: 40),
                  SizedBox(height: 8),
                  Text('Could not load image', style: TextStyle(color: Colors.white)),
                  Text(error.toString().length > 50 ? error.toString().substring(0, 50) + '...' : error.toString(),
                      style: TextStyle(color: Colors.red, fontSize: 10)),
                ],
              ),
            ),
          );
        },
      );
    }

    // Then check for Base64 image
    else if (post.imageBase64 != null && post.imageBase64!.isNotEmpty) {
      try {
        // Try to decode the base64 string
        String base64String = post.imageBase64!;

        // If it has a data:image prefix, remove it
        if (base64String.contains(';base64,')) {
          base64String = base64String.split(';base64,').last;
        } else if (base64String.contains(',')) {
          base64String = base64String.split(',').last;
        }

        // Clean base64 string (remove any whitespace)
        base64String = base64String.trim().replaceAll(RegExp(r'\s+'), '');

        // Add padding if needed
        while (base64String.length % 4 != 0) {
          base64String += '=';
        }

        final imageBytes = base64Decode(base64String);

        print('Successfully decoded base64 image of ${imageBytes.length} bytes');

        return Image.memory(
          imageBytes,
          height: 300,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('Error displaying decoded image: $error');
            return Container(
              height: 300,
              color: Colors.grey[800],
              child: Center(
                child: Icon(Icons.image_not_supported, color: Colors.white54),
              ),
            );
          },
        );
      } catch (e) {
        print('Base64 decode error: $e');
        return Container(
          height: 300,
          color: Colors.grey[800],
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.broken_image, color: Colors.white54),
                Text('Failed to load image', style: TextStyle(color: Colors.white54)),
                Text('Error: ${e.toString().length > 30 ? e.toString().substring(0, 30) + '...' : e.toString()}',
                    style: TextStyle(color: Colors.red, fontSize: 10)),
              ],
            ),
          ),
        );
      }
    }

    // No image available
    else {
      return Container(
        height: 300,
        color: Colors.grey[800],
        child: Center(
          child: Text('No image', style: TextStyle(color: Colors.white54)),
        ),
      );
    }
  }
  Widget _buildUserAvatar() {
    // Debug - print userId directly to check its value
    print('Building avatar for post with userId: ${widget.post.userId}, username: ${widget.post.username}');

    // If we have a username, try to fetch user info for profile picture
    if (widget.post.username != null && widget.post.username!.isNotEmpty) {
      final String apiUrl = '${widget.serverBaseUrl}/api/users/by-username/${widget.post.username}';
      final token = Provider.of<AuthProvider>(context, listen: false).token;

      return GestureDetector(
        onTap: () {
          // Check and convert userId to ensure it's a proper value
          if (widget.post.userId != null) {
            var userId = widget.post.userId.toString();
            print('Navigating to profile from avatar - userId: $userId, username: ${widget.post.username}');

            // Debug - print what gets passed to the UserProfileScreen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => UserProfileScreen(
                  userId: userId,
                  initialUsername: widget.post.username,
                ),
              ),
            );
          } else {
            print('Cannot navigate to profile: userId is null');
            // Try to navigate with just the username if available
            if (widget.post.username != null && widget.post.username!.isNotEmpty) {
              print('Attempting to navigate with just username: ${widget.post.username}');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    userId: "0", // Use a placeholder
                    initialUsername: widget.post.username,
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Cannot view profile: User information not available'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
        child: FutureBuilder<http.Response>(
          future: http.get(
            Uri.parse(apiUrl),
            headers: {
              'Authorization': 'Bearer $token',
              'Content-Type': 'application/json',
            },
          ),
          builder: (context, snapshot) {
            // If we successfully got user data
            if (snapshot.connectionState == ConnectionState.done &&
                snapshot.data != null &&
                snapshot.data!.statusCode == 200) {

              try {
                final userData = jsonDecode(snapshot.data!.body);
                final profilePicture = userData['profilePicture'];
                final userId = userData['userId']; // Extract userId from the API response

                print('User API response success - userId from API: $userId, username: ${widget.post.username}');

                // Store profile picture for navigation
                String? profilePictureToPass = profilePicture;

                // If user has a profile picture
                if (profilePicture != null && profilePicture.isNotEmpty) {
                  // Handle base64 image
                  if (profilePicture.contains(';base64,') || profilePicture.contains(',')) {
                    try {
                      String base64String = profilePicture;

                      // Extract the actual base64 string
                      if (base64String.contains(';base64,')) {
                        base64String = base64String.split(';base64,').last;
                      } else if (base64String.contains(',')) {
                        base64String = base64String.split(',').last;
                      }

                      base64String = base64String.trim();
                      final imageBytes = base64Decode(base64String);

                      return GestureDetector(
                        onTap: () {
                          // Use the userId from the API response if available, otherwise fallback to the post's userId
                          final userIdToUse = userId != null ? userId.toString() : (widget.post.userId != null ? widget.post.userId.toString() : "0");
                          print('Navigating to profile from base64 avatar - userId: $userIdToUse');

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserProfileScreen(
                                userId: userIdToUse,
                                initialUsername: widget.post.username,
                                initialProfilePicture: profilePictureToPass,
                              ),
                            ),
                          );
                        },
                        child: CircleAvatar(
                          radius: 16,
                          backgroundImage: MemoryImage(imageBytes),
                          backgroundColor: Colors.grey,
                        ),
                      );
                    } catch (e) {
                      print('Error decoding base64 image: $e');
                    }
                  }
                  // Handle URL image
                  else {
                    String imageUrl = profilePicture;
                    if (!imageUrl.startsWith('http')) {
                      imageUrl = '${widget.serverBaseUrl}/uploads/$imageUrl';
                    }

                    return GestureDetector(
                      onTap: () {
                        // Use the userId from the API response if available, otherwise fallback to the post's userId
                        final userIdToUse = userId != null ? userId.toString() : (widget.post.userId != null ? widget.post.userId.toString() : "0");
                        print('Navigating to profile from URL avatar - userId: $userIdToUse');

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserProfileScreen(
                              userId: userIdToUse,
                              initialUsername: widget.post.username,
                              initialProfilePicture: profilePictureToPass,
                            ),
                          ),
                        );
                      },
                      child: CircleAvatar(
                        radius: 16,
                        backgroundImage: NetworkImage(imageUrl),
                        backgroundColor: Colors.grey,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('Error parsing user data: $e');
              }
            } else if (snapshot.connectionState == ConnectionState.done) {
              print('User API request failed: ${snapshot.data?.statusCode ?? "No data"}');
            }

            // Default avatar when no username is available
            return GestureDetector(
              onTap: () {
                if (widget.post.userId != null) {
                  final userId = widget.post.userId.toString();
                  print('Navigating to profile from default avatar - userId: $userId');

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfileScreen(
                        userId: userId,
                        initialUsername: widget.post.username,
                      ),
                    ),
                  );
                } else {
                  print('Cannot navigate: userId is null');
                }
              },
              child: CircleAvatar(
                radius: 16,
                backgroundColor: Colors.grey,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            );
          },
        ),
      );
    }

    // Default avatar when no username is available
    return GestureDetector(
      onTap: () {
        if (widget.post.userId != null) {
          final userId = widget.post.userId.toString();
          print('Navigating to profile from default avatar (no username) - userId: $userId');

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => UserProfileScreen(
                userId: userId,
              ),
            ),
          );
        } else {
          print('Cannot navigate: no userId and no username available');
        }
      },
      child: CircleAvatar(
        radius: 16,
        backgroundColor: Colors.grey,
        child: Icon(Icons.person, color: Colors.white, size: 18),
      ),
    );
  }
}