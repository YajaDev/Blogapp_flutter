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
  @override
  void initState() {
    super.initState();

    // Load user blogs after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      context.read<BlogProvider>().fetchBlogsByUserId(auth.user!.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BlogProvider>();
    final blogs = provider.userBlogs;

    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (blogs.isEmpty) {
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
      itemCount: blogs.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final blog = blogs[index];
        return BlogCard(
          blog: blog,
          index: index + 1,
          onDelete: (id) =>
              context.read<BlogProvider>().deleteBlog(id),
        );
      },
    );
  }
}
