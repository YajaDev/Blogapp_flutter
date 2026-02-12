import 'dart:io';
import 'package:blogapp_flutter/helper/date.dart';
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

  File? newImage;
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

    setState(() {
      newImage = File(picked.path);
      previewUrl = picked.path;
      removeImage = widget.comment.imageUrl != null ? true : false;
    });
  }

  void _clearImaga() {
    setState(() {
      newImage = null;
      previewUrl = null;
      removeImage = true;
    });
  }

  // ---------------- SAVE EDIT ----------------

  Future<void> _saveEdit() async {
    final newContent = _controller.text.trim();

    setState(() {
      loading = true;
    });

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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment updated'),
            backgroundColor: Colors.green,
          ),
        );

        setState(() {
          editing = false;
          newImage = null;
          loading = false;
        });

        widget.updatedComment(updatedComment);
        break;

      case SafeFailure(errorMessage: final err):
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
              // --------------------- Avatar section ---------------------
              comment.avatarUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(widget.comment.avatarUrl!),
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

                        // ---------------- CONTENT ----------------
                        subtitle: editing
                            ? TextField(
                                controller: _controller,
                                maxLength: null,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  hintText: "Edit comment...",
                                ),
                              )
                            : Text(widget.comment.content),
                      ),
                    ),

                    // ---------------- IMAGE ----------------
                    if (previewUrl != null)
                      Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: previewUrl!.startsWith('http')
                                ? Image.network(
                                    previewUrl!,
                                    height: 100,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  )
                                : Image.file(
                                    File(previewUrl!),
                                    height: 100,
                                    width: 200,
                                    fit: BoxFit.cover,
                                  ),
                          ),

                          if (editing)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: _clearImaga,
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),

          // --------------------- Actions Buttons -----------------------
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (currentUser?.id == comment.userId)
                Container(
                  child: editing
                      // edit Mode
                      ? Row(
                          children: [
                            IconButton(
                              onPressed: _pickImage,
                              icon: const Icon(Icons.image_outlined),
                            ),
                            TextButton(
                              onPressed: loading
                                  ? null
                                  : () {
                                      setState(() {
                                        editing = false;
                                        newImage = null;
                                        _controller.text = comment.content;
                                        previewUrl = comment.imageUrl;
                                      });
                                    },
                              child: Text(
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
                      // Viewing move
                      : Row(
                          children: [
                            TextButton(
                              onPressed: loading
                                  ? null
                                  : () => setState(() => editing = true),
                              child: Text(
                                "Edit",
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.secondary,
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
