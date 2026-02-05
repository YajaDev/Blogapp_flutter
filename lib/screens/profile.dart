import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final usernameCtrl = TextEditingController();
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    usernameCtrl.text = auth.profile?['username'] ?? '';
  }

  Future<void> saveProfile() async {
    final auth = context.read<AuthProvider>();
    final newUsername = usernameCtrl.text.trim();

    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Username cannot be empty'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSaving = true);

    await auth.updateProfile({'username': newUsername});

    setState(() => isSaving = false);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Username updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> logout() async {
    await context.read<AuthProvider>().signOut();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(onPressed: logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: usernameCtrl,
              decoration: const InputDecoration(labelText: 'Username'),
            ),
            const SizedBox(height: 16),
            isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: saveProfile,
                    child: const Text('Save Username'),
                  ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    usernameCtrl.dispose();
    super.dispose();
  }
}
