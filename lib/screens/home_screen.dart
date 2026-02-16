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
    final isWide = MediaQuery.of(context).size.width > 650; // Breakpoint

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false, // Hide scrollbar
          ),
          child: isWide ? _buildGrid(blogProvider) : _buildList(blogProvider),
        ),
      ),
    );
  }

  // Mobile - single column list
  Widget _buildList(BlogProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: provider.blogs.length + 1,
      itemBuilder: (context, index) {
        if (index == provider.blogs.length) {
          return _buildLoader(provider);
        }
        return _BlogCard(blog: provider.blogs[index]);
      },
    );
  }

  // Web/Tablet - 2 column grid
  Widget _buildGrid(BlogProvider provider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: provider.blogs.length + 1,
      itemBuilder: (context, index) {
        if (index == provider.blogs.length) {
          return _buildLoader(provider);
        }
        return _BlogCard(blog: provider.blogs[index]);
      },
    );
  }

  Widget _buildLoader(BlogProvider provider) {
    if (provider.hasMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return const SizedBox.shrink();
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
            // ---------------- IMAGE ----------------
            if (blog.imageUrl != null && blog.imageUrl!.isNotEmpty)
              AspectRatio(
                aspectRatio: 16 / 9, // Consistent ratio on grid and list
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
                  Text(
                    blog.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (blog.subtitle != null && blog.subtitle!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      blog.subtitle!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
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
