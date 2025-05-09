import 'package:flutter/foundation.dart';
import '../../models/post.dart';
import '../../services/post_service.dart';

class PostsProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchPosts(String token) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final posts = await _postService.getPosts(token);
      _posts = posts;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPost(String imageBase64, String caption, String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final post = await _postService.createPost(
        imageBase64,
        caption,
        token,
      );

      if (post != null) {
        // Refresh the entire posts list to ensure we have the latest data
        await fetchPosts(token);
        
        // If for some reason the post isn't in the list (unlikely but possible),
        // add it to the beginning
        if (!_posts.any((p) => p.id == post.id)) {
          _posts.insert(0, post);
        }
        
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'Failed to create post';
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
} 