import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  File? _profilePicture;
  final TextEditingController _nameController = TextEditingController(text: 'Nguyen Thanh Dat');
  final TextEditingController _usernameController =
  TextEditingController(text: 'nguyenthanhdat9290');
  final TextEditingController _bioController = TextEditingController();
  String _selectedGender = 'Prefer not to say';
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickProfilePicture(ImageSource source) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _profilePicture = File(pickedFile.path);
      });
    }
  }

  void _showProfilePictureOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library, color: Colors.white),
            title: const Text('Choose from library', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickProfilePicture(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.facebook, color: Colors.white),
            title: const Text('Import from Facebook', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              // TODO: Implement import from Facebook
            },
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Colors.white),
            title: const Text('Take photo', style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              _pickProfilePicture(ImageSource.camera);
            },
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Your profile picture and avatar are visible to everyone on and off Instagram. Learn more',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  void _selectGender() async {
    final result = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: const Text('Male', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, 'Male'),
          ),
          ListTile(
            title: const Text('Female', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, 'Female'),
          ),
          ListTile(
            title: const Text('Prefer not to say', style: TextStyle(color: Colors.white)),
            onTap: () => Navigator.pop(context, 'Prefer not to say'),
          ),
        ],
      ),
    );
    if (result != null) {
      setState(() {
        _selectedGender = result;
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
          'Edit profile',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile picture
              GestureDetector(
                onTap: _showProfilePictureOptions,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: _profilePicture != null
                          ? FileImage(_profilePicture!)
                          : null,
                      child: _profilePicture == null
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _showProfilePictureOptions,
                child: const Text(
                  'Edit picture or avatar',
                  style: TextStyle(color: Colors.blue, fontSize: 14),
                ),
              ),
              const SizedBox(height: 24),

              // Name
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Name',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Username
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Username',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _usernameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Bio
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Bio',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                style: const TextStyle(color: Colors.white),
                maxLines: 3,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Gender
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Gender',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: Text(
                  _selectedGender,
                  style: const TextStyle(color: Colors.white),
                ),
                trailing: const Icon(Icons.arrow_drop_down, color: Colors.white),
                onTap: _selectGender,
                tileColor: Colors.grey[800],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}