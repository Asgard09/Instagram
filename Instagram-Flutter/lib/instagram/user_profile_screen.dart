import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/user_provider.dart';
import '../models/user.dart';

class UserProfileScreen extends StatefulWidget {
  final String username;
  
  const UserProfileScreen({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  bool _isLoading = false;
  User? _user;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    // Load the user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }
  
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      try {
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        final user = await userProvider.fetchUserByUsername(widget.username, token);
        
        setState(() {
          _user = user;
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _error = 'Authentication token not found';
        _isLoading = false;
      });
    }
  }
  
  Widget _buildProfileImage(String? profilePicture) {
    if (profilePicture != null) {
      // Add server base URL if the path is relative
      String imageUrl = profilePicture;
      if (!imageUrl.startsWith('http')) {
        String serverUrl = kIsWeb 
            ? 'http://192.168.1.169:8080'
            : 'http://192.168.1.169:8080';
        imageUrl = '$serverUrl/uploads/$imageUrl';
      }
      
      print('Loading profile image from URL: $imageUrl');
      
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey[300],
        child: ClipOval(
          child: Image.network(
            imageUrl,
            width: 80,
            height: 80,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              print('Error loading profile image: $error');
              // Show fallback icon when image fails to load
              return Icon(Icons.person, size: 40, color: Colors.grey[800]);
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
        radius: 40,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: 40, color: Colors.grey[800]),
      );
    }
  }
  
  Widget _buildStat(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          widget.username,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: _isLoading 
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : _error != null
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Failed to load profile',
                      style: TextStyle(color: Colors.white),
                    ),
                    SizedBox(height: 8),
                    Text(
                      _error!,
                      style: TextStyle(color: Colors.red[300], fontSize: 12),
                    ),
                    SizedBox(height: 16),
                    TextButton(
                      onPressed: _loadUserData,
                      child: Text('Retry'),
                    ),
                  ],
                ),
              )
            : _user == null
              ? Center(
                  child: Text(
                    'User not found',
                    style: TextStyle(color: Colors.white),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile header
                      Row(
                        children: [
                          // Profile picture
                          _buildProfileImage(_user!.profilePicture),
                          
                          const SizedBox(width: 24),
                          
                          // Stats
                          Expanded(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStat(0, 'Posts'),
                                _buildStat(0, 'Followers'),
                                _buildStat(0, 'Following'),
                              ],
                            ),
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Name and bio
                      if (_user!.name != null && _user!.name!.isNotEmpty)
                        Text(
                          _user!.name!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      
                      if (_user!.bio != null && _user!.bio!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            _user!.bio!,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      
                      const SizedBox(height: 16),
                      
                      // Follow button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement follow functionality
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('Follow functionality not implemented yet')),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: const Text('Follow'),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Posts grid (placeholder)
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 4,
                          mainAxisSpacing: 4,
                        ),
                        itemCount: 0, // Placeholder for user posts
                        itemBuilder: (context, index) {
                          return Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: Icon(Icons.image, color: Colors.white30),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
} 