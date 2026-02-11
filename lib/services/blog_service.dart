import 'package:blogapp_flutter/models/blog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> add(UpdateBlog blogDetail) async {
    await _client.from('blogs').insert(blogDetail.toJson());
  }

  static Future<void> edit(UpdateBlog blogDetail, String id) async {
    await _client.from('blogs').update(blogDetail.toJson()).eq('id', id);
  }

  static Future<void> delete(String id) async {
    await _client.from('blogs').delete().eq('id', id);
  }

  static Future<List<Blog>> fetchBlogs({int page = 0, int limit = 10}) async {
    final from = page * limit;
    final to = from + limit - 1;

    final data = await _client
        .from('blogs')
        .select()
        .order('created_at', ascending: false)
        .range(from, to);

    return data.map((blog) => Blog.fromJson(blog)).toList();
  }

  static Future<List<Blog>> fetchBlogsByUser(String userId) async {
    final data = await _client
        .from('blogs')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return data.map((json) => Blog.fromJson(json)).toList();  
  }

  static Future<Blog?> fetchById(String id) async {
    final data = await _client
        .from('blogs')
        .select()
        .eq('id', id)
        .maybeSingle();

    if (data == null) return null;

    return Blog.fromJson(data);
  }
}
