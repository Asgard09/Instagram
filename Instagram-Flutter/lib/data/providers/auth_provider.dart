import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _token;

  String? get token => _token;
  bool get isAuthenticated => _token != null;

  Future<void> setToken(String? token) async {
    _token = token;
    if (token != null) {
      await SharedPreferences.getInstance()
          .then((prefs) => prefs.setString('jwt_token', token));
    } else {
      await SharedPreferences.getInstance()
          .then((prefs) => prefs.remove('jwt_token'));
    }
    notifyListeners();
  }

  Future<void> loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    notifyListeners();
  }

  Future<void> logout() async {
    await setToken(null);
  }
}