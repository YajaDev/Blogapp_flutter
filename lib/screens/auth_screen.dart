import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../models/notif_message.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreen();
}

class _AuthScreen extends State<AuthScreen> {
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final usernameCtrl = TextEditingController();

  bool isLogin = true;

  @override
  void dispose() {
    emailCtrl.dispose();
    passCtrl.dispose();
    usernameCtrl.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    final auth = context.read<AuthProvider>();

    final email = emailCtrl.text.trim();
    final password = passCtrl.text.trim();
    final username = usernameCtrl.text.trim();

    if (isLogin) {
      await auth.signIn(email, password);
    } else {
      await auth.signUp(email, password, username);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Show SnackBar on message
    if (auth.message != null && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isLogin)
              TextField(
                controller: usernameCtrl,
                decoration: const InputDecoration(labelText: 'Username'),
                textInputAction: TextInputAction.next,
              ),
            TextField(
              controller: emailCtrl,
              decoration: const InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
            ),
            TextField(
              controller: passCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              textInputAction: TextInputAction.done,
            ),
            const SizedBox(height: 16),
            auth.isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: auth.isLoading ? null : submit,
                    child: Text(isLogin ? 'Login' : 'Sign Up'),
                  ),
            TextButton(
              onPressed: () => setState(() => isLogin = !isLogin),
              child: Text(
                isLogin ? 'Create account' : 'Already have an account?',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
