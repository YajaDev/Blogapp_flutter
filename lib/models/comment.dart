class Comment {
  final String id;
  final String blogId;
  final String userId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;

  final String? username;
  final String? avatarUrl;

  Comment({
    required this.id,
    required this.blogId,
    required this.userId,
    required this.content,
    this.imageUrl,
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
      imageUrl: json['image_url'],
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
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
