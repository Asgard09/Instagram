import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/user_provider.dart';
import '../models/user.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  void initState() {
    super.initState();
    
    // Load the user data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserData();
    });
  }
  
  Future<void> _loadUserData() async {
    final token = Provider.of<AuthProvider>(context, listen: false).token;
    if (token != null) {
      await Provider.of<UserProvider>(context, listen: false).fetchCurrentUser(token);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            final username = userProvider.user?.username ?? 'Profile';
            return Text(
              username,
              style: const TextStyle(color: Colors.white),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_box_outlined, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData,
        child: Consumer<UserProvider>(
          builder: (context, userProvider, child) {
            if (userProvider.isLoading && userProvider.user == null) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }
            
            final user = userProvider.user;
            if (user == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Failed to load profile',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextButton(
                      onPressed: _loadUserData,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }
            
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile header
                  Row(
                    children: [
                      // Profile picture
                      _buildProfileImage(user.profilePicture),
                      
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
                  if (user.name != null && user.name!.isNotEmpty)
                    Text(
                      user.name!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  
                  if (user.bio != null && user.bio!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        user.bio!,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  
                  const SizedBox(height: 16),
                  
                  // Edit Profile button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        ).then((_) => _loadUserData());
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.grey),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        'Edit Profile',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tab bar for posts/tagged
                  const DefaultTabController(
                    length: 2,
                    child: Column(
                      children: [
                        TabBar(
                          tabs: [
                            Tab(icon: Icon(Icons.grid_on, color: Colors.white)),
                            Tab(icon: Icon(Icons.person_pin_outlined, color: Colors.white)),
                          ],
                          indicatorColor: Colors.white,
                        ),
                        SizedBox(
                          height: 400, // Fixed height for tab content
                          child: TabBarView(
                            children: [
                              // Posts grid
                              Center(
                                child: Text(
                                  'No posts yet',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                              // Tagged photos
                              Center(
                                child: Text(
                                  'No tagged photos',
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
  
  Widget _buildStat(int count, String label) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white),
        ),
      ],
    );
  }
}
