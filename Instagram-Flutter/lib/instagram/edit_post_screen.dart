import 'package:flutter/material.dart';
import 'dart:io';
import 'dart:convert';
import '../models/media_item.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/post_service.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';

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

      // Convert image to base64
      String imageBase64;
      if (kIsWeb) {
        // For web, you'd need to handle this differently
        // This is a placeholder
        imageBase64 = widget.selectedMedia.first.path;
      } else {
        // Read file and convert to base64
        final File imageFile = File(widget.selectedMedia.first.path);
        final List<int> imageBytes = await imageFile.readAsBytes();
        imageBase64 = base64Encode(imageBytes);
      }

      final post = await _postService.createPost(
        imageBase64,
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
    if (kIsWeb) {
      // For web platform
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Center(
            child: Text(
              'Failed to load image',
              style: TextStyle(color: Colors.white),
            ),
          );
        },
      );
    } else {
      // For mobile platforms
      return Image.file(
        File(path),
        fit: BoxFit.cover,
      );
    }
  }
}