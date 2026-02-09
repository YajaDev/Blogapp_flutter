import 'package:flutter/material.dart';

import 'package:blogapp_flutter/providers/auth_provider.dart';
import 'package:provider/provider.dart';

import 'package:blogapp_flutter/models/profile.dart';

class ProfileDisplay extends StatelessWidget {
  final Profile profile;
  final VoidCallback onEdit;

  const ProfileDisplay({
    super.key,
    required this.profile,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    return Column(
      children: [
        CircleAvatar(
          radius: 60,
          backgroundImage: profile.avatarUrl != null
              ? NetworkImage(profile.avatarUrl!)
              : null,
          child: profile.avatarUrl == null
              ? const Icon(Icons.person, size: 60, color: Colors.grey)
              : null,
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            const Icon(Icons.email, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              auth.user?.email ?? 'No email',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Icon(Icons.person, color: Colors.grey),
            const SizedBox(width: 8),
            Text(
              profile.username ?? 'No username',
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: onEdit,
          icon: const Icon(Icons.edit),
          label: const Text('Edit Profile'),
        ),
      ],
    );
  }
}
