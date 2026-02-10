import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/blog_provider.dart';
import '../models/blog.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final blogProvider = context.watch<BlogProvider>();

    return RefreshIndicator(
      onRefresh: () => blogProvider.fetchInitialBlogs(),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: blogProvider.blogs.length + 1,
        itemBuilder: (context, index) {
          if (index == blogProvider.blogs.length) {
            if (blogProvider.hasMore) {
              blogProvider.fetchMoreBlogs();
              return Center(
                child: Container(
                  margin: EdgeInsets.symmetric(vertical: 24),
                  padding: const EdgeInsets.fromLTRB(15, 3, 15, 5),
                  child: Text(
                    'Fecthing more blogs...',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                ),
              );
            }
            return const SizedBox.shrink();
          }

          final blog = blogProvider.blogs[index];
          return _BlogCard(blog: blog);
        },
      ),
    );
  }
}

class _BlogCard extends StatelessWidget {
  final Blog blog;

  const _BlogCard({required this.blog});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/blog/${blog.id}'),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- BLOG IMAGE ----------------
            if (blog.imageUrl != null && blog.imageUrl!.isNotEmpty)
              SizedBox(
                height: 180,
                width: double.infinity,
                child: Image.network(
                  blog.imageUrl!,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Center(
                      child: Icon(Icons.broken_image, size: 40),
                    );
                  },
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- TITLE ----------------
                  Text(
                    blog.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),

                  // ---------------- SUBTITLE ----------------
                  if (blog.subtitle != null && blog.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      blog.subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
