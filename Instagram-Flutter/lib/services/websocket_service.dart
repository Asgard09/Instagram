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
      return 'ws://192.168.100.23:8080';
    } else {
      return 'ws://192.168.100.23:8080';
    }
  }

  StompClient? _stompClient;
  bool _connected = false;
  final _messageController = StreamController<Message>.broadcast();
  final _readReceiptController = StreamController<int>.broadcast();
  
  // Authentication info
  String? _token;
  int? _userId;
  
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;

  // Stream for new messages
  Stream<Message> get messageStream => _messageController.stream;
  
  // Stream for read receipts
  Stream<int> get readReceiptStream => _readReceiptController.stream;

  // Connection status
  bool get isConnected => _connected;

  // Connect to WebSocket
  void connect(String token, int userId) {
    // Store credentials for reconnection
    _token = token;
    _userId = userId;
    
    // Disconnect existing connection if any
    if (_stompClient != null) {
      try {
        _stompClient!.deactivate();
      } catch (e) {
        print('Error disconnecting previous connection: $e');
      }
    }
    
    print('Connecting to WebSocket at $_baseUrl with user $userId');

    _stompClient = StompClient(
      config: StompConfig(
        url: '$_baseUrl/ws',
        onConnect: (StompFrame frame) {
          print('Connected to WebSocket successfully');
          _connected = true;
          _reconnectAttempts = 0;
          
          // Subscribe to personal queue for new messages
          _stompClient!.subscribe(
            destination: '/user/$userId/queue/messages',
            callback: (frame) {
              if (frame.body != null) {
                print('Received WebSocket message: ${frame.body}');
                try {
                  final messageJson = json.decode(frame.body!);
                  print('Decoded JSON: $messageJson');
                  
                  // Check for read/isRead field discrepancy
                  if (messageJson.containsKey('read') && !messageJson.containsKey('isRead')) {
                    print('Converting "read" field to "isRead"');
                    messageJson['isRead'] = messageJson['read'];
                  }
                  
                  // Ensure createdAt is properly handled as UTC
                  if (messageJson.containsKey('createdAt') && messageJson['createdAt'] != null) {
                    try {
                      // Parse the date and ensure it's treated as UTC
                      DateTime parsedDate = DateTime.parse(messageJson['createdAt']);
                      messageJson['createdAt'] = parsedDate.toUtc().toIso8601String();
                    } catch (e) {
                      print('Error parsing date: $e');
                    }
                  }
                  
                  final message = Message.fromJson(messageJson);
                  print('Created message object with senderId: ${message.senderId}, receiverId: ${message.receiverId}');
                  _messageController.add(message);
                } catch (e) {
                  print('Error processing WebSocket message: $e');
                }
              }
            },
          );
          
          // Subscribe to read receipts
          _stompClient!.subscribe(
            destination: '/user/$userId/queue/read-receipts',
            callback: (frame) {
              if (frame.body != null) {
                final chatId = int.parse(frame.body!);
                _readReceiptController.add(chatId);
              }
            },
          );
        },
        onWebSocketError: (dynamic error) {
          print('WebSocket error: $error');
          _connected = false;
          _scheduleReconnect();
        },
        onDisconnect: (frame) {
          print('Disconnected from WebSocket');
          _connected = false;
          _scheduleReconnect();
        },
        onStompError: (frame) {
          print('STOMP error: ${frame.body}');
          _connected = false;
          _scheduleReconnect();
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
    try {
      _stompClient!.activate();
    } catch (e) {
      print('Error activating STOMP client: $e');
      _connected = false;
      _scheduleReconnect();
    }
  }
  
  void _scheduleReconnect() {
    // Cancel any existing reconnect timer
    _reconnectTimer?.cancel();
    
    if (_reconnectAttempts < _maxReconnectAttempts && _token != null && _userId != null) {
      final delay = Duration(seconds: _reconnectAttempts * 2 + 1); // Exponential backoff
      print('Scheduling reconnect attempt ${_reconnectAttempts + 1} in ${delay.inSeconds} seconds');
      
      _reconnectTimer = Timer(delay, () {
        _reconnectAttempts++;
        print('Attempting to reconnect (${_reconnectAttempts}/$_maxReconnectAttempts)');
        connect(_token!, _userId!);
      });
    } else {
      print('Max reconnect attempts reached or missing credentials. No further automatic reconnections.');
    }
  }

  // Send a message via WebSocket
  void sendMessage(int receiverId, String content) {
    if (!_connected || _stompClient == null) {
      print('Not connected to WebSocket, cannot send message');
      return;
    }

    // Include senderId in the message payload - this is crucial!
    final message = {
      'senderId': _userId, // Add the sender ID
      'receiverId': receiverId,
      'content': content,
      'timestamp': DateTime.now().toUtc().toIso8601String(), // Include UTC timestamp
    };

    print('Sending message via WebSocket from user $_userId to user $receiverId: $content');
    print('WebSocket connection status: $_connected');
    print('Message JSON: ${json.encode(message)}');
    print('Destination: /app/chat.sendMessage');
    
    try {
      _stompClient!.send(
        destination: '/app/chat.sendMessage',
        body: json.encode(message),
      );
      print('WebSocket message sent successfully');
    } catch (e) {
      print('Error sending message via WebSocket: $e');
      print('STOMP client state: ${_stompClient!.connected ? 'connected' : 'disconnected'}');
    }
  }

  // Mark messages as read via WebSocket
  void markMessagesAsRead(int chatId) {
    if (!_connected || _stompClient == null) {
      print('Not connected to WebSocket, cannot mark messages as read');
      return;
    }

    final data = {
      'chatId': chatId,
    };

    try {
      _stompClient!.send(
        destination: '/app/chat.markRead',
        body: json.encode(data),
      );
    } catch (e) {
      print('Error marking messages as read: $e');
    }
  }

  // Disconnect from WebSocket
  void disconnect() {
    if (_stompClient != null) {
      try {
        _stompClient!.deactivate();
      } catch (e) {
        print('Error disconnecting: $e');
      }
      _connected = false;
    }
    
    // Cancel any reconnection attempts
    _reconnectTimer?.cancel();
  }

  // Dispose resources
  void dispose() {
    disconnect();
    _messageController.close();
    _readReceiptController.close();
  }
} 