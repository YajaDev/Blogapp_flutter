import './profile.dart';

class Blog {
  final String id;
  final String userId;
  final String title;
  final String? subtitle;
  final String description;
  final String? imageUrl;
  final DateTime createdAt;

  final Profile? owner;

  Blog({
    required this.id,
    required this.userId,
    required this.title,
    this.subtitle,
    required this.description,
    this.imageUrl,
    required this.createdAt,
    this.owner,
  });

  factory Blog.fromJson(Map<String, dynamic> json, {Profile? owner}) {
    return Blog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      title: json['title'] as String,
      subtitle: json['subtitle'] as String?,
      description: json['description'] as String,
      imageUrl: json['img_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      owner: owner,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'img_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Blog copyWith({Profile? owner}) {
    return Blog(
      id: id,
      userId: userId,
      title: title,
      subtitle: subtitle,
      description: description,
      imageUrl: imageUrl,
      createdAt: createdAt,
      owner: owner ?? this.owner,
    );
  }
}

class UpdateBlog {
  final String? id;
  final String? userId;
  final String? title;
  final String? subtitle;
  final String? description;
  final String? imageUrl;

  UpdateBlog({
    this.userId,
    this.id,
    this.title,
    this.subtitle,
    this.description,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (subtitle != null) data['subtitle'] = subtitle;
    if (description != null) data['description'] = description;
    data['img_url'] = imageUrl;
    return data;
  }
}
