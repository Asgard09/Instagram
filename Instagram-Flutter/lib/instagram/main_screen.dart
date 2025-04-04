import 'package:flutter/material.dart';
import 'package:practice_widgets/instagram/new_post_screen.dart';
import 'package:practice_widgets/instagram/profile_screen.dart';
import 'package:practice_widgets/instagram/reels_screen.dart';
import 'package:practice_widgets/instagram/search_screen.dart';

import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // List of screens
  static final List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),
    SearchScreen(),
    ReelsScreen(),
    ProfileScreen(),
  ];

  // List of icons for the bottom navigation
  final List<IconData> _navigationIcons = [
    Icons.home,
    Icons.search_outlined,
    Icons.smart_display_outlined,
    Icons.person,
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _openPostScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const NewPostScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _widgetOptions.elementAt(_selectedIndex),
      bottomNavigationBar: Container(
        height: 100,
        color: Colors.black,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // First two icons
            _buildNavItem(0),
            _buildNavItem(1),

            // Add button in the middle
            GestureDetector(
              onTap: _openPostScreen,
              child: const Icon(
                Icons.add_box_outlined,
                size: 30,
                color: Colors.white,
              ),
            ),

            // Last two icons
            _buildNavItem(2),
            _buildNavItem(3),
          ],
        ),
      ),
    );
  }

  // Build a navigation item
  Widget _buildNavItem(int index) {
    bool isSelected = index == _selectedIndex;
    return GestureDetector(
      onTap: () => _onItemTapped(index),
      child: Container(
        padding: const EdgeInsets.all(8),
        child: Icon(
          _navigationIcons[index],
          size: 40,
          color: isSelected ? Colors.white : Colors.grey,
        ),
      ),
    );
  }
}