import 'package:flutter/foundation.dart';
import '../../services/comment_service.dart';

class CommentsProvider extends ChangeNotifier {
  final CommentService _commentService = CommentService();
  
  // Map of postId to comment count
  final Map<int, int> _commentCounts = {};
  
  // Get methods
  int getCommentCount(int postId) => _commentCounts[postId] ?? 0;
  
  // Fetch comment count for a post
  Future<void> fetchCommentCount(String token, int postId) async {
    try {
      final count = await _commentService.getCommentCount(token, postId);
      _commentCounts[postId] = count;
      notifyListeners();
    } catch (e) {
      print('Error fetching comment count: $e');
    }
  }
  
  // Update comment count when a new comment is added
  void incrementCommentCount(int postId) {
    _commentCounts[postId] = (_commentCounts[postId] ?? 0) + 1;
    notifyListeners();
  }
  
  // Update comment count when a comment is deleted
  void decrementCommentCount(int postId) {
    _commentCounts[postId] = (_commentCounts[postId] ?? 1) - 1;
    if (_commentCounts[postId]! < 0) _commentCounts[postId] = 0;
    notifyListeners();
  }
} 