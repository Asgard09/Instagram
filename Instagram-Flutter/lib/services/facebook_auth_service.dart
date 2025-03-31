import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FacebookAuthService {
  static final FacebookAuth _facebookAuth = FacebookAuth.instance;

  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      final LoginResult result = await _facebookAuth.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status == LoginStatus.success) {
        // Get user data
        final userData = await _facebookAuth.getUserData();
        return userData;
      }
    } catch (e) {
      print('Facebook Sign In Error: $e');
      return null;
    }
    return null;
  }

  Future<void> signOut() async {
    await _facebookAuth.logOut();
  }
}