import 'package:blogapp_flutter/models/notif_message.dart';
import 'package:blogapp_flutter/services/auth_service.dart';
import 'package:blogapp_flutter/helper/api/handle_call.dart';
import 'package:blogapp_flutter/helper/api/safe_call.dart';
import 'package:blogapp_flutter/models/blog.dart';
import 'package:blogapp_flutter/services/blog_service.dart';
import 'package:flutter/material.dart';

class BlogProvider extends ChangeNotifier {
  final List<Blog> blogs = [];

  bool isLoading = false;
  bool hasMore = true;
  NotifMessage? message;

  int page = 0;
  final int limit = 10;

  late final ApiCallHandler _apiHandler;

  BlogProvider() {
    _apiHandler = ApiCallHandler(
      startLoading: _startLoading,
      stopLoading: _stopLoading,
      setMessage: _setMessage,
    );
    fetchInitialBlogs();
  }

  // ---------------- FETCH ----------------

  /// Load first page of blogs (pull-to-refresh)
  Future<void> fetchInitialBlogs() async {
    page = 0;
    blogs.clear();
    hasMore = true;

    final data = await _apiHandler.call(
      () =>
          SafeCall.run(() => BlogService.fetchBlogs(page: page, limit: limit)),
    );

    if (data != null) {
      blogs.addAll(data);
      page++;
    }

    notifyListeners();
  }

  /// Load next page of blogs (infinite scroll)
  Future<void> fetchMoreBlogs() async {
    if (!hasMore || isLoading) return;

    final data = await _apiHandler.call(
      () =>
          SafeCall.run(() => BlogService.fetchBlogs(page: page, limit: limit)),
    );

    if (data != null && data.isNotEmpty) {
      blogs.addAll(data);
      page++;
    } else {
      hasMore = false;
    }

    notifyListeners();
  }

  Future<Blog?> fetchBlogWithOwner(String blogId) async {
    return await _apiHandler.call(
      () => SafeCall.run(() async {
        // Fetch blog Details
        final blog = await BlogService.fetchById(blogId);
        if (blog == null) throw Exception('Cant find Blog');

        // Fetch blog Owner
        final owner = await AuthService.getProfile(blog.userId);

        return blog.copyWith(owner: owner);
      }),
    );
  }

  // ---------------- CRUD ----------------

  Future<void> addBlog(UpdateBlog blogDetail) async {
    await _apiHandler.call(
      () => SafeCall.run(() => BlogService.add(blogDetail)),
      successMessage: 'Blog created successfully',
    );

    await fetchInitialBlogs(); // refresh after adding
  }

  Future<void> editBlog(UpdateBlog blogDetail, String id) async {
    await _apiHandler.call(
      () => SafeCall.run(() => BlogService.edit(blogDetail)),
      successMessage: 'Blog updated successfully',
    );

    await fetchInitialBlogs(); // refresh after editing
  }

  Future<void> deleteBlog(String id) async {
    await _apiHandler.call(
      () => SafeCall.run(() => BlogService.delete(id)),
      successMessage: 'Blog deleted successfully',
    );

    blogs.removeWhere((b) => b.id == id);
    notifyListeners();
  }

  Future<Blog?> fetchBlogById(String id) async {
    return await _apiHandler.call<Blog?>(
      () => SafeCall.run(() => BlogService.fetchById(id)),
    );
  }

  // ---------------- INTERNAL HELPERS ----------------

  void _startLoading() {
    isLoading = true;
    notifyListeners();
  }

  void _stopLoading() {
    isLoading = false;
    notifyListeners();
  }

  void _setMessage(String text, MessageType type) {
    message = NotifMessage(text, type);
    notifyListeners();
  }

  void clearMessage() {
    message = null;
    notifyListeners();
  }
}
