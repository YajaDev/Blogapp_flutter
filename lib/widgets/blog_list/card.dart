import 'package:blogapp_flutter/models/blog.dart';
import 'package:blogapp_flutter/providers/blog_provider.dart';
import 'package:blogapp_flutter/widgets/blog_form.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class BlogCard extends StatefulWidget {
  final Blog blog;
  final int index;
  final VoidCallback onRefresh;

  const BlogCard({
    required this.blog,
    required this.index,
    required this.onRefresh,
  });

  @override
  State<BlogCard> createState() => _BlogCardState();
}

// ✅ This is the State class where 'mounted' is available
class _BlogCardState extends State<BlogCard> {
  void _openBlogForm(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => BlogForm(blog: widget.blog),
    ).then((_) {
      if (mounted) {
        widget.onRefresh();
      }
    });
  }

  Future<void> _deleteBlog(BuildContext context) async {
    final confirm = await _confirmDelete(context);
    
    // ✅ Now 'mounted' is available
    if (!mounted) return;
    if (confirm != true) return;

    final provider = context.read<BlogProvider>();
    await provider.deleteBlog(widget.blog.id);
    
    if (!mounted) return;
    widget.onRefresh();
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Blog'),
        content: Text(
          'Are you sure you want to delete "${widget.blog.title}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () => context.go('/blog/${widget.blog.id}'),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Index number
              CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: Theme.of(context).colorScheme.onPrimaryContainer,
                child: Text(
                  widget.index.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Blog info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.blog.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(widget.blog.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.edit,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: () => _openBlogForm(context),
                    tooltip: 'Edit',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteBlog(context),
                    tooltip: 'Delete',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}