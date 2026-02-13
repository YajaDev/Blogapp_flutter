import 'dart:io';
import 'package:blogapp_flutter/helper/date.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:blogapp_flutter/models/comment.dart';
import 'package:blogapp_flutter/services/comment_service.dart';
import 'package:blogapp_flutter/helper/api/safe_call.dart';

class CommentItem extends StatefulWidget {
  final Comment comment;
  final void Function(Comment) updatedComment;
  final void Function(String) deleteComment;

  const CommentItem({
    super.key,
    required this.comment,
    required this.updatedComment,
    required this.deleteComment,
  });

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool editing = false;
  bool loading = false;

  late TextEditingController _controller;

  XFile? newImage;
  Uint8List? newImageBytes; // For web preview
  String? previewUrl;
  bool removeImage = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.comment.content);
    previewUrl = widget.comment.imageUrl;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------- PICK IMAGE ----------------

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    // Read bytes for web preview
    final bytes = await picked.readAsBytes();

    if (!mounted) return;

    setState(() {
      newImage = picked;
      newImageBytes = bytes;
      previewUrl = picked.path;
      removeImage = false;
    });
  }

  void _clearImage() {
    setState(() {
      newImage = null;
      newImageBytes = null;
      previewUrl = null;
      removeImage = true;
    });
  }

  // ✅ Build image that works on both web and mobile
  Widget _buildImage(String url) {
    // Network image (existing)
    if (url.startsWith('http')) {
      return Image.network(url, height: 100, width: 200, fit: BoxFit.cover);
    }

    // Local image preview
    if (kIsWeb && newImageBytes != null) {
      return Image.memory(
        newImageBytes!,
        height: 100,
        width: 200,
        fit: BoxFit.cover,
      );
    }

    // Mobile file
    if (!kIsWeb) {
      return Image.file(File(url), height: 100, width: 200, fit: BoxFit.cover);
    }

    return const SizedBox.shrink();
  }

  // ---------------- SAVE EDIT ----------------

  Future<void> _saveEdit() async {
    final newContent = _controller.text.trim();

    if (!mounted) return;
    setState(() => loading = true);

    final result = await CommentService.editComment(
      commentId: widget.comment.id,
      content: newContent,
      existingImageUrl: widget.comment.imageUrl,
      newImageFile: newImage,
      removeImage: removeImage,
    );

    if (!mounted) return;

    switch (result) {
      case SafeSuccess(data: final updatedComment):
        setState(() {
          editing = false;
          newImage = null;
          newImageBytes = null;
          previewUrl = updatedComment.imageUrl;
          loading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment updated'),
            backgroundColor: Colors.green,
          ),
        );
        widget.updatedComment(updatedComment);
        break;

      case SafeFailure(errorMessage: final err):
        setState(() => loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
        break;
    }
  }

  // ---------------- DELETE ----------------

  Future<void> _deleteComment() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Comment'),
        content: const Text('Are you sure you want to delete this comment?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (!mounted || confirm != true) return;

    setState(() => loading = true);

    final result = await CommentService.deleteComment(
      commentId: widget.comment.id,
      imageUrl: widget.comment.imageUrl,
    );

    if (!mounted) return;

    setState(() => loading = false);

    switch (result) {
      case SafeSuccess():
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment deleted'),
            backgroundColor: Colors.green,
          ),
        );
        widget.deleteComment(widget.comment.id);
        break;

      case SafeFailure(errorMessage: final err):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
        break;
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final comment = widget.comment;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          Row(
            spacing: 10,
            children: [
              comment.avatarUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(comment.avatarUrl!),
                    )
                  : const CircleAvatar(child: Icon(Icons.person)),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: ListTile(
                        title: Text(
                          comment.username ?? "Unknown User",
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: editing
                            ? TextField(
                                controller: _controller,
                                maxLength: null,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "Edit comment...",
                                ),
                              )
                            : Text(comment.content),
                      ),
                    ),

                    // Image preview
                    if (previewUrl != null)
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImage(previewUrl!),
                          ),
                          if (editing)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clearImage,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (currentUser?.id == comment.userId)
                editing
                    ? Row(
                        children: [
                          IconButton(
                            onPressed: loading ? null : _pickImage,
                            icon: const Icon(Icons.image_outlined),
                          ),
                          TextButton(
                            onPressed: loading
                                ? null
                                : () {
                                    setState(() {
                                      editing = false;
                                      newImage = null;
                                      newImageBytes = null;
                                      _controller.text = comment.content;
                                      previewUrl = comment.imageUrl;
                                      removeImage = false;
                                    });
                                  },
                            child: const Text(
                              "Cancel",
                              style: TextStyle(color: Colors.black),
                            ),
                          ),
                          TextButton(
                            onPressed: loading ? null : _saveEdit,
                            child: const Text("Save"),
                          ),
                        ],
                      )
                    : Row(
                        children: [
                          TextButton(
                            onPressed: loading
                                ? null
                                : () => setState(() => editing = true),
                            child: Text(
                              "Edit",
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: loading ? null : _deleteComment,
                            child: const Text(
                              "Delete",
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),

              const Spacer(),

              Text(
                Date.timeAgo(comment.createdAt),
                style: TextStyle(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
