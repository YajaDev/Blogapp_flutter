import 'dart:async';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../helper/safe_api_call.dart';
import '../models/ui_message.dart';

class AuthProvider extends ChangeNotifier {
  User? user;
  Map<String, dynamic>? profile;
  bool isLoading = false;
  UiMessage? message;

  late final StreamSubscription<AuthState> _sub;

  AuthProvider() {
    _init();
  }

  void _init() {
    _sub = AuthService.authChanges.listen((data) async {
      final newUser = data.session?.user;

      // early return if user stay the same
      if (user?.id == newUser?.id) return;

      user = newUser;

      if (user != null) {
        // update profile
        profile = await SafeCall.run<Map<String, dynamic>?>(
          () => AuthService.getProfile(user!.id),
        );
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

  Future<void> signIn(String email, String password) async {
    _startLoading();

    final result = await SafeCall.run(
      () => AuthService.signIn(email: email, password: password),
    );

    if (result == null) {
      _setMessage('Sign in failed', MessageType.error);
      _stopLoading();
      return;
    }

    _setMessage('Signed in successfully', MessageType.success);
    _stopLoading();
  }

  Future<void> signUp(String email, String password, String username) async {
    _startLoading();

    final result = await SafeCall.run(
      () => AuthService.signUp(
        email: email,
        password: password,
        username: username,
      ),
    );

    if (result == null) {
      _setMessage('Sign up failed', MessageType.error);
      _stopLoading();
      return;
    }

    _setMessage('Account created successfully', MessageType.success);
    _stopLoading();
  }

  Future<void> signOut() async {
    await SafeCall.run(() => AuthService.signOut());
    _setMessage('Signed out', MessageType.success);
  }

  // ---------------- PROFILE ----------------

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (user == null) return;

    await SafeCall.run(() => AuthService.updateProfile(user!.id, data));

    profile = await AuthService.getProfile(user!.id);
    notifyListeners();
  }

  // ---------------- UI HELPERS ----------------

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

  void _setMessage(String text, MessageType type) {
    message = UiMessage(text, type);
    notifyListeners();
  }
}
