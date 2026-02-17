class Comment {
  final String id;
  final String blogId;
  final String userId;
  final String content;
  final List<String>? imagesUrl;
  final DateTime createdAt;

  final String? username;
  final String? avatarUrl;

  Comment({
    required this.id,
    required this.blogId,
    required this.userId,
    required this.content,
    this.imagesUrl = const [],
    required this.createdAt,
    this.username,
    this.avatarUrl,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    final profiles = json['profiles'] ?? {};
    return Comment(
      id: json['id'],
      blogId: json['blog_id'],
      userId: json['user_id'],
      content: json['content'],
      imagesUrl: json['images_url'] != null
          ? List<String>.from(json['images_url'])
          : [],
      createdAt: DateTime.parse(json['created_at']),
      username: profiles['username'],
      avatarUrl: profiles['avatar_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'blog_id': blogId,
      'content': content,
      'images_url': imagesUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
