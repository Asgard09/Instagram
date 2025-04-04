import 'package:flutter/material.dart';
import 'package:practice_widgets/instagram/profile_screen.dart';

// Import các màn hình thực tế từ các file .dart
import 'home_screen.dart'; // Trang Home
import 'search_screen.dart'; // Trang Search
import 'reels_screen.dart'; // Trang Reels
import 'chat_screen.dart'; // Trang Chat

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Danh sách các trang thực tế
  static final List<Widget> _pages = <Widget>[
     HomeScreen(), // Sử dụng HomeScreen từ home_screen.dart
     SearchScreen(), // Sử dụng SearchScreen từ search_screen.dart
     ReelsScreen(), // Sử dụng ReelsScreen từ reels_screen.dart
     ChatScreen(), // Sử dụng ChatScreen từ chat_screen.dart
     ProfileScreen(), // Sử dụng ProfileScreen từ profile_screen.dart
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Hiển thị trang tương ứng với chỉ số được chọn
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Reels',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        backgroundColor: Colors.white,
        onTap: _onItemTapped,
      ),
    );
  }
}