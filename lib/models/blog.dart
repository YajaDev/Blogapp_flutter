import './profile.dart';

class Blog {
  final String id;
  final String userId;
  final String title;
  final String? subtitle;
  final String description;
  final List<String> imagesUrl;
  final DateTime createdAt;

  final Profile? owner;

  Blog({
    required this.id,
    required this.userId,
    required this.title,
    this.subtitle,
    required this.description,
    this.imagesUrl = const [],
    required this.createdAt,
    this.owner,
  });

  factory Blog.fromJson(Map<String, dynamic> json) {
    return Blog(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      subtitle: json['subtitle'],
      description: json['description'],
      imagesUrl: json['images_url'] != null
          ? List<String>.from(json['images_url'])
          : [],
      createdAt: DateTime.parse(json['created_at'] as String),
      owner: json['profiles'] != null
          ? Profile.fromJson(json['profiles'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'subtitle': subtitle,
      'description': description,
      'images_url': imagesUrl,
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
      imagesUrl: imagesUrl,
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
  final List<String>? imagesUrl;

  UpdateBlog({
    this.userId,
    this.id,
    this.title,
    this.subtitle,
    this.description,
    this.imagesUrl,
  });

  Map<String, dynamic> toJson() {
    final data = <String, dynamic>{};
    if (title != null) data['title'] = title;
    if (subtitle != null) data['subtitle'] = subtitle;
    if (description != null) data['description'] = description;
    data['images_url'] = imagesUrl;
    return data;
  }
}
