import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class FacebookAuthService {
  Future<Map<String, dynamic>?> signInWithFacebook() async {
    try {
      // Attempt login
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        // Get token
        final String token = result.accessToken!.token;

        // Get user data
        final userData = await FacebookAuth.instance.getUserData();

        // Send token to your Spring Boot backend for verification
        final response = await http.post(
          Uri.parse('YOUR_BACKEND_URL/api/auth/facebook'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'token': token, 'userData': userData}),
        );

        if (response.statusCode == 200) {
          return json.decode(response.body);
        }
      }
      return null;
    } catch (e) {
      print('Facebook login error: $e');
      return null;
    }
  }
}