import 'dart:async';

import 'package:blogapp_flutter/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../models/notif_message.dart';
import '../services/auth_service.dart';
import '../helper/safe_api_call.dart';

class AuthProvider extends ChangeNotifier {
  User? user;
  Profile? profile;
  bool isLoading = false;
  NotifMessage? message;

  late final StreamSubscription<AuthState> _sub;

  AuthProvider() {
    _init();
  }

  // ---------------- INIT ----------------

  void _init() {
    _sub = AuthService.authChanges.listen((data) async {
      final newUser = data.session?.user;

      // early return if user stay the same
      if (user?.id == newUser?.id) return;

      user = newUser;

      if (user != null) {
        final result = await SafeCall.run<Profile?>(
          () => AuthService.getProfile(user!.id),
        );

        switch (result) {
          case SafeSuccess(data: final profileData):
            profile = profileData;
            break;

          case SafeFailure(errorMessage: final err):
            profile = null;
            message = NotifMessage(err, MessageType.error);
            break;
        }
      } else {
        profile = null;
      }

      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  // ---------------- AUTH ----------------

  Future<void> signIn(String email, String password) async {
    await _handleApiCall<User?>(
      () => SafeCall.run(
        () => AuthService.signIn(email: email, password: password),
      ),
      successMessage: 'Signed in successfully',
    );
  }

  Future<void> signUp(String email, String password, String username) async {
    await _handleApiCall<User?>(
      () => SafeCall.run(
        () => AuthService.signUp(
          email: email,
          password: password,
          username: username,
        ),
      ),
      successMessage: 'Account created successfully',
    );
  }

  Future<void> signOut() async {
    await _handleApiCall<void>(
      () => SafeCall.run(() => AuthService.signOut()),
      successMessage: 'Signed out successfully',
    );
  }

  // ---------------- PROFILE ----------------

  Future<void> updateProfile(Map<String, dynamic> data) async {
    final oldAvatar = profile?.avatarUrl;

    final hasNewAvatar =
        data.containsKey('avatar_url') && data['avatar_url'] != null;

    final removedAvatar =
        data.containsKey('avatar_url') && data['avatar_url'] == null;

    await _handleApiCall<void>(
      () => SafeCall.run(() async {
        final updatedProfile = await AuthService.updateProfile(user!.id, data);

        if (updatedProfile == null) throw Exception('Profile update failed');
        profile = updatedProfile;

        // Delete previous avatar url 
        if ((hasNewAvatar || removedAvatar) && oldAvatar != null) {
          await ImageService.deleteImage(
            DeleteImageProps(imageUrl: oldAvatar, type: ImageType.avatar),
          );
        }
      }),
      successMessage: 'Profile updated successfully',
    );
  }

  // ---------------- HELPERS ----------------

  Future<T?> _handleApiCall<T>(
    Future<SafeResult<T>> Function() action, {
    String? successMessage,
  }) async {
    _startLoading();

    final result = await action();
    T? data;

    switch (result) {
      case SafeSuccess(data: final d):
        data = d;
        if (successMessage != null) {
          _setMessage(successMessage, MessageType.success);
        }
        break;

      case SafeFailure(errorMessage: final err):
        _setMessage(err, MessageType.error);
        break;
    }

    _stopLoading();
    return data;
  }

  void _setMessage(String text, MessageType type) {
    message = NotifMessage(text, type);
    notifyListeners();
  }

  void clearMessage() {
    message = null;
    notifyListeners();
  }

  void _startLoading() {
    isLoading = true;
    message = null;
    notifyListeners();
  }

  void _stopLoading() {
    isLoading = false;
    notifyListeners();
  }
}
