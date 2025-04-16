import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../models/media_item.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/post_service.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/posts_provider.dart';
import '../services/platform_helper_io.dart' if (dart.library.html) '../services/platform_helper_web.dart';

class EditPostScreen extends StatefulWidget {
  final List<MediaItem> selectedMedia;
  const EditPostScreen({Key? key, required this.selectedMedia}) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  final PostService _postService = PostService();
  List<String> _taggedPeople = [];
  bool _isLoading = false;

  void _tagPeople() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tag People'),
        content: TextField(
          decoration: const InputDecoration(hintText: 'Enter username'),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
      ),
    );
    if (result != null && result.isNotEmpty) {
      setState(() {
        _taggedPeople.add(result);
      });
    }
  }

  Future<void> _sharePost() async {
    if (widget.selectedMedia.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      
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

      // Call the updated method with file path
      final post = await _postService.createPost(
        imagePath,
        _captionController.text,
        token,
      );

      if (post != null) {
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
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text(
                'Tag people',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: _tagPeople,
            ),
            // Display tagged people list
            if (_taggedPeople.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
                  spacing: 8,
                  children: _taggedPeople
                      .map((person) => Chip(
                    label: Text(person),
                    onDeleted: () {
                      setState(() {
                        _taggedPeople.remove(person);
                      });
                    },
                  ))
                      .toList(),
                ),
              ),
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
          errorBuilder: (context, error, stackTrace) {
            print('Error loading web image: $error');
            return Center(
              child: Text(
                'Failed to load image: $error',
                style: TextStyle(color: Colors.white),
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
        return Image.file(
          File(path),
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
}