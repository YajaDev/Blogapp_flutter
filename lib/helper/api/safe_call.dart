import 'package:supabase_flutter/supabase_flutter.dart';

sealed class SafeResult<T> {
  const SafeResult();
}

class SafeSuccess<T> extends SafeResult<T> {
  final T data;
  const SafeSuccess(this.data);
}

class SafeFailure<T> extends SafeResult<T> {
  final String errorMessage;

  const SafeFailure(this.errorMessage);
}

class SafeCall {
  static Future<SafeResult<T>> run<T>(Future<T> Function() action) async {
    try {
      return SafeSuccess(await action());
    } catch (e) {
      switch (e) {
        case AuthException(message: final msg):
          return SafeFailure(msg);
        case PostgrestException(message: final msg):
          return SafeFailure(msg);
        case Exception():
          String message = e.toString().toString().trim();
          return SafeFailure(message);
        default:
          return SafeFailure('Unknown error');
      }
    }
  }
}

// class SafeCall {
//   static Future<T?> run<T>(Future<T> Function() action) async {
//     try {
//       return await action();
//     } on AuthException catch (e) {
//       debugPrint('Auth error: ${e.message}');
//       return null;
//     } on PostgrestException catch (e) {
//       debugPrint('DB error: ${e.message}');
//       return null;
//     } catch (e) {
//       debugPrint('Unknown error: $e');
//       return null;
//     }
//   }
// }
