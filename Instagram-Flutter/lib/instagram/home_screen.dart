import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../data/providers/auth_provider.dart';
import '../data/providers/posts_provider.dart';
import '../models/post.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Helper method to get the base URL for server resources
  String get serverBaseUrl {
    if (Platform.isAndroid && !kIsWeb) {
      // Android emulator needs 10.0.2.2 to access host
      return 'http://10.0.2.2:8080';
    } else if (kIsWeb) {
      // Web always needs actual address
      return 'http://localhost:8080';
    } else {
      // iOS simulator can use localhost, physical devices need IP
      return 'http://localhost:8080';
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
                return PostItem(post: posts[index]);
              },
            );
          },
        ),
      ),
    );
  }
}

class PostItem extends StatelessWidget {
  final Post post;
  
  // Helper method to get the base URL for server resources
  String get serverBaseUrl {
    if (Platform.isAndroid && !kIsWeb) {
      // Android emulator needs 10.0.2.2 to access host
      return 'http://10.0.2.2:8080';
    } else if (kIsWeb) {
      // Web always needs actual address
      return 'http://localhost:8080';
    } else {
      // iOS simulator can use localhost, physical devices need IP
      return 'http://localhost:8080';
    }
  }

  const PostItem({Key? key, required this.post}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, color: Colors.white, size: 18),
                ),
                SizedBox(width: 8),
                Text(
                  post.userId != null ? 'User ${post.userId}' : 'Instagram User',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          _buildPostImage(post),
            
          // Post actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.favorite_border, color: Colors.white),
                  onPressed: () {},
                ),
                IconButton(
                  icon: Icon(Icons.chat_bubble_outline, color: Colors.white),
                  onPressed: () {},
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
          if (post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                post.caption,
                style: TextStyle(color: Colors.white),
              ),
            ),
            
          // Date
          if (post.createdAt != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
              child: Text(
                '${post.createdAt!.day}/${post.createdAt!.month}/${post.createdAt!.year}',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildPostImage(Post post) {
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
        imageUrl = '$serverBaseUrl/uploads/$imageUrl';
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
}
