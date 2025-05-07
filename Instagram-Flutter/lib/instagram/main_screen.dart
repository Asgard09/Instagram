import 'package:flutter/material.dart';
import 'package:practice_widgets/instagram/new_post_screen.dart';
import 'package:practice_widgets/instagram/profile_screen.dart';
import 'package:practice_widgets/instagram/reels_screen.dart';
import 'package:practice_widgets/instagram/search_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
  }
  final List<Widget> _screens = [
    const HomeScreen(),
    const Scaffold(body: Center(child: Text('Search', style: TextStyle(color: Colors.white)))),
    const Scaffold(body: Center(child: Text('Add Post', style: TextStyle(color: Colors.white)))),
    const Scaffold(body: Center(child: Text('Reels', style: TextStyle(color: Colors.white)))),
    const ProfileScreen(),
  ];

  // List of icons for the bottom navigation
  final List<IconData> _navigationIcons = [
    Icons.home,
    Icons.search_outlined,
    Icons.add_box_outlined,
    Icons.smart_display_outlined,
    Icons.person,
  ];

  void _onItemTapped(int index) {
    // If add button (index 2) is tapped, open post screen instead of switching
    if (index == 2) {
      _openPostScreen();
    } else {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  void _openPostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewPostScreen()),
    );
  }
  void switchToTab(int index) {
    if (mounted) {
      setState(() {
        _currentIndex = index;
      });
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