import 'package:flutter/material.dart';
import 'package:practice_widgets/instagram/new_post_screen.dart';
import 'package:practice_widgets/instagram/profile_screen.dart';
import 'package:practice_widgets/instagram/reels_screen.dart';
import 'package:practice_widgets/instagram/search_screen.dart';
import 'package:practice_widgets/instagram/user_search_screen.dart';
import 'package:provider/provider.dart';
import '../data/providers/posts_provider.dart';
import '../data/providers/auth_provider.dart';

import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  final int initialTabIndex;

  const MainScreen({
    Key? key,
    this.initialTabIndex = 0,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _currentIndex;
  bool _isSearchFocused = false;
  
  final List<Widget> _screens = [];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    
    // Initialize screens list
    _screens.addAll([
      HomeScreen(),
      SearchScreen(),
      const Scaffold(body: Center(child: Text('Add Post', style: TextStyle(color: Colors.white)))),
      const Scaffold(body: Center(child: Text('Reels', style: TextStyle(color: Colors.white)))),
      const ProfileScreen(),
    ]);
  }

  // List of icons for the bottom navigation
  final List<IconData> _navigationIcons = [
    Icons.home_outlined,
    Icons.search_outlined,
    Icons.add_box_outlined,
    Icons.movie_outlined,
    Icons.person_outline,
  ];

  // Refresh posts directly using PostsProvider
  void _refreshPosts() {
    if (_currentIndex == 0) {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        Provider.of<PostsProvider>(context, listen: false).fetchPosts(token);
      }
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // When search icon is tapped, show the search page with focus
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserSearchScreen(),
        ),
      );
      return;
    }
    
    if (index == 2) {
      _openPostScreen();
    } else {
      setState(() {
        _currentIndex = index;
      });
      
      // Refresh posts when returning to the home screen
      if (index == 0) {
        _refreshPosts();
      }
    }
  }

  void _openPostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NewPostScreen(),
      ),
    ).then((_) {
      // Refresh the posts when returning from creating a new post
      if (_currentIndex == 0) {
        _refreshPosts();
      }
    });
  }
  
  void switchToTab(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
      
      // Refresh posts when switching to the home screen
      if (index == 0) {
        _refreshPosts();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _screens.elementAt(_currentIndex),
      bottomNavigationBar: Container(
        height: 60,
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0), // Home
            _buildNavItem(1), // Search
            _buildNavItem(2), // Add
            _buildNavItem(3), // Reels
            _buildNavItem(4), // Profile
          ],
        ),
      ),
    );
  }

  // Build a navigation item
  Widget _buildNavItem(int index) {
    bool isSelected = index == _currentIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          _navigationIcons[index],
          size: 30,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}