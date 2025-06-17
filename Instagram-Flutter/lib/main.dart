import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:practice_widgets/instagram/home_screen.dart';
import 'package:practice_widgets/instagram/login_screen.dart';
import 'package:provider/provider.dart';

import 'data/providers/auth_provider.dart';
import 'data/providers/posts_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/providers/likes_provider.dart';
import 'data/providers/chat_provider.dart';
import 'data/providers/comments_provider.dart';
import 'data/providers/notification_provider.dart';
import 'instagram/main_screen.dart';

// Import mobile implementation only on non-web platforms
// This file is not imported directly - it's used to register the extension
import 'services/post_service_native.dart' if (dart.library.html) 'services/post_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (context) => PostsProvider()),
        ChangeNotifierProvider(create: (context) => LikesProvider()),
        ChangeNotifierProvider(create: (context) => ChatProvider()),
        ChangeNotifierProvider(create: (context) => CommentsProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Print platform info for debugging
    if (kDebugMode) {
      print('Running on platform: ${kIsWeb ? 'Web' : 'Native'}');
    }
    
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Instagram',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: AppInitializer());
  }
}

/*Note
* Save user token when reload
*/
class AppInitializer extends StatefulWidget {
  @override
  _AppInitializerState createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer>{
  bool _isInitializing = true;

  @override
  void initState(){
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      // Load token from storage
      await authProvider.loadToken();

      // If token exists and is valid, load user data
      if (authProvider.isTokenValid) {
        print('Valid token found, loading user data...');
        try {
          await userProvider.fetchCurrentUser(authProvider.token!);
          print('User data loaded successfully: ${userProvider.user?.username}');
        } catch (e) {
          print('Failed to load user data: $e');
          // Clear invalid token
          await authProvider.setToken(null);
        }
      }
    } catch (e) {
      print('Error during app initialization: $e');
    }

    setState(() {
      _isInitializing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text(
                'Loading...',
                style: TextStyle(color: Colors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isTokenValid) {
            return MainScreen();
          } else {
            return LoginScreen();
          }
        }
    );
  }
}