import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:practice_widgets/instagram/story_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import '../models/media_item.dart';
import 'edit_post_screen.dart';
class NewPostScreen extends StatefulWidget {
  final List<String>? initialMedia;
  const NewPostScreen({Key? key, this.initialMedia}) : super(key: key);

  @override
  _NewPostScreenState createState() => _NewPostScreenState();
}

class _NewPostScreenState extends State<NewPostScreen> {
  final List<String> _postTypes = ['POST', 'STORY'];
  String _selectedType = 'POST';
  List<MediaItem> _mediaItems = [];
  List<MediaItem> _selectedMedia = [];
  bool _isSelectingMultiple = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (widget.initialMedia != null && widget.initialMedia!.isNotEmpty) {
      _selectedMedia = widget.initialMedia!
          .map((path) => MediaItem(
        id: path,
        path: path,
        type: MediaType.image,
        createdAt: DateTime.now(),
      ))
          .toList();
    }
    _loadMedia();
  }

  Future<void> _loadMedia() async {
    var status = await Permission.photos.request();
    if (status.isGranted) {
      final List<XFile> images = await _picker.pickMultiImage();
      setState(() {
        _mediaItems = images
            .map((xFile) => MediaItem(
          id: xFile.path,
          path: xFile.path,
          type: MediaType.image,
          createdAt: DateTime.now(),
        ))
            .toList();
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
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'New post',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          TextButton(
            onPressed: _selectedMedia.isNotEmpty
                ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditPostScreen(
                    selectedMedia: _selectedMedia,
                    onPostCreated: () {
                      // This will execute after post creation
                      // We'll return to main screen and it will handle refresh
                    },
                  ),
                ),
              );
            }
                : null,
            child: Text(
              'Next',
              style: TextStyle(
                color: _selectedMedia.isNotEmpty
                    ? Colors.blue
                    : Colors.blue.withOpacity(0.5),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _buildMediaGrid(),
          ),
          _buildBottomSection(),
        ],
      ),
    );
  }

  Widget _buildMediaGrid() {
    if (_mediaItems.isEmpty) {
      return const Center(
        child: Text(
          'No media available',
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: _mediaItems.length,
      itemBuilder: (context, index) {
        final item = _mediaItems[index];
        final isSelected = _selectedMedia.contains(item);

        return GestureDetector(
          onTap: () {
            if (_isSelectingMultiple) {
              setState(() {
                if (isSelected) {
                  _selectedMedia.remove(item);
                } else {
                  _selectedMedia.add(item);
                }
              });
            } else {
              setState(() {
                _selectedMedia = [item];
              });
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildMediaPreview(item.path),
              if (isSelected)
                Container(
                  color: Colors.blue.withOpacity(0.3),
                  alignment: Alignment.topRight,
                  padding: const EdgeInsets.all(5),
                  child: const CircleAvatar(
                    backgroundColor: Colors.blue,
                    radius: 10,
                    child: Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMediaPreview(String path) {
    if (kIsWeb) {
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
              child: Icon(Icons.image_not_supported, color: Colors.white54),
            ),
          );
        },
      );
    } else {
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('Error loading file image: $error');
          return Container(
            color: Colors.grey[800],
            child: Center(
              child: Icon(Icons.image_not_supported, color: Colors.white54),
            ),
          );
        },
      );
    }
  }

  Widget _buildBottomSection() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Recents',
                    style: TextStyle(color: Colors.white),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                  ),
                ],
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _isSelectingMultiple = !_isSelectingMultiple;
                        if (!_isSelectingMultiple) {
                          _selectedMedia =
                          _selectedMedia.isEmpty ? [] : [_selectedMedia.first];
                        }
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'SELECT MULTIPLE',
                            style: TextStyle(color: Colors.white, fontSize: 12),
                          ),
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isSelectingMultiple
                                  ? Colors.blue
                                  : Colors.transparent,
                              border: Border.all(
                                color: _isSelectingMultiple ? Colors.blue : Colors.white,
                              ),
                            ),
                            child: _isSelectingMultiple
                                ? const Icon(Icons.check, color: Colors.white, size: 12)
                                : const SizedBox(height: 12, width: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.camera_alt, color: Colors.white),
                    onPressed: () async {
                      final XFile? photo =
                      await _picker.pickImage(source: ImageSource.camera);
                      if (photo != null) {
                        final newMedia = MediaItem(
                          id: photo.path,
                          path: photo.path,
                          type: MediaType.image,
                          createdAt: DateTime.now(),
                        );
                        setState(() {
                          _mediaItems.insert(0, newMedia);
                          if (!_isSelectingMultiple) {
                            _selectedMedia = [newMedia];
                          }
                        });
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  "You've given Instagram access to a select number of photos and videos",
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ),
              Text(
                'Manage',
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
        Container(
          height: 50,
          width: double.infinity,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.grey, width: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _postTypes.map((type) => _buildPostTypeButton(type)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPostTypeButton(String type) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        if (type == 'STORY' && _selectedMedia.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => StoryScreen(
                initialMedia: File(_selectedMedia.first.path),
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Text(
          type,
          style: TextStyle(
            color: _selectedType == type ? Colors.white : Colors.grey,
            fontWeight: _selectedType == type ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}