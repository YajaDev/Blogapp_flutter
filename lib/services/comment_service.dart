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
    XFile? imageFile,
  }) {
    return SafeCall.run(() async {
      final user = _client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await ImageService.uploadImage(
          UploadProps(
            file: imageFile,
            userId: user.id,
            type: ImageType.comments,
          ),
        );
      }

      final newComment = await _client
          .from('comments')
          .insert({
            'blog_id': blogId,
            'content': content,
            'image_url': imageUrl,
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
    String? existingImageUrl,
    XFile? newImageFile,
    bool removeImage = false,
  }) {
    return SafeCall.run(() async {
      String? imageUrl = existingImageUrl;

      if (removeImage) imageUrl = null;

      if (newImageFile != null) {
        imageUrl = await ImageService.uploadImage(
          UploadProps(
            file: newImageFile,
            userId: _client.auth.currentUser!.id,
            type: ImageType.comments,
          ),
        );
      }

      final editedComment = await _client
          .from('comments')
          .update({'content': content, 'image_url': imageUrl})
          .eq('id', commentId)
          .select('*,profiles(username, avatar_url)')
          .single();

      // Delete old image if replaced or removed
      if (existingImageUrl != null && (newImageFile != null || removeImage)) {
        await ImageService.deleteImage(
          DeleteImageProps(
            imageUrl: existingImageUrl,
            type: ImageType.comments,
          ),
        );
      }

      return Comment.fromJson(editedComment);
    });
  }

  // ---------------- DELETE ----------------
  static Future<SafeResult<bool>> deleteComment({
    required String commentId,
    String? imageUrl,
  }) {
    return SafeCall.run(() async {
      if (imageUrl != null) {
        await ImageService.deleteImage(
          DeleteImageProps(imageUrl: imageUrl, type: ImageType.comments),
        );
      }

      await _client.from('comments').delete().eq('id', commentId);

      return true;
    });
  }
}
