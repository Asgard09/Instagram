import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import 'new_post_screen.dart';
class StoryScreen extends StatefulWidget {
  final File? initialMedia;
  const StoryScreen({Key? key, this.initialMedia}) : super(key: key);

  @override
  _StoryScreenState createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  File? _mediaFile;
  final List<String> _postTypes = ['POST', 'STORY'];
  String _selectedType = 'STORY';
  List<Widget> _storyTools = [];
  int _selectedToolIndex = -1;

  @override
  void initState() {
    super.initState();
    _mediaFile = widget.initialMedia;
    _initStoryTools();
  }

  void _initStoryTools() {
    _storyTools = [
      _buildToolItem('Create', Icons.text_fields, 0),
      _buildToolItem('Boomerang', Icons.abc_sharp, 1),
      _buildToolItem('Layout', Icons.grid_view, 2),
    ];
  }

  Widget _buildToolItem(String label, IconData icon, int index) {
    bool isSelected = _selectedToolIndex == index;
    Color bgColor = isSelected ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.6);

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedToolIndex = index;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: bgColor,
        child: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Media display area
          _mediaFile != null
              ? Container(
            width: double.infinity,
            height: double.infinity,
            child: Image.file(
              _mediaFile!,
              fit: BoxFit.cover,
            ),
          )
              : Container(
            width: double.infinity,
            height: double.infinity,
            color: Colors.grey[800],
            child: const Center(
              child: Text(
                'No media selected',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),

          // Color gradient strips at top
          Container(
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.green.withOpacity(0.7),
                  Colors.yellow.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          // Story tools on the left
          Positioned(
            left: 0,
            bottom: 100,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: _storyTools,
              ),
            ),
          ),

          // Top controls
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.text_fields, color: Colors.white),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Add Text'),
                              content: TextField(
                                onSubmitted: (value) {
                                  Navigator.pop(context);
                                  // TODO: Add text overlay logic
                                },
                              ),
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.brush, color: Colors.white),
                        onPressed: () {
                          // TODO: Add drawing function
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.settings, color: Colors.white),
                        onPressed: () {
                          // TODO: Add settings function
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Circle capture button
                Container(
                  padding: const EdgeInsets.only(bottom: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: _captureMedia,
                        child: Container(
                          width: 70,
                          height: 70,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: Center(
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Post types (POST, STORY)
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: _postTypes.map((type) => _buildPostTypeButton(type)).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostTypeButton(String type) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
        if (type == 'POST' && _mediaFile != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NewPostScreen(
                initialMedia: [_mediaFile!.path],
              ),
            ),
          );
        } else if (type != 'STORY') {
          Navigator.pop(context);
        }
      },
      child: Text(
        type,
        style: TextStyle(
          color: _selectedType == type ? Colors.white : Colors.grey,
          fontWeight: _selectedType == type ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Future<void> _captureMedia() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);

    if (pickedFile != null) {
      setState(() {
        _mediaFile = File(pickedFile.path);
      });
    }
  }
}