import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum ImageType { blog, comments, avatar}

class UploadProps {
  final File file;
  final String userId;
  final ImageType type;

  UploadProps({required this.file, required this.userId, required this.type});
}

class DeleteImageProps {
  final String imageUrl;
  final ImageType type;

  DeleteImageProps({required this.imageUrl, required this.type});
}

class ImageService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final Uuid _uuid = const Uuid();

  static String _getImageTypeName(ImageType type) {
    switch (type) {
      case ImageType.avatar:
        return 'avatar';
      case ImageType.blog:
        return 'blog-images';
      case ImageType.comments:
        return 'comments-images';
    }
  }

  static Future<String> uploadImage(UploadProps props) async {
    final fileExt = props.file.path.split('.').last;
    final fileName = '${props.userId}/${_uuid.v4()}.$fileExt';
    final typeName = _getImageTypeName(props.type);

    await _supabase.storage
        .from(typeName)
        .upload(
          fileName,
          props.file,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
        );

    final publicUrl = _supabase.storage
        .from(typeName)
        .getPublicUrl(fileName);

    return publicUrl;
  }

  static Future<void> deleteImage(DeleteImageProps props) async {
    final pathParts = props.imageUrl.split('/');
    final fileName = pathParts.sublist(pathParts.length - 2).join('/');
    final typeName = _getImageTypeName(props.type);

    await _supabase.storage.from(typeName).remove([fileName]);
  }
}
