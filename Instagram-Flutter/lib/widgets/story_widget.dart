import 'package:flutter/material.dart';
import 'package:practice_widgets/widgets/circle_story.dart';

class StoryWidget extends StatelessWidget {
  final String username;
  const StoryWidget({Key? key, required this.username}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: 85,
                width: 85,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.yellow,
                      Colors.orange,
                      Colors.red,
                      Colors.pink,
                      Colors.purple,
                    ],
                  ),
                ),
              ),
              Container(
                height: 80,
                width: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                // child: CircleAvatar(
                //   backgroundColor: Colors.white, // Nền của avatar
                //   backgroundImage: AssetImage('assets/profile.jpg'), // Ảnh đại diện
                // ),
                padding: EdgeInsets.all(3),
              ),
              const CircleStory()
            ],
          ),
        ),
        Text(
          username,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
        ),
      ],
    );
  }
}
