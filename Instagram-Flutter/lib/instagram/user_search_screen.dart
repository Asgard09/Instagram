import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../data/providers/auth_provider.dart';
import '../data/providers/user_provider.dart';
import '../models/user.dart';
import 'user_profile_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class UserSearchScreen extends StatefulWidget {
  const UserSearchScreen({Key? key}) : super(key: key);

  @override
  _UserSearchScreenState createState() => _UserSearchScreenState();
}

class _UserSearchScreenState extends State<UserSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<User> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  
  // Base URL for API calls
  final String serverBaseUrl = 'http://192.168.100.23:8080';

  @override
  void initState() {
    super.initState();
    // Focus the search field when the screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  Future<void> _searchUsers(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token == null) {
        setState(() {
          _error = 'Not authenticated';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('$serverBaseUrl/api/users/search?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        setState(() {
          _searchResults = data.map((userData) => User.fromJson(userData)).toList();
          _isLoading = false;
        });
      } else {
        print('Search API error: ${response.statusCode}');
        print('Response body: ${response.body}');
        setState(() {
          _error = 'Failed to search users: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Exception during search: $e');
      setState(() {
        _error = 'Error searching users: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: TextField(
          controller: _searchController,
          autofocus: true,
          style: TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Search users...',
            hintStyle: TextStyle(color: Colors.grey),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear, color: Colors.grey),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchResults = [];
                      });
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            _searchUsers(value);
          },
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: Colors.white)))
              : _searchResults.isEmpty
                  ? Center(
                      child: Text(
                        _searchController.text.isEmpty
                            ? 'Search for users'
                            : 'No users found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _searchResults.length,
                      itemBuilder: (context, index) {
                        final user = _searchResults[index];
                        return ListTile(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => UserProfileScreen(
                                  userId: user.userId.toString(),
                                  initialUsername: user.username,
                                ),
                              ),
                            );
                          },
                          leading: CircleAvatar(
                            backgroundImage: _buildProfileImage(user.profilePicture),
                            backgroundColor: Colors.grey,
                          ),
                          title: Text(
                            user.username ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            user.name ?? '',
                            style: TextStyle(color: Colors.grey),
                          ),
                        );
                      },
                    ),
    );
  }

  ImageProvider _buildProfileImage(String? profilePicture) {
    if (profilePicture == null || profilePicture.isEmpty) {
      return AssetImage('assets/images/default_profile.png');
    } else if (profilePicture.startsWith('http')) {
      return NetworkImage(profilePicture);
    } else {
      return NetworkImage('$serverBaseUrl/uploads/$profilePicture');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
} 