import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../models/media_item.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/post_service.dart';
import '../services/user_service.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/posts_provider.dart';
import '../models/user.dart';
// Import for non-web platforms only
import 'dart:io' if (dart.library.html) 'package:flutter/foundation.dart';

class EditPostScreen extends StatefulWidget {
  final List<MediaItem> selectedMedia;
  final Function? onPostCreated;
  
  const EditPostScreen({
    Key? key, 
    required this.selectedMedia,
    this.onPostCreated,
  }) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final PostService _postService = PostService();
  final UserService _userService = UserService();
  List<Map<String, dynamic>> _taggedPeople = [];
  bool _isLoading = false;
  bool _isLoadingFollowers = false;
  List<User> _followers = [];

  @override
  void initState() {
    super.initState();
    _loadFollowers();
  }

  Future<void> _loadFollowers() async {
    setState(() {
      _isLoadingFollowers = true;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      
      if (token != null) {
        final followers = await _userService.getFollowersForTagging(token);
        setState(() {
          _followers = followers;
        });
      }
    } catch (e) {
      print('Error loading followers: $e');
    } finally {
      setState(() {
        _isLoadingFollowers = false;
      });
    }
  }

  void _tagPeople() async {
    if (_isLoadingFollowers) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Still loading followers, please wait...'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_followers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No followers to tag'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Tag People', style: TextStyle(color: Colors.white)),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: _followers.length,
                  itemBuilder: (context, index) {
                    final follower = _followers[index];
                    // Check if this user is already tagged
                    bool isTagged = _taggedPeople.any((tag) => tag['userId'] == follower.userId);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: follower.profilePicture != null
                            ? NetworkImage(follower.profilePicture!)
                            : null,
                        backgroundColor: Colors.grey[800],
                        child: follower.profilePicture == null
                            ? Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      title: Text(
                        follower.username ?? 'Unknown',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        follower.name ?? '',
                        style: TextStyle(color: Colors.grey[400]),
                      ),
                      trailing: IconButton(
                        icon: Icon(
                          isTagged ? Icons.check_circle : Icons.add_circle_outline,
                          color: isTagged ? Colors.blue : Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            if (isTagged) {
                              _taggedPeople.removeWhere((tag) => tag['userId'] == follower.userId);
                            } else {
                              _taggedPeople.add({
                                'userId': follower.userId,
                                'username': follower.username,
                              });
                            }
                          });
                          Navigator.pop(context);
                          _tagPeople(); // Re-open dialog
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Done', style: TextStyle(color: Colors.blue)),
          ),
        ],
      ),
    );
  }

  Future<void> _sharePost() async {
    if (widget.selectedMedia.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final postsProvider = Provider.of<PostsProvider>(context, listen: false);
      
      if (token == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please login first'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Just get the file path
      final String imagePath = widget.selectedMedia.first.path;

      // Extract just the usernames for the API call
      List<String> taggedUsernames = _taggedPeople
          .map((tag) => tag['username'] as String)
          .toList();

      // Call the updated method with file path and tagged people
      final post = await _postService.createPost(
        imagePath,
        _captionController.text,
        token,
        taggedPeople: taggedUsernames,
      );

      if (post != null) {
        // Refresh the posts list
        await postsProvider.fetchPosts(token);
        
        // Call the callback if provided
        if (widget.onPostCreated != null) {
          widget.onPostCreated!();
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to create post'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error sharing post: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'New post',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          _isLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : TextButton(
                  onPressed: _sharePost,
                  child: const Text(
                    'Share',
                    style: TextStyle(color: Colors.blue),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display selected media with platform check
            if (widget.selectedMedia.isNotEmpty)
              Container(
                height: 300,
                width: double.infinity,
                child: _buildMediaPreview(widget.selectedMedia.first.path),
              ),
            // Caption input field
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _captionController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Add caption...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            // Tag people option
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.white),
              title: const Text(
                'Tag people',
                style: TextStyle(color: Colors.white),
              ),
              trailing: _isLoadingFollowers 
                ? SizedBox(
                    width: 16, 
                    height: 16, 
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: _tagPeople,
            ),
            // Display tagged people list
            if (_taggedPeople.isNotEmpty) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Tagged People',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: _taggedPeople.length,
                    itemBuilder: (context, index) {
                      final taggedPerson = _taggedPeople[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          child: Icon(Icons.person, color: Colors.white, size: 18),
                        ),
                        title: Text(
                          taggedPerson['username'] ?? '',
                          style: TextStyle(color: Colors.white),
                        ),
                        trailing: IconButton(
                          icon: Icon(Icons.close, color: Colors.white70),
                          onPressed: () {
                            setState(() {
                              _taggedPeople.removeAt(index);
                            });
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
  
  // Helper method to handle platform differences
  Widget _buildMediaPreview(String path) {
    print('Building media preview for path: $path');
    
    if (kIsWeb) {
      // For web platform - could be blob URL or regular URL
      if (path.startsWith('blob:') || path.startsWith('http')) {
        print('Loading web image from URL: $path');
        return Image.network(
          path,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                    : null,
                color: Colors.white,
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            print('Error loading web image: $error');
            return Container(
              color: Colors.grey[800],
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white54, size: 40),
                    SizedBox(height: 8),
                    Text(
                      'Image load error',
                      style: TextStyle(color: Colors.white60),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      } else {
        // Local file in web platform
        return Center(
          child: Text(
            'Unsupported image source for web',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
    } else {
      // For mobile platforms - should be a local file path
      try {
        print('Loading mobile image from file: $path');
        // Use the File class only in non-web environment
        return _buildNativeImagePreview(path);
      } catch (e) {
        print('Exception loading image file: $e');
        return Center(
          child: Text(
            'Error: $e',
            style: TextStyle(color: Colors.white),
          ),
        );
      }
    }
  }
  
  // This is only called on mobile platforms
  Widget _buildNativeImagePreview(String path) {
    // Only for non-web platforms
    if (kIsWeb) {
      return Text('Native image preview not supported on web');
    }
    
    return Image.file(
      File(path),  // File from dart:io, not available on web
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        print('Error loading image file: $error');
        return Center(
          child: Text(
            'Failed to load image: $error',
            style: TextStyle(color: Colors.white),
          ),
        );
      },
    );
  }
}