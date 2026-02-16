import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/notif_message.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();

  bool _isLogin = true;
  bool _obscurePass = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();
    final password = _passCtrl.text.trim();
    final username = _usernameCtrl.text.trim();

    if (_isLogin) {
      await auth.signIn(email, password);
    } else {
      await auth.signUp(email, password, username);
    }
  }

  void _toggleMode() {
    setState(() => _isLogin = !_isLogin);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 600; // Responsive breakpoint

    // Show SnackBar on message
    if (auth.message != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final msg = auth.message;
        if (msg == null) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg.text),
            backgroundColor: msg.type == MessageType.error
                ? Colors.red
                : Colors.green,
          ),
        );

        context.read<AuthProvider>().clearMessage();
      });
    }

    return Scaffold(
      body: Center(
        child: Container(
          width: isWide ? 480 : null,
          padding: EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ---------------- HEADER ----------------
              Icon(
                Icons.article_outlined,
                size: isWide ? 64 : 48,
                color: Theme.of(context).colorScheme.primary,
              ),

              const SizedBox(height: 16),

              Text(
                _isLogin ? 'Welcome Back' : 'Create Account',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isWide ? 32 : 26,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
                _isLogin ? 'Sign in to continue' : 'Join us and start blogging',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),

              const SizedBox(height: 32),

              // ---------------- FIELDS ----------------
              if (!_isLogin) ...[
                TextField(
                  controller: _usernameCtrl,
                  decoration: const InputDecoration(labelText: 'Username'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _emailCtrl,
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
              ),

              const SizedBox(height: 16),

              TextField(
                controller: _passCtrl,
                obscureText: _obscurePass,
                decoration: InputDecoration(
                  labelText: 'Password',
                  // Show/hide password toggle
                  suffixIcon: IconButton(
                    icon: Icon(
                      size: 20,
                      _obscurePass
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePass = !_obscurePass),
                  ),
                ),
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => auth.isLoading ? null : _submit(),
              ),

              const SizedBox(height: 32),

              // ---------------- SUBMIT ----------------
              auth.isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isLogin ? 'Login' : 'Sign Up'),
                    ),

              const SizedBox(height: 16),

              // ---------------- TOGGLE ----------------
              TextButton(
                onPressed: _toggleMode,
                child: Text(
                  _isLogin ? 'Create account' : 'Already have an account?',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
