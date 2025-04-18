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
      final response = await http.get(
        Uri.parse('http://192.168.1.4:8080/api/users/${widget.userId}'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          userData = User.fromJson(data);
          isFollowing = data['isFollowing'] ?? false;
          followersCount = data['followersCount'] ?? 0;
          followingCount = data['followingCount'] ?? 0;
          postsCount = data['postsCount'] ?? 0;
        });
      } else {
        _showError('Failed to load user profile');
      }
    } catch (e) {
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
        Uri.parse('http://192.168.1.4:8080/api/follows/${widget.userId}'),
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
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  Widget _buildProfileImage(String? profilePicture) {
    if (profilePicture != null) {
      String imageUrl = profilePicture;
      if (!imageUrl.startsWith('http')) {
        String serverUrl = kIsWeb 
            ? 'http://192.168.1.4:8080'
            : 'http://192.168.1.4:8080';
        imageUrl = '$serverUrl/uploads/$imageUrl';
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
              child: SingleChildScrollView(
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
                    if (userData?.name != null)
                      Text(
                        userData!.name!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if (userData?.bio != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          userData!.bio!,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ),
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