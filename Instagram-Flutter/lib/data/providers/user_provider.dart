import 'package:flutter/foundation.dart';
import '../../models/user.dart';
import '../../services/user_service.dart';

class UserProvider extends ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _error;
  final UserService _userService = UserService();

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Get the current user profile
  Future<void> fetchCurrentUser(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final user = await _userService.getCurrentUser(token);
      _user = user;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update the user's bio
  Future<bool> updateBio(String bio, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _userService.updateBio(bio, token);
      if (updatedUser != null) {
        _user = updatedUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update bio';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update the user's profile
  Future<bool> updateProfile({
    required String token,
    String? username,
    String? name,
    String? bio,
    Gender? gender,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _userService.updateProfile(
        token: token,
        username: username,
        name: name,
        bio: bio,
        gender: gender,
      );

      if (updatedUser != null) {
        _user = updatedUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update profile image
  Future<bool> updateProfileImage(String imagePath, String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updatedUser = await _userService.updateProfileImage(imagePath, token);
      if (updatedUser != null) {
        _user = updatedUser;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to update profile image';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear user data (for logout)
  void clearUser() {
    _user = null;
    _error = null;
    notifyListeners();
  }
} 