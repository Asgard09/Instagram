import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/gestures.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/posts_provider.dart';
import '../data/providers/user_provider.dart'; // Added for accessing current user info
import '../data/providers/likes_provider.dart';
import '../data/providers/comments_provider.dart';
import '../models/post.dart';
import '../widgets/popup_comment.dart';
import '../widgets/popup_listlike.dart';
import 'main_screen.dart';
import 'user_profile_screen.dart';
import 'profile_screen.dart'; // Import ProfileScreen
import 'chat_list_screen.dart'; // Import ChatListScreen
import '../services/user_service.dart'; // Added for user service to get current user

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  // Helper method to get the base URL for server resources
  String get serverBaseUrl {
    if (kIsWeb) {
      // Use the specific IP for web
      return 'http://172.22.98.43:8080';
    } else {
      // For mobile platforms
      return 'http://172.22.98.43:8080';
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // This will refresh posts when the screen is revisited
    _loadPosts();
  }

  Future<void> _loadPosts() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await Provider.of<PostsProvider>(context, listen: false).fetchPosts(token);
    }
  }

  // Make this method public so it can be called from outside using a GlobalKey
  Future<void> refreshPosts() async {
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
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ChatListScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: refreshPosts,
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
  int _commentCount = 0;
  bool _isLoading = false;
  bool _isNavigatingToTaggedUser = false;
  int? _currentUserId; // Store current user ID

  @override
  void initState() {
    super.initState();
    _fetchLikeData();
    _fetchCommentCount();
    _getCurrentUserId(); // Get current user ID when component initializes
  }

  // Function to get the current user ID from token
  Future<void> _getCurrentUserId() async {
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
          _currentUserId = currentUser.userId;
        });
        print('Current user ID: $_currentUserId');
      } else {
        print('Failed to get current user or user ID is null');
      }
    } catch (e) {
      print('Error getting current user ID: $e');
    }
  }

  // Fetch comment count
  Future<void> _fetchCommentCount() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null && widget.post.id != null) {
      int postId = int.parse(widget.post.id.toString());

      // Get the comment count
      await Provider.of<CommentsProvider>(context, listen: false)
          .fetchCommentCount(token, postId);

      // Update local state
      setState(() {
        _commentCount = Provider.of<CommentsProvider>(context, listen: false)
            .getCommentCount(postId);
      });
    }
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
    final postId = int.parse(widget.post.id.toString());
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CommentsBottomSheet(
        postId: postId,
        onCommentSubmitted: (comment) {
          // When a comment is added, increment the count
          Provider.of<CommentsProvider>(context, listen: false)
              .incrementCommentCount(postId);
          
          // Update the local state
          setState(() {
            _commentCount = Provider.of<CommentsProvider>(context, listen: false)
                .getCommentCount(postId);
          });
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

  // Navigate to profile based on whether it's the current user or not
  void _navigateToProfile(String userId, {String? username, String? profilePicture}) {
    print('Navigation check - Post userId: $userId, Current userId: $_currentUserId');

    // Convert to strings for reliable comparison
    String postUserId = userId.toString();
    String? currentUserId = _currentUserId?.toString();

    // Check if this is the current logged-in user
    if (currentUserId != null && postUserId == currentUserId) {
      print('Navigating to ProfileScreen (current user)');

      // Use Navigator to pop back to MainScreen and rebuild it with the profile tab
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => MainScreen(initialTabIndex: 4), // Pass the profile tab index
        ),
            (Route<dynamic> route) => false, // Remove all previous routes
      );
    } else {
      print('Navigating to UserProfileScreen (different user)');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserProfileScreen(
            userId: userId,
            initialUsername: username,
            initialProfilePicture: profilePicture,
          ),
        ),
      );
    }
  }

  // Add this method to build loading overlay when navigating to tagged user
  Widget _buildLoadingOverlay() {
    if (!_isNavigatingToTaggedUser) return Container();
    
    return Container(
      color: Colors.black.withOpacity(0.3),
      width: double.infinity,
      height: double.infinity,
      child: Center(
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 15),
              Text(
                'Opening profile...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
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

    return Stack(
      children: [
        // Post content
        Container(
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
                          print('Username tap - userId: $userId, username: ${widget.post.username}');

                          _navigateToProfile(
                            userId,
                            username: widget.post.username,
                          );
                        } else if (widget.post.username != null && widget.post.username!.isNotEmpty) {
                          // If no userId but we have username, try to navigate with just the username
                          print('No userId available, trying with just username: ${widget.post.username}');
                          _navigateToProfile(
                            "0", // Use a placeholder
                            username: widget.post.username,
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
                        padding: const EdgeInsets.only(left: 0.0),
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
                    if (_commentCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 0.0),
                        child: GestureDetector(
                          onTap: _showCommentsSheet,
                          child: Text(
                            '$_commentCount',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
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

              // Caption with rich text for clickable tagged users
              if ((widget.post.displayCaption != null && widget.post.displayCaption!.isNotEmpty) || 
                  (widget.post.caption.isNotEmpty))
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                  child: _buildRichCaption(),
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
        ),
        // Loading overlay
        _buildLoadingOverlay(),
      ],
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
            print('Avatar tap - userId: $userId, username: ${widget.post.username}');

            _navigateToProfile(
              userId,
              username: widget.post.username,
            );
          } else {
            print('Cannot navigate to profile: userId is null');
            // Try to navigate with just the username if available
            if (widget.post.username != null && widget.post.username!.isNotEmpty) {
              print('Attempting to navigate with just username: ${widget.post.username}');
              _navigateToProfile(
                "0", // Use a placeholder
                username: widget.post.username,
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
                          print('Base64 avatar tap - userId: $userIdToUse');

                          _navigateToProfile(
                            userIdToUse,
                            username: widget.post.username,
                            profilePicture: profilePictureToPass,
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
                        print('URL avatar tap - userId: $userIdToUse');

                        _navigateToProfile(
                          userIdToUse,
                          username: widget.post.username,
                          profilePicture: profilePictureToPass,
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
                  print('Default avatar tap - userId: $userId');

                  _navigateToProfile(
                    userId,
                    username: widget.post.username,
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
          print('Default avatar (no username) tap - userId: $userId');

          _navigateToProfile(
            userId,
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

  Widget _buildRichCaption() {
    String captionText = widget.post.displayCaption ?? widget.post.caption;
    
    // If there's no tag, just return a simple Text widget
    if (!captionText.contains('@')) {
      return Text(
        captionText,
        style: TextStyle(color: Colors.white),
      );
    }
    
    List<TextSpan> spans = [];

    // Regular expression to find tagged usernames
    RegExp regExp = RegExp(r'@[a-zA-Z0-9_]+');
    Iterable<RegExpMatch> matches = regExp.allMatches(captionText);

    int lastIndex = 0;
    for (var match in matches) {
      // Add text before the match
      if (match.start > lastIndex) {
        spans.add(TextSpan(
          text: captionText.substring(lastIndex, match.start),
          style: TextStyle(color: Colors.white),
        ));
      }

      // Get the username without @ symbol
      String username = match.group(0)!.substring(1);
      
      // Add the match as a clickable text span
      spans.add(TextSpan(
        text: match.group(0),
        style: TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          backgroundColor: Colors.blue.withOpacity(0.1), // Light blue background
          decoration: TextDecoration.underline,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            if (_isNavigatingToTaggedUser) return;

            setState(() {
              _isNavigatingToTaggedUser = true;
            });

            print('Tagged username clicked: $username');
            
            // Try to get the user ID from the username
            final token = Provider.of<AuthProvider>(context, listen: false).token;
            if (token != null) {
              try {
                final userService = UserService();
                final userId = await userService.getUserIdByUsername(username, token);
                
                if (userId != null) {
                  _navigateToProfile(
                    userId,
                    username: username,
                  );
                } else {
                  // User not found
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Could not find user profile for @$username'),
                      backgroundColor: Colors.red,
                    ),
                  );
                  
                  // Fallback to using just the username
                  _navigateToProfile(
                    "0", // Use a placeholder
                    username: username,
                  );
                }
              } catch (e) {
                print('Error navigating to tagged user: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error accessing user profile: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }

            setState(() {
              _isNavigatingToTaggedUser = false;
            });
          },
      ));

      lastIndex = match.end;
    }

    // Add remaining text after the last match
    if (lastIndex < captionText.length) {
      spans.add(TextSpan(
        text: captionText.substring(lastIndex),
        style: TextStyle(color: Colors.white),
      ));
    }

    return RichText(
      text: TextSpan(
        children: spans,
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}