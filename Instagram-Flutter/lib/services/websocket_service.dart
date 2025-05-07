import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:stomp_dart_client/stomp.dart';
import 'package:stomp_dart_client/stomp_config.dart';
import 'package:stomp_dart_client/stomp_frame.dart';
import '../models/message.dart';

class WebSocketService {
  // Server base URL
  String get _baseUrl {
    if (kIsWeb) {
      return 'ws://192.168.1.5:8080';
    } else {
      return 'ws://192.168.1.5:8080';
    }
  }

  late StompClient _stompClient;
  bool _connected = false;
  final _messageController = StreamController<Message>.broadcast();
  final _readReceiptController = StreamController<int>.broadcast();

  // Stream for new messages
  Stream<Message> get messageStream => _messageController.stream;
  
  // Stream for read receipts
  Stream<int> get readReceiptStream => _readReceiptController.stream;

  // Connection status
  bool get isConnected => _connected;

  // Connect to WebSocket
  void connect(String token, int userId) {
    _stompClient = StompClient(
      config: StompConfig(
        url: '$_baseUrl/ws',
        onConnect: (StompFrame frame) {
          _connected = true;
          
          // Subscribe to personal queue for new messages
          _stompClient.subscribe(
            destination: '/user/$userId/queue/messages',
            callback: (frame) {
              if (frame.body != null) {
                final message = Message.fromJson(json.decode(frame.body!));
                _messageController.add(message);
              }
            },
          );
          
          // Subscribe to read receipts
          _stompClient.subscribe(
            destination: '/user/$userId/queue/read-receipts',
            callback: (frame) {
              if (frame.body != null) {
                final chatId = int.parse(frame.body!);
                _readReceiptController.add(chatId);
              }
            },
          );
          
          print('Connected to WebSocket');
        },
        onWebSocketError: (dynamic error) {
          print('WebSocket error: $error');
          _connected = false;
        },
        // Add authentication headers
        stompConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
        webSocketConnectHeaders: {
          'Authorization': 'Bearer $token',
        },
      ),
    );

    // Activate client
    _stompClient.activate();
  }

  // Send a message via WebSocket
  void sendMessage(int receiverId, String content) {
    if (!_connected) {
      print('Not connected to WebSocket, cannot send message');
      return;
    }

    final message = {
      'receiverId': receiverId,
      'content': content,
    };

    _stompClient.send(
      destination: '/app/chat.sendMessage',
      body: json.encode(message),
    );
  }

  // Mark messages as read via WebSocket
  void markMessagesAsRead(int chatId) {
    if (!_connected) {
      print('Not connected to WebSocket, cannot mark messages as read');
      return;
    }

    final data = {
      'chatId': chatId,
    };

    _stompClient.send(
      destination: '/app/chat.markRead',
      body: json.encode(data),
    );
  }

  // Disconnect from WebSocket
  void disconnect() {
    if (_connected) {
      _stompClient.deactivate();
      _connected = false;
    }
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _readReceiptController.close();
  }
} 