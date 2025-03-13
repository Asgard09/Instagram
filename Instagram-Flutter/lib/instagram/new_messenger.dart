import 'package:flutter/material.dart';

class NewMessageScreen extends StatelessWidget {
  const NewMessageScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "New message",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // To: Search field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const Text(
                  "To:",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: const InputDecoration(
                      hintText: "Search",
                      hintStyle: TextStyle(color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8.0),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.grey),

          // Create group chat button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade800,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.group_add,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                const Text(
                  "Create group chat",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: Colors.grey),

          // Suggested header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Text(
              "Suggested",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),

          // Suggested contacts list
          Expanded(
            child: ListView(
              children: [
                _buildContactItem("tienng12", true),
                _buildContactItem("Chau Anh (Chao) ૮ˆﻌˆ ა", true, username: "_whynotchao_"),
                _buildContactItem("NOEL", false, username: "khoin.2907"),
                _buildContactItem("HURRYKNG", true, username: "hurrykhang"),
                _buildContactItem("thachtrang 🏄‍♀️", true, username: "thach_trangg"),
                _buildContactItem("Lê Hà Trúc ♡", true, username: "lehatruc"),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem(String name, bool verified, {String? username}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: Colors.grey,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (verified)
                      const Icon(Icons.verified, color: Colors.blue, size: 14),
                  ],
                ),
                if (username != null)
                  Text(
                    username,
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}