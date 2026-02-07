class Profile {
  final String id;
  final String? username;
  final String? avatarUrl;
  final DateTime createdAt;

  const Profile({
    required this.id,
    this.username,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      username: json['username'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'avatar_url': avatarUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // For updates (safe)
  Map<String, dynamic> toUpdateJson() {
    final data = <String, dynamic>{};

    if (username != null) data['username'] = username;
    if (avatarUrl != null) data['avatar_url'] = avatarUrl;

    return data;
  }
}
