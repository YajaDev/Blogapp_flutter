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

  int? _currentPage;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    // Schedule after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBlog();
    });
  }

  Future<void> _loadBlog() async {
    final blogDetail = await context.read<BlogProvider>().fetchBlogWithOwner(
      widget.blogId,
    );

    if (!mounted) return;

    _pageController = PageController();
    _currentPage = 0;

    setState(() {
      blog = blogDetail;
      isLoading = false;
    });
  }

  // ---------------- UI ----------------

  Widget _buildImageCarousel(List<String> images) {
    if (images.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 350,
          child: PageView.builder(
            controller: _pageController,
            itemCount: images.length,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    images[index],
                    fit: BoxFit.cover,
                    width: double.infinity,
                  ),
                ),
              );
            },
          ),
        ),

        const SizedBox(height: 12),

        // -------- CLICKABLE PAGINATION DOTS --------
        if (images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              images.length,
              (index) => GestureDetector(
                onTap: () {
                  _pageController?.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == index ? 14 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == index
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade400,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
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
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(
            scrollbars: false, // Hide scrollbar
          ),
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

                  const SizedBox(height: 20),
                ],

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
                _buildImageCarousel(blog!.imagesUrl),
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
      ),
    );
  }
}
