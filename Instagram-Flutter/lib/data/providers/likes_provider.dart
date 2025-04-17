import 'package:flutter/foundation.dart';
import '../../services/like_service.dart';

class LikesProvider extends ChangeNotifier {
  final LikeService _likeService = LikeService();
  
  // Map of postId to liked status
  final Map<int, bool> _likedPosts = {};
  
  // Map of postId to like count
  final Map<int, int> _likeCounts = {};
  
  // Get methods
  bool isPostLiked(int postId) => _likedPosts[postId] ?? false;
  int getLikeCount(int postId) => _likeCounts[postId] ?? 0;
  
  // Fetch initial like status for a post
  Future<void> fetchLikeStatus(String token, int postId) async {
    try {
      final liked = await _likeService.hasLiked(token, postId);
      _likedPosts[postId] = liked;
      notifyListeners();
    } catch (e) {
      print('Error fetching like status: $e');
    }
  }
  
  // Fetch initial like count for a post
  Future<void> fetchLikeCount(String token, int postId) async {
    try {
      final count = await _likeService.getLikeCount(token, postId);
      _likeCounts[postId] = count;
      notifyListeners();
    } catch (e) {
      print('Error fetching like count: $e');
    }
  }
  
  // Like a post
  Future<bool> likePost(String token, int postId) async {
    try {
      final success = await _likeService.likePost(token, postId);
      if (success) {
        _likedPosts[postId] = true;
        _likeCounts[postId] = (_likeCounts[postId] ?? 0) + 1;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error in like post provider: $e');
      return false;
    }
  }
  
  // Unlike a post
  Future<bool> unlikePost(String token, int postId) async {
    try {
      final success = await _likeService.unlikePost(token, postId);
      if (success) {
        _likedPosts[postId] = false;
        _likeCounts[postId] = (_likeCounts[postId] ?? 1) - 1;
        if (_likeCounts[postId]! < 0) _likeCounts[postId] = 0;
        notifyListeners();
      }
      return success;
    } catch (e) {
      print('Error in unlike post provider: $e');
      return false;
    }
  }
  
  // Toggle like status of a post
  Future<bool> toggleLike(String token, int postId) async {
    final isLiked = _likedPosts[postId] ?? false;
    if (isLiked) {
      return await unlikePost(token, postId);
    } else {
      return await likePost(token, postId);
    }
  }
} 