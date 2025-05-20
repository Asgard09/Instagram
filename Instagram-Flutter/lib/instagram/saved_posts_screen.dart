import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';

import '../data/providers/auth_provider.dart';
import '../data/providers/user_provider.dart';
import '../models/post.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({Key? key}) : super(key: key);

  @override
  _SavedPostsScreenState createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  bool _isLoading = false;
  List<Post> _savedPosts = [];
  String? _error;
  int? _currentUserId;
  
  // Helper method to get the base URL for server resources
  String get serverBaseUrl {
    if (kIsWeb) {
      // Use the specific IP for web
      return 'http://192.168.100.23:8080';
    } else {
      // For mobile platforms
      return 'http://192.168.100.23:8080';
    }
  }
  
  @override
  void initState() {
    super.initState();
    _loadSavedPosts();
  }
  
  Future<void> _loadSavedPosts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        setState(() {
          _error = 'You need to be logged in to view saved posts';
          _isLoading = false;
        });
        return;
      }
      
      // Get current user ID
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      if (userProvider.user == null) {
        await userProvider.fetchCurrentUser(token);
      }
      
      final userId = userProvider.user?.userId;
      if (userId == null) {
        setState(() {
          _error = 'Could not determine user ID';
          _isLoading = false;
        });
        return;
      }
      
      _currentUserId = userId;
      
      // Fetch saved posts
      final response = await http.get(
        Uri.parse('$serverBaseUrl/api/posts/getAll/$userId'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> postsJson = json.decode(response.body);
        
        // Extract posts from the saved posts response
        List<Post> posts = [];
        for (var item in postsJson) {
          if (item.containsKey('post')) {
            // If the response contains a nested post object
            final postData = item['post'];
            posts.add(Post.fromJson(postData));
          } else {
            // If the response is already the post data
            posts.add(Post.fromJson(item));
          }
        }
        
        setState(() {
          _savedPosts = posts;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load saved posts: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error loading saved posts: $e';
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Saved Posts',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadSavedPosts,
        color: Colors.white,
        backgroundColor: Colors.blue,
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _error!,
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadSavedPosts,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _savedPosts.isEmpty
                    ? const Center(
                        child: Text(
                          'No saved posts yet',
                          style: TextStyle(color: Colors.white),
                        ),
                      )
                    : _buildSavedPostsGrid(),
      ),
    );
  }
  
  Widget _buildSavedPostsGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemCount: _savedPosts.length,
      itemBuilder: (context, index) {
        final post = _savedPosts[index];
        return _buildGridItem(post);
      },
    );
  }
  
  Widget _buildGridItem(Post post) {
    // Determine the image URL to display
    String? imageUrl;
    if (post.imageUrls != null && post.imageUrls!.isNotEmpty) {
      imageUrl = post.imageUrls!.first;
      if (!imageUrl.startsWith('http')) {
        imageUrl = '$serverBaseUrl/uploads/$imageUrl';
      }
    }
    
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to post detail view
      },
      child: Container(
        color: Colors.grey[900],
        child: imageUrl != null
            ? Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                          : null,
                      color: Colors.white,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.white),
                  );
                },
              )
            : const Center(
                child: Icon(Icons.image, color: Colors.white54),
              ),
      ),
    );
  }
} 