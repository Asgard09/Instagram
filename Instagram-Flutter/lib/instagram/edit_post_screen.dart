import 'package:flutter/material.dart';
import 'dart:io';
import '../models/media_item.dart';
class EditPostScreen extends StatefulWidget {
  final List<MediaItem> selectedMedia;
  const EditPostScreen({Key? key, required this.selectedMedia}) : super(key: key);

  @override
  _EditPostScreenState createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final TextEditingController _captionController = TextEditingController();
  List<String> _taggedPeople = [];

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
          TextButton(
            onPressed: () {
              // Xử lý đăng bài
              Navigator.popUntil(context, (route) => route.isFirst);
            },
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
            // Hiển thị media đã chọn
            if (widget.selectedMedia.isNotEmpty)
              Container(
                height: 300,
                width: double.infinity,
                child: Image.file(
                  File(widget.selectedMedia.first.path),
                  fit: BoxFit.cover,
                ),
              ),
            // Trường nhập caption
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
            // Tùy chọn tag people
            ListTile(
              leading: const Icon(Icons.person, color: Colors.white),
              title: const Text(
                'Tag people',
                style: TextStyle(color: Colors.white),
              ),
              trailing: const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              onTap: _tagPeople,
            ),
            // Hiển thị danh sách người đã tag
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
}