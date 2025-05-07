import 'package:flutter/material.dart';
import 'package:practice_widgets/instagram/new_post_screen.dart';
import 'package:practice_widgets/instagram/profile_screen.dart';
import 'package:practice_widgets/instagram/reels_screen.dart';
import 'package:practice_widgets/instagram/search_screen.dart';
import 'package:practice_widgets/instagram/chat_list_screen.dart';
import 'package:provider/provider.dart';
import '../data/providers/chat_provider.dart';

import 'home_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
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
  
  void _openChatList() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = Provider.of<ChatProvider>(context).unreadCount;
    
    return Scaffold(
      backgroundColor: Colors.black,
      // Hiển thị AppBar cho tất cả các màn hình
      appBar: _currentIndex == 0 
        ? AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            // Không hiển thị tiêu đề cho Home screen, vì đã có tiêu đề trong HomeScreen
            automaticallyImplyLeading: false,
            actions: [
              // Nút messenger
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.messenger_outline, color: Colors.white),
                    onPressed: _openChatList,
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          )
        : AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            title: const Text(
              'Instagram',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
          ),
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