import 'package:blogapp_flutter/models/blog.dart';
import 'package:blogapp_flutter/providers/auth_provider.dart';
import 'package:blogapp_flutter/providers/blog_provider.dart';
import 'package:blogapp_flutter/widgets/blog_list/card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlogList extends StatefulWidget {
  const BlogList({super.key});

  @override
  State<BlogList> createState() => _BlogListState();
}

class _BlogListState extends State<BlogList> {
  List<Blog> _userBlogs = []; // Changed from List<Blog?> to List<Blog>
  bool _isLoading = true; // Added underscore for consistency

  @override
  void initState() {
    super.initState();

    // Load user blogs after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadUserBlogs();
    });
  }

  Future<void> _loadUserBlogs() async {
    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final blogProvider = context.read<BlogProvider>();

    // Check if user is authenticated
    if (authProvider.user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Fetch blogs for the current user
    final blogs = await blogProvider.fetchBlogsByUserId(authProvider.user!.id);

    if (!mounted) return;

    setState(() {
      _userBlogs = blogs ?? [];
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_userBlogs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.article_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No blogs yet',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first blog post!',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _userBlogs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final blog = _userBlogs[index];
        return BlogCard(
          blog: blog,
          index: index + 1,
          onRefresh: _loadUserBlogs, // Added callback
        );
      },
    );
  }
}
