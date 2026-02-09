import 'package:blogapp_flutter/models/notif_message.dart';
import 'package:blogapp_flutter/widgets/profile/display_mode.dart';
import 'package:blogapp_flutter/widgets/profile/edit_mode.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isEditing = false;

  void toggleEdit(bool value) {
    setState(() => isEditing = value);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final profile = auth.profile;

    if (profile == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

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

        auth.clearMessage();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: auth.isLoading ? null : auth.signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: isEditing
            ? ProfileEdit(profile: profile, onCancel: () => toggleEdit(false))
            : ProfileDisplay(profile: profile, onEdit: () => toggleEdit(true)),
      ),
    );
  }
}
