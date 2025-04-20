import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/user_provider.dart';
import '../models/user.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserProfileScreen extends StatefulWidget {
  final String userId;
  final String? initialUsername;
  final String? initialProfilePicture;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    this.initialUsername,
    this.initialProfilePicture,
  }) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  User? userData;
  bool isLoading = true;
  bool isFollowing = false;
  bool isProcessing = false;
  int followersCount = 0;
  int followingCount = 0;
  int postsCount = 0;

  // Helper method to get the base URL for server resources
  String get serverBaseUrl {
    if (kIsWeb) {
      // Use the specific IP for web
      return 'http://192.168.1.97:8080';
    } else {
      // For mobile platforms
      return 'http://192.168.1.97:8080';
    }
  }

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        print('Token is null, cannot load user profile');
        _showError('Authentication token not found');
        setState(() {
          isLoading = false;
        });
        return;
      }

      print('Fetching user profile for userId: ${widget.userId}, username: ${widget.initialUsername}');

      // Try to get user by ID first
      var responseById = await http.get(
        Uri.parse('${serverBaseUrl}/api/users/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      print('User profile API response by ID (${widget.userId}) status: ${responseById.statusCode}');
      
      // If failed and we have a username, try by username
      if (responseById.statusCode != 200 && widget.initialUsername != null) {
        print('Failed to get user by ID, trying by username: ${widget.initialUsername}');
        
        var responseByUsername = await http.get(
          Uri.parse('${serverBaseUrl}/api/users/by-username/${widget.initialUsername}'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
        );
        
        print('User profile API response by username status: ${responseByUsername.statusCode}');
        
        if (responseByUsername.statusCode == 200) {
          print('Successfully fetched user by username: ${responseByUsername.body}');
          final data = json.decode(responseByUsername.body);
          setState(() {
            userData = User.fromJson(data);
            isFollowing = data['isFollowing'] ?? false;
            followersCount = data['followersCount'] ?? 0;
            followingCount = data['followingCount'] ?? 0;
            postsCount = data['postsCount'] ?? 0;
          });
          print('Successfully parsed user data from username API: ${userData?.username}, ${userData?.name}');
          return;
        } else {
          print('Also failed to fetch by username: ${responseByUsername.statusCode}');
        }
      }
      
      // Process the response from the ID endpoint if it was successful
      if (responseById.statusCode == 200) {
        print('User profile API response body: ${responseById.body}');
        final data = json.decode(responseById.body);
        setState(() {
          userData = User.fromJson(data);
          isFollowing = data['isFollowing'] ?? false;
          followersCount = data['followersCount'] ?? 0;
          followingCount = data['followingCount'] ?? 0;
          postsCount = data['postsCount'] ?? 0;
        });
        print('Successfully parsed user data: ${userData?.username}, ${userData?.name}');
      } else if (responseById.statusCode == 404) {
        print('User not found: ${widget.userId}');
        setState(() {
          // Set a placeholder user with the initialUsername
          if (widget.initialUsername != null) {
            userData = User(username: widget.initialUsername!);
          }
        });
      } else {
        print('Failed to load user profile: ${responseById.statusCode}, ${responseById.body}');
        _showError('Failed to load user profile: ${responseById.statusCode}');
      }
    } catch (e) {
      print('Error loading profile: $e');
      _showError('Error loading profile: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final response = await http.post(
        Uri.parse('${serverBaseUrl}/api/follows/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          isFollowing = !isFollowing;
          followersCount += isFollowing ? 1 : -1;
        });
      } else {
        _showError('Failed to ${isFollowing ? 'unfollow' : 'follow'} user');
      }
    } catch (e) {
      _showError('Error: $e');
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  void _showError(String message) {
    // Only show error if mounted
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Retry',
          textColor: Colors.white,
          onPressed: () {
            _loadUserData();
          },
        ),
      ),
    );
  }

  Widget _buildProfileImage(String? profilePicture) {
    if (profilePicture != null) {
      String imageUrl = profilePicture;
      if (!imageUrl.startsWith('http')) {
        imageUrl = '${serverBaseUrl}/uploads/$imageUrl';
      }

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
              return Icon(Icons.person, size: 40, color: Colors.grey[800]);
            },
          ),
        ),
      );
    } else {
      return CircleAvatar(
        radius: 40,
        backgroundColor: Colors.grey[300],
        child: Icon(Icons.person, size: 40, color: Colors.grey[800]),
      );
    }
  }

  Widget _buildFollowButton() {
    // Don't show follow button if we couldn't fetch the user
    if (userData == null) {
      return const SizedBox.shrink();
    }
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isProcessing ? null : _toggleFollow,
        style: ElevatedButton.styleFrom(
          backgroundColor: isFollowing ? Colors.grey[800] : Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        child: isProcessing
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Text(
                isFollowing ? 'Following' : 'Follow',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
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
          userData?.username ?? widget.initialUsername ?? 'Profile',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.white),
            )
          : RefreshIndicator(
              onRefresh: _loadUserData,
              child: Stack(
                children: [
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildProfileImage(
                              userData?.profilePicture ?? widget.initialProfilePicture,
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  _buildStat(postsCount, 'Posts'),
                                  _buildStat(followersCount, 'Followers'),
                                  _buildStat(followingCount, 'Following'),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildUserInfoSection(),
                        const SizedBox(height: 16),
                        _buildFollowButton(),
                        const SizedBox(height: 24),
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
                                height: 400,
                                child: TabBarView(
                                  children: [
                                    Center(
                                      child: Text(
                                        'No posts yet',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
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
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildUserInfoSection() {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Always show username as backup if name is missing
            if (userData?.name != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[400], size: 18),
                    SizedBox(width: 8),
                    Text(
                      userData!.name!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              )
            else if (userData?.username != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    Icon(Icons.person, color: Colors.grey[400], size: 18),
                    SizedBox(width: 8),
                    Text(
                      userData!.username,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            if (userData?.bio != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: Colors.grey[400], size: 18),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        userData!.bio!,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            if (userData?.gender != null)
              Row(
                children: [
                  Icon(Icons.transgender, color: Colors.grey[400], size: 18),
                  SizedBox(width: 8),
                  Text(
                    _formatGender(userData!.gender!),
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            // If no user data is available
            if (userData == null || (userData?.name == null && userData?.bio == null && userData?.gender == null))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.person_off, color: Colors.grey[400], size: 36),
                      SizedBox(height: 8),
                      Text(
                        'No profile information available',
                        style: TextStyle(color: Colors.grey[400], fontSize: 14),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'This user may not exist or profile is private',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatGender(Gender gender) {
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
        return 'Not specified';
    }
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