import 'package:flutter/material.dart';
import 'package:practice_widgets/instagram/login_screen.dart';
import 'package:practice_widgets/instagram/main_screen.dart';
import 'package:practice_widgets/instagram/new_messenger.dart';
import 'package:practice_widgets/screens/media_query.dart';
import 'package:practice_widgets/screens/screen_one.dart';
import 'package:practice_widgets/screens/widgets_list.dart';

import 'instagram/chat_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: LoginScreen());
  }
}
