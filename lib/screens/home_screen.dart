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
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();

    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final provider = context.read<BlogProvider>();

    // Trigger prefetch 200px before bottom
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !provider.isLoading &&
        provider.hasMore) {
      provider.fetchMoreBlogs();
    }
  }

  Future<void> _onRefresh() async {
    await context.read<BlogProvider>().fetchInitialBlogs();
  }

  @override
  Widget build(BuildContext context) {
    final blogProvider = context.watch<BlogProvider>();

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ListView.builder(
          controller: _scrollController,
          padding: const EdgeInsets.all(16),
          itemCount: blogProvider.blogs.length + 1,
          itemBuilder: (context, index) {
            // Bottom loader
            if (index == blogProvider.blogs.length) {
              if (blogProvider.hasMore) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return const SizedBox.shrink();
            }

            final blog = blogProvider.blogs[index];
            return _BlogCard(blog: blog);
          },
        ),
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
