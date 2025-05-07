import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;
  DateTime? _tokenExpiryTime;

  String? get token => _token;
  bool get isAuthenticated => _token != null;
  
  // Check if token is valid and not expired
  bool get isTokenValid {
    if (_token == null) return false;
    if (_tokenExpiryTime == null) return true; // No expiry time set
    return _tokenExpiryTime!.isAfter(DateTime.now());
  }
  
  // Validate token and throw exception if invalid
  String validateToken() {
    if (_token == null) {
      throw Exception('No authentication token available. Please log in.');
    }
    
    if (_tokenExpiryTime != null && _tokenExpiryTime!.isBefore(DateTime.now())) {
      throw Exception('Your session has expired. Please log in again.');
    }
    
    return _token!;
  }

  Future<void> setToken(String? token) async {
    _token = token;
    if (token != null) {
      // Set token expiry to 1 day from now for example
      _tokenExpiryTime = DateTime.now().add(Duration(days: 1));
      
      await SharedPreferences.getInstance()
          .then((prefs) {
            prefs.setString('jwt_token', token);
            if (_tokenExpiryTime != null) {
              prefs.setString('token_expiry', _tokenExpiryTime!.toIso8601String());
            }
          });
      print('Token saved: ${token.substring(0, 20)}... expires at $_tokenExpiryTime');
    } else {
      await SharedPreferences.getInstance()
          .then((prefs) {
            prefs.remove('jwt_token');
            prefs.remove('token_expiry');
          });
      _tokenExpiryTime = null;
      print('Token cleared');
    }
    notifyListeners();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    
    final expiryString = prefs.getString('token_expiry');
    if (expiryString != null) {
      try {
        _tokenExpiryTime = DateTime.parse(expiryString);
        
        // Check if token has expired
        if (_tokenExpiryTime!.isBefore(DateTime.now())) {
          print('Token has expired, clearing');
          _token = null;
          _tokenExpiryTime = null;
          prefs.remove('jwt_token');
          prefs.remove('token_expiry');
        } else {
          print('Token loaded and valid until $_tokenExpiryTime');
        }
      } catch (e) {
        print('Error parsing token expiry date: $e');
      }
    }
    
    notifyListeners();
  }

  Future<void> logout() async {
    await setToken(null);
  }
}