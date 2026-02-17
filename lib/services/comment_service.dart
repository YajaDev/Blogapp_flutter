import 'package:blogapp_flutter/helper/api/safe_call.dart';
import 'package:blogapp_flutter/models/comment.dart';
import 'package:blogapp_flutter/services/image_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CommentService {
  static final SupabaseClient _client = Supabase.instance.client;

  // ---------------- FETCH ----------------
  static Future<SafeResult<List<Comment>>> getBlogComments(String blogId) {
    return SafeCall.run(() async {
      final data = await _client
          .from('comments')
          .select('*, profiles(username, avatar_url)')
          .eq('blog_id', blogId)
          .order('created_at', ascending: false)
          .limit(50);

      return data.map((e) => Comment.fromJson(e)).toList();
    });
  }

  // ---------------- ADD ----------------
  static Future<SafeResult<Comment>> addComment({
    required String blogId,
    required String content,
    required List<XFile> imageFiles,
  }) {
    return SafeCall.run(() async {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      List<String> imageUrl = [];
      if (imageFiles.isNotEmpty) {
        imageUrl = await ImageService.uploadImages(
          imageFiles,
          userId: user.id,
          type: ImageType.comments,
        );
      }

      final newComment = await _client
          .from('comments')
          .insert({
            'blog_id': blogId,
            'content': content,
            'images_url': imageUrl,
          })
          .select('*,profiles(username, avatar_url)')
          .single();

      return Comment.fromJson(newComment);
    });
  }

  // ---------------- EDIT ----------------
  static Future<SafeResult<Comment>> editComment({
    required String commentId,
    required String content,
    List<String> existingImageUrls = const [],
    List<String> imagesToDelete = const [],
    required List<XFile> newImageFiles,
  }) {
    return SafeCall.run(() async {
      List<String> imagesUrl = existingImageUrls;

      if (newImageFiles.isNotEmpty) {
        final newImagesUrl = await ImageService.uploadImages(
          newImageFiles,
          userId: _client.auth.currentUser!.id,
          type: ImageType.comments,
        );

        imagesUrl.addAll(newImagesUrl);
      }

      if (imagesToDelete.isNotEmpty) {
        imagesUrl.removeWhere((url) => imagesToDelete.contains(url));
      }

      final editedComment = await _client
          .from('comments')
          .update({'content': content, 'images_url': imagesUrl})
          .eq('id', commentId)
          .select('*,profiles(username, avatar_url)')
          .single();

      // Delete old image if replaced or removed
      if (imagesToDelete.isNotEmpty) {
        await ImageService.deleteImages(
          imagesToDelete,
          type: ImageType.comments,
        );
      }

      return Comment.fromJson(editedComment);
    });
  }

  // ---------------- DELETE ----------------
  static Future<SafeResult<bool>> deleteComment({
    required String commentId,
    List<String> imagesUrl = const [],
  }) {
    return SafeCall.run(() async {
      if (imagesUrl.isNotEmpty) {
        await ImageService.deleteImages(
          imagesUrl,
          type: ImageType.comments
        );
      }

      await _client.from('comments').delete().eq('id', commentId);

      return true;
    });
  }
}
