import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SafeCall {
  static Future<T?> run<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException catch (e) {
      debugPrint('Auth error: ${e.message}');
      return null;
    } on PostgrestException catch (e) {
      debugPrint('DB error: ${e.message}');
      return null;
    } catch (e) {
      debugPrint('Unknown error: $e');
      return null;
    }
  }
}
