import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/user_provider.dart';
import '../models/user.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _bioController = TextEditingController();
  Gender? _selectedGender;
  String? _profileImagePath;
  bool _isImageChanged = false;
  
  final ImagePicker _picker = ImagePicker();
  
  @override
  void initState() {
    super.initState();
    
    // Load the user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user != null) {
        _usernameController.text = user.username;
        _nameController.text = user.name ?? '';
        _bioController.text = user.bio ?? '';
        _selectedGender = user.gender;
      } else {
        // Fetch user if not already loaded
        _loadUserData();
      }
    });
  }
  
  Future<void> _loadUserData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await Provider.of<UserProvider>(context, listen: false).fetchCurrentUser(token);
      
      // Update the form with fetched data
      final user = Provider.of<UserProvider>(context, listen: false).user;
      if (user != null) {
        setState(() {
          _usernameController.text = user.username;
          _nameController.text = user.name ?? '';
          _bioController.text = user.bio ?? '';
          _selectedGender = user.gender;
        });
      }
    }
  }
  
  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        setState(() {
          _profileImagePath = pickedFile.path;
          _isImageChanged = true;
        });
      }
    } catch (e) {
      print('Error picking image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }
  
  Widget _buildProfileImage() {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;
    
    if (_isImageChanged && _profileImagePath != null) {
      // Show newly picked image
      if (kIsWeb) {
        // Web platforms
        return CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          child: ClipOval(
            child: Image.network(
              _profileImagePath!,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                print('Error loading selected web image: $error');
                return Icon(Icons.person, size: 50, color: Colors.grey[800]);
              },
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
            ),
          ),
        );
      } else {
        // Mobile platforms
        return CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey[200],
          backgroundImage: FileImage(File(_profileImagePath!)),
          onBackgroundImageError: (exception, stackTrace) {
            print('Error loading selected file image: $exception');
          },
        );
      }
    } else if (user?.profilePicture != null) {
      // Show existing profile picture
      String imageUrl = user!.profilePicture!;
      
      // Add server base URL if the path is relative
      if (!imageUrl.startsWith('http')) {
        String serverUrl = kIsWeb 
            ? 'http://192.168.1.238:8080'
            : 'http://192.168.1.238:8080';
        imageUrl = '$serverUrl/uploads/$imageUrl';
      }
      
      print('Loading profile image from URL: $imageUrl');
      
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[200],
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 100,
            height: 100,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading profile image: $error');
              return Icon(Icons.person, size: 50, color: Colors.grey[800]);
            },
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
          ),
        ),
      );
    } else {
      // Show default avatar
      return CircleAvatar(
        radius: 50,
        backgroundColor: Colors.grey[200],
        child: Icon(Icons.person, size: 50, color: Colors.grey[800]),
      );
    }
  }
  
  Future<void> _saveProfile() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    final token = authProvider.token;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You need to be logged in')),
      );
      return;
    }
    
    // Show loading indicator
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Saving profile...')),
    );
    
    bool success = true;
    
    // Update profile image if changed
    if (_isImageChanged && _profileImagePath != null) {
      print('Updating profile image with path: $_profileImagePath');
      success = await userProvider.updateProfileImage(_profileImagePath!, token);
      
      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(userProvider.error ?? 'Failed to update profile image')),
        );
        return;
      }
    }
    
    // Update profile information
    success = await userProvider.updateProfile(
      token: token,
      username: _usernameController.text,
      name: _nameController.text,
      bio: _bioController.text,
      gender: _selectedGender,
    );
    
    if (success) {
      // Refresh user data to get updated profile
      await userProvider.fetchCurrentUser(token);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userProvider.error ?? 'Failed to update profile')),
      );
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
          'Edit Profile',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.blue),
            onPressed: _saveProfile,
          ),
        ],
      ),
      body: Consumer<UserProvider>(
        builder: (context, userProvider, child) {
          if (userProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Profile picture
                Center(
                  child: GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        _buildProfileImage(),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.camera_alt,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Username field
                _buildTextField(
                  controller: _usernameController,
                  label: 'Username',
                  hint: 'Enter your username',
                ),
                
                const SizedBox(height: 16),
                
                // Name field
                _buildTextField(
                  controller: _nameController,
                  label: 'Name',
                  hint: 'Enter your name',
                ),
                
                const SizedBox(height: 16),
                
                // Bio field
                _buildTextField(
                  controller: _bioController,
                  label: 'Bio',
                  hint: 'Tell something about yourself',
                  maxLines: 3,
                ),
                
                const SizedBox(height: 24),
                
                // Gender dropdown
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[900],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<Gender>(
                      dropdownColor: Colors.grey[900],
                      value: _selectedGender,
                      hint: const Text('Select Gender', style: TextStyle(color: Colors.grey)),
                      style: const TextStyle(color: Colors.white),
                      onChanged: (Gender? newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                      items: Gender.values.map<DropdownMenuItem<Gender>>((Gender gender) {
                        return DropdownMenuItem<Gender>(
                          value: gender,
                          child: Text(
                            _getGenderDisplayName(gender),
                            style: const TextStyle(color: Colors.white),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  String _getGenderDisplayName(Gender gender) {
    switch (gender) {
      case Gender.MALE:
        return 'Male';
      case Gender.FEMALE:
        return 'Female';
      case Gender.OTHER:
        return 'Other';
      case Gender.PREFER_NOT_TO_SAY:
        return 'Prefer not to say';
      default:
        return 'Unknown';
    }
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[900],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
  
  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}