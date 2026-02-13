import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

enum ImageType { blog, comments, avatar }

class UploadProps {
  final XFile file;
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

  static String _getFileExt(XFile file) {
    // Try mimeType first (reliable on web)
    final mime = file.mimeType;
    if (mime != null) {
      if (mime.contains('jpeg') || mime.contains('jpg')) return 'jpg';
      if (mime.contains('png')) return 'png';
      if (mime.contains('webp')) return 'webp';
      if (mime.contains('gif')) return 'gif';
    }

    // Try from file name
    final name = file.name;
    if (name.contains('.')) {
      return name.split('.').last.toLowerCase();
    }

    return 'jpg'; // fallback
  }

  static String _getMimeType(String ext) {
    switch (ext.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  static Future<String> uploadImage(UploadProps props) async {
    final fileExt = _getFileExt(props.file); // ✅ Use helper
    final mime = _getMimeType(fileExt);
    final typeName = _getImageTypeName(props.type);

    final fileName = props.type == ImageType.avatar
        ? '${props.userId}/avatar'
        : '${props.userId}/${_uuid.v4()}.$fileExt';

    // Always use bytes - works on both web and mobile
    final bytes = await props.file.readAsBytes();

      await _supabase.storage
        .from(typeName)
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: FileOptions(
            cacheControl: '3600',
            upsert: props.type == ImageType.avatar, // upsert for avatar
            contentType: mime,
          ),
        );

    final publicUrl = _supabase.storage.from(typeName).getPublicUrl(fileName);

    return props.type == ImageType.avatar
        ? '$publicUrl?t=${DateTime.now().millisecondsSinceEpoch}'
        : publicUrl;
  }

  static Future<void> deleteImage(DeleteImageProps props) async {
    final pathParts = props.imageUrl.split('/');
    final fileName = pathParts.sublist(pathParts.length - 2).join('/');
    final typeName = _getImageTypeName(props.type);

    await _supabase.storage.from(typeName).remove([fileName]);
  }
}
