import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:practice_widgets/instagram/home_screen.dart';
import 'package:practice_widgets/instagram/login_screen.dart';
import 'package:provider/provider.dart';

import 'data/providers/auth_provider.dart';
import 'data/providers/posts_provider.dart';
import 'data/providers/user_provider.dart';
import 'data/providers/likes_provider.dart';
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
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Print platform info for debugging
    print('Running on platform: ${kIsWeb ? 'Web' : 'Native'}');
    
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: LoginScreen());
  }
}