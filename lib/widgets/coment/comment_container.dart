import 'package:blogapp_flutter/helper/api/safe_call.dart';
import 'package:blogapp_flutter/widgets/coment/comment_form.dart';
import 'package:blogapp_flutter/widgets/coment/comment_item.dart';
import 'package:flutter/material.dart';
import 'package:blogapp_flutter/models/comment.dart';
import 'package:blogapp_flutter/services/comment_service.dart';

class CommentContainer extends StatefulWidget {
  final String blogId;
  const CommentContainer({super.key, required this.blogId});

  @override
  State<CommentContainer> createState() => _CommentContainerState();
}

class _CommentContainerState extends State<CommentContainer> {
  List<Comment> comments = [];
  bool loading = true;

  Future<void> _loadComments() async {
    setState(() => loading = true);

    final result = await CommentService.getBlogComments(widget.blogId);

    setState(() => loading = false);

    if (!mounted) return;
    switch (result) {
      case SafeSuccess(data: final data):
        setState(() => comments = data);
        break;
      case SafeFailure(errorMessage: final err):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
        break;
    }
  }

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  void _onAdd(Comment newComment) {
    setState(() {
      comments.add(newComment);
    });
  }

  void _onUpdate(Comment updatedComment) {
    setState(() {
      final newcoments = comments
          .map((c) => c.id == updatedComment.id ? updatedComment : c)
          .toList();
      comments = newcoments;
    });
  }

  void _onDelete(String id) {
    setState(() {
      comments.removeWhere((c) => c.id == id);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());

    return Column(
      children: [
        const SizedBox(height: 30),

        Text(
          "Comments (${comments.length})",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 8),

        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (_, index) => CommentItem(
            comment: comments[index],
            deleteComment: _onDelete,
            updatedComment: _onUpdate,
          ),
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemCount: comments.length,
        ),

        const SizedBox(height: 16),

        CommentForm(blogId: widget.blogId, addComment: _onAdd),
      ],
    );
  }
}
