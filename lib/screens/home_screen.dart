import 'package:blogapp_flutter/helper/date.dart';
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
    final isWide = MediaQuery.of(context).size.width > 650;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: isWide ? _buildGrid(blogProvider) : _buildList(blogProvider),
        ),
      ),
    );
  }

  // ---------------- MOBILE LIST ----------------

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

  // ---------------- GRID ----------------

  Widget _buildGrid(BlogProvider provider) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(24),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: MediaQuery.of(context).size.width > 1100 ? 3 : 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.8,
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
    final isWide = MediaQuery.of(context).size.width > 650;

    return GestureDetector(
      onTap: () => context.go('/blog/${blog.id}'),
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------------- AUTHOR ----------------
            Padding(
              padding: EdgeInsetsGeometry.fromLTRB(10, 10, 0, 0),
              child: Row(
                children: [
                  blog.owner!.avatarUrl != null
                      ? CircleAvatar(
                          radius: 16,
                          backgroundImage: NetworkImage(blog.owner!.avatarUrl!),
                        )
                      : const CircleAvatar(
                          radius: 16,
                          child: Icon(Icons.person, size: 18),
                        ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          blog.owner!.username ?? "Unknown User",
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: blog.owner != null ? 12 : 0),

            // ---------------- BLOG IMAGE ----------------
            if (blog.imagesUrl.isNotEmpty)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      blog.imagesUrl.first,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(Icons.broken_image, size: 40),
                          ),
                    ),
                  ),

                  // Multi-image badge
                  if (blog.imagesUrl.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          "+${blog.imagesUrl.length - 1}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------------- TITLE ----------------
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

            if (isWide) Spacer(),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                SizedBox(),
                Padding(
                  padding: EdgeInsetsGeometry.all(15),
                  child: Text(
                    Date.formatDate(blog.createdAt),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
