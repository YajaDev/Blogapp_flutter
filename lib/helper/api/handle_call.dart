import 'package:blogapp_flutter/helper/api/safe_call.dart';
import 'package:blogapp_flutter/models/notif_message.dart';

typedef LoadingCallback = void Function();
typedef MessageCallback = void Function(String message, MessageType type);

class ApiCallHandler {
  final LoadingCallback _startLoading;
  final LoadingCallback _stopLoading;
  final MessageCallback _setMessage;

  ApiCallHandler({
    required LoadingCallback startLoading,
    required LoadingCallback stopLoading,
    required MessageCallback setMessage,
  })  : _startLoading = startLoading,
        _stopLoading = stopLoading,
        _setMessage = setMessage;

  /// Call API safely with optional success message
  Future<T?> call<T>(
    Future<SafeResult<T>> Function() action, {
    String? successMessage,
  }) async {
    _startLoading();

    try {
      final result = await action();

      switch (result) {
        case SafeSuccess(data: final d):
          if (successMessage != null) {
            _setMessage(successMessage, MessageType.success);
          }
          return d;

        case SafeFailure(errorMessage: final err):
          _setMessage(err, MessageType.error);
          return null;
      }
    } finally {
      _stopLoading();
    }
  }
}
