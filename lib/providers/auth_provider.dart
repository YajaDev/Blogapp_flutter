import 'dart:async';

import 'package:blogapp_flutter/helper/api/handle_call.dart';
import 'package:blogapp_flutter/helper/api/safe_call.dart';
import 'package:blogapp_flutter/services/image_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/profile.dart';
import '../models/notif_message.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  User? user;
  Profile? profile;
  bool isLoading = false;
  NotifMessage? message;

  late final StreamSubscription<AuthState> _sub;
  late final ApiCallHandler _apiCallHandler;

  AuthProvider() {
    _init();

    _apiCallHandler = ApiCallHandler(
      startLoading: _startLoading,
      stopLoading: _stopLoading,
      setMessage: _setMessage,
    );
  }

  // ---------------- INIT ----------------

  void _init() {
    _sub = AuthService.authChanges.listen((data) async {
      final newUser = data.session?.user;
      if (user?.id == newUser?.id) return;

      user = newUser;

      if (user == null) {
        profile = null;
        isLoading = false;
        notifyListeners();
        return;
      }

      _startLoading();

      final result = await SafeCall.run<Profile?>(
        () => AuthService.getProfile(user!.id),
      );

      switch (result) {
        case SafeSuccess(data: final profileData):
          if (profileData == null) {
            _setMessage("Profile not found", MessageType.error);
          } else {
            profile = profileData;
          }
          break;

        case SafeFailure(errorMessage: final err):
          profile = null;
          _setMessage(err, MessageType.error);
          break;
      }

      _stopLoading();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  // ---------------- AUTH ----------------

  Future<void> signIn(String email, String password) async {
    await _apiCallHandler.call<User?>(
      () => SafeCall.run(
        () => AuthService.signIn(email: email, password: password),
      ),
      successMessage: 'Signed in successfully',
    );
  }

  Future<void> signUp(String email, String password, String username) async {
    await _apiCallHandler.call<User?>(
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
    profile = null;
    await _apiCallHandler.call<void>(
      () => SafeCall.run(() => AuthService.signOut()),
      successMessage: 'Signed out successfully',
    );
  }

  // ---------------- PROFILE ----------------

  Future<void> updateProfile({
    required String username,
    XFile? newAvatarFile,
    bool removeAvatar = false,
  }) async {
    await _apiCallHandler.call(
      () => SafeCall.run(() async {
        final oldAvatarUrl = profile?.avatarUrl;
        String? avatarUrl = oldAvatarUrl;

        // Upload new avatar if provided
        if (newAvatarFile != null) {
          avatarUrl = await ImageService.uploadImage(
            UploadProps(
              file: newAvatarFile,
              userId: user!.id,
              type: ImageType.avatar,
            ),
          );
        }

        if (removeAvatar) {
          if (oldAvatarUrl != null) {
            await ImageService.deleteImages([
              oldAvatarUrl,
            ], type: ImageType.avatar);
          }

          avatarUrl = null;
        }

        // Update profile in database
        final updatedProfile = await AuthService.updateProfile(user!.id, {
          'username': username,
          'avatar_url': avatarUrl,
        });

        if (updatedProfile == null) throw Exception('Profile update failed');

        profile = updatedProfile;
      }),
      successMessage: 'Profile updated successfully',
    );
  }

  // ---------------- HELPERS ----------------

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
