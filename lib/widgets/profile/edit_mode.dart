import 'dart:io';

import 'package:blogapp_flutter/models/notif_message.dart';
import 'package:blogapp_flutter/models/profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:image_picker/image_picker.dart';

import 'package:blogapp_flutter/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ProfileEdit extends StatefulWidget {
  final Profile profile;
  final VoidCallback onCancel;

  const ProfileEdit({super.key, required this.profile, required this.onCancel});

  @override
  State<ProfileEdit> createState() => _ProfileEditState();
}

class _ProfileEditState extends State<ProfileEdit> {
  final usernameCtrl = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  XFile? selectedAvatar;
  Uint8List? imageBytes;
  String? currentAvatarUrl;

  bool removedAvatar = false;

  // Setting up initial state
  @override
  void initState() {
    super.initState();
    usernameCtrl.text = widget.profile.username ?? '';
    currentAvatarUrl = widget.profile.avatarUrl;
  }

  Future<void> pickAvatar() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked == null) return;

    // Read bytes for web preview
    final bytes = await picked.readAsBytes();

    if (!mounted) return;

    setState(() {
      selectedAvatar = picked;
      imageBytes = bytes;
      removedAvatar = false;
    });
  }

  void removeAvatar() {
    setState(() {
      selectedAvatar = null;
      currentAvatarUrl = null;
      removedAvatar = true;
    });
  }

  Future<void> saveProfile() async {
    final auth = context.read<AuthProvider>();
    final username = usernameCtrl.text.trim();

    if (username.isEmpty) return;

    await auth.updateProfile(
      username: username,
      removeAvatar: removedAvatar,
      newAvatarFile: selectedAvatar,
    );

    if (!mounted) return;

    // Exit edit mode ONLY on success
    if (auth.message?.type == MessageType.success) widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.profile;
    final auth = context.watch<AuthProvider>();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: selectedAvatar != null
                      ? (kIsWeb
                            ? MemoryImage(imageBytes!)
                            : FileImage(File(selectedAvatar!.path)))
                      : (currentAvatarUrl != null
                            ? NetworkImage(currentAvatarUrl!)
                            : null),
                  child: selectedAvatar == null && currentAvatarUrl == null
                      ? const Icon(Icons.person, size: 60, color: Colors.grey)
                      : null,
                ),

                // Edit Button / Icon
                Positioned(
                  bottom: 12,
                  right: 0,
                  child: GestureDetector(
                    onTap: pickAvatar,
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Theme.of(context).primaryColor,
                      child: const Icon(
                        Icons.edit,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            if (currentAvatarUrl != null || selectedAvatar != null)
              TextButton.icon(
                onPressed: removeAvatar,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Remove Avatar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
              ),
            const SizedBox(height: 24),

            // Username field
            TextFormField(
              controller: usernameCtrl,
              decoration: const InputDecoration(
                labelText: 'Username',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Email field
            TextFormField(
              initialValue: auth.user?.email ?? 'No email',
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // User ID field
            TextFormField(
              initialValue: profile.id,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'User ID',
                prefixIcon: Icon(Icons.badge),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Created account date
            TextFormField(
              initialValue: profile.createdAt
                  .toLocal()
                  .toString()
                  .split(' ')
                  .first,
              enabled: false,
              decoration: const InputDecoration(
                labelText: 'Joined',
                prefixIcon: Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: auth.isLoading ? null : saveProfile,
                    icon: const Icon(Icons.save),
                    label: Text(auth.isLoading ? 'Saving...' : 'Save'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : widget.onCancel,
                    child: const Text('Cancel'),
                  ),
                ),
              ],
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
