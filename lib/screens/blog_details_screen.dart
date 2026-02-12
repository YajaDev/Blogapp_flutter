import 'package:blogapp_flutter/helper/date.dart';
import 'package:blogapp_flutter/models/blog.dart';
import 'package:blogapp_flutter/providers/blog_provider.dart';
import 'package:blogapp_flutter/widgets/coment/comment_container.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class BlogDetailPage extends StatefulWidget {
  final String blogId;
  const BlogDetailPage({super.key, required this.blogId});

  @override
  State<BlogDetailPage> createState() => _BlogDetailPageState();
}

class _BlogDetailPageState extends State<BlogDetailPage> {
  Blog? blog;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    // ✅ Schedule after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBlog();
    });
  }

  Future<void> _loadBlog() async {
    final blogDetail = await context.read<BlogProvider>().fetchBlogWithOwner(
      widget.blogId,
    );

    if (!mounted) return;

    setState(() {
      blog = blogDetail;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (blog == null) {
      return const Scaffold(body: Center(child: Text('Blog not found')));
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ---------------- PUBLISHED DATE ----------------
              Text(
                'Published on ${Date.formatDate(blog!.createdAt)}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 16),

              // ---------------- TITLE ----------------
              Text(
                blog!.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.2,
                ),
              ),

              // ---------------- SUBTITLE ----------------
              if (blog!.subtitle != null) ...[
                const SizedBox(height: 12),
                Text(
                  blog!.subtitle!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // ---------------- AUTHOR CHIP ----------------
              if (blog!.owner != null)
                Container(
                  padding: const EdgeInsets.fromLTRB(15, 3, 15, 5),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Theme.of(context).primaryColor),
                  ),
                  child: Text(
                    blog!.owner!.username!,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),

              const SizedBox(height: 28),

              // ---------------- IMAGE ----------------
              if (blog!.imageUrl != null && blog!.imageUrl!.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(blog!.imageUrl!, fit: BoxFit.cover),
                  ),
                ),

              const SizedBox(height: 32),

              // ---------------- CONTENT ----------------
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  blog!.description,
                  style: const TextStyle(fontSize: 16, height: 1.7),
                ),
              ),

              CommentContainer(blogId: blog!.id),
            ],
          ),
        ),
      ),
    );
  }
}
