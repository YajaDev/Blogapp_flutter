import 'dart:io';

import 'package:blogapp_flutter/models/notif_message.dart';
import 'package:blogapp_flutter/services/auth_service.dart';
import 'package:blogapp_flutter/helper/api/handle_call.dart';
import 'package:blogapp_flutter/helper/api/safe_call.dart';
import 'package:blogapp_flutter/models/blog.dart';
import 'package:blogapp_flutter/services/blog_service.dart';
import 'package:blogapp_flutter/services/image_service.dart';
import 'package:flutter/material.dart';

enum AddOrEditType { add, edit }

class BlogProvider extends ChangeNotifier {
  final List<Blog> blogs = [];
  final List<Blog> userBlogs = [];

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

  Future<Blog?> fetchBlogById(String id) async {
    return await _apiHandler.call<Blog?>(
      () => SafeCall.run(() => BlogService.fetchById(id)),
    );
  }

  Future<void> fetchBlogsByUserId(String userId) async {
    final data = await _apiHandler.call(
      () => SafeCall.run(() => BlogService.fetchBlogsByUser(userId)),
    );

    if (data != null) {
      userBlogs
        ..clear()
        ..addAll(data);
      notifyListeners();
    }
  }

  // ---------------- DELETE ----------------

  Future<Blog?> deleteBlog(String id) async {
    final result = await _apiHandler.call(
      () => SafeCall.run(() => BlogService.delete(id)),
      successMessage: 'Blog deleted successfully',
    );

    blogs.removeWhere((b) => b.id == id);
    userBlogs.removeWhere((b) => b.id == id);

    return result;
  }

  // ---------------- ADD / EDIT ----------------

  Future<Blog?> addOrEdit(
    AddOrEditType type,
    UpdateBlog blogDetail, {
    required bool deleteImage,
    String? successMessage,
    File? file,
  }) async {
    return await _apiHandler.call(
      () => SafeCall.run(() async {
        String? imageUrl = deleteImage ? null : blogDetail.imageUrl;

        // Upload image
        if (file != null) {
          imageUrl = await ImageService.uploadImage(
            UploadProps(
              file: file,
              userId: blogDetail.userId!,
              type: ImageType.blog,
            ),
          );
        }

        final blog = UpdateBlog(
          id: blogDetail.id,
          userId: blogDetail.userId,
          title: blogDetail.title,
          subtitle: blogDetail.subtitle,
          description: blogDetail.description,
          imageUrl: imageUrl,
        );

        Blog? newBlog;

        switch (type) {
          case AddOrEditType.add:
            newBlog = await BlogService.add(blog);
            blogs.insert(0, newBlog);
            userBlogs.insert(0, newBlog);
            break;

          case AddOrEditType.edit:
            if (blog.id == null) {
              throw Exception('Blog ID is required for editing');
            }
            newBlog = await BlogService.edit(blog, blog.id!);
            final i1 = blogs.indexWhere((b) => b.id == newBlog!.id);
            if (i1 != -1) blogs[i1] = newBlog;
            final i2 = userBlogs.indexWhere((b) => b.id == newBlog!.id);
            if (i2 != -1) userBlogs[i2] = newBlog;
            break;
        }

        if (blog.imageUrl != null &&
            type.toString() == "edit" &&
            (deleteImage || file != null)) {
          ImageService.deleteImage(
            DeleteImageProps(imageUrl: blog.imageUrl!, type: ImageType.blog),
          );
        }

        return newBlog;
      }),
      successMessage: successMessage,
    );
  }

  Future<Blog?> addBlog(UpdateBlog blogDetail, {File? file}) async {
    return await addOrEdit(
      AddOrEditType.add,
      blogDetail,
      deleteImage: false,
      file: file,
      successMessage: 'Blog created successfully',
    );
  }

  Future<Blog?> editBlog(
    UpdateBlog blogDetail, {
    required bool deleteImage,
    File? file,
  }) async {
    return await addOrEdit(
      AddOrEditType.edit,
      blogDetail,
      file: file,
      deleteImage: deleteImage,
      successMessage: 'Blog updated successfully',
    );
  }

  // ---------------- HELPERS ----------------

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
