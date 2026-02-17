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
  bool _loading = false;

  late TextEditingController _controller;

  // MULTI IMAGE STATE
  List<String> previewUrls = [];
  List<String> imagesToDelete = [];
  List<XFile> newImages = [];
  List<Uint8List> newImageBytes = [];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.comment.content);
    previewUrls = widget.comment.imagesUrl ?? [];
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------- PICK MULTIPLE IMAGES ----------------

  Future<void> _pickImages() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) return;

    List<Uint8List> bytes = [];
    for (final img in picked) {
      bytes.add(await img.readAsBytes());
    }

    if (!mounted) return;

    setState(() {
      newImages.addAll(picked);
      newImageBytes.addAll(bytes);
    });
  }

  // ---------------- SAVE EDIT ----------------

  Future<void> _saveEdit() async {
    final newContent = _controller.text.trim();

    setState(() => _loading = true);

    final result = await CommentService.editComment(
      commentId: widget.comment.id,
      content: newContent,
      existingImageUrls: previewUrls,
      imagesToDelete: imagesToDelete,
      newImageFiles: newImages,
    );

    if (!mounted) return;

    switch (result) {
      case SafeSuccess(data: final updated):
        setState(() {
          editing = false;
          _loading = false;
          newImages.clear();
          newImageBytes.clear();
          imagesToDelete.clear();
          previewUrls = updated.imagesUrl ?? [];
        });

        widget.updatedComment(updated);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Comment updated"),
            backgroundColor: Colors.green,
          ),
        );
        break;

      case SafeFailure(errorMessage: final err):
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
        break;
    }
  }

  // ---------------- DELETE COMMENT ----------------

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

    setState(() => _loading = true);

    final result = await CommentService.deleteComment(
      commentId: widget.comment.id,
      imagesUrl: widget.comment.imagesUrl ?? [],
    );

    if (!mounted) return;

    setState(() => _loading = false);

    switch (result) {
      case SafeSuccess():
        widget.deleteComment(widget.comment.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Comment deleted"),
            backgroundColor: Colors.green,
          ),
        );
        break;

      case SafeFailure(errorMessage: final err):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red),
        );
        break;
    }
  }

  // ---------------- IMAGE GRID ----------------

  Widget _buildImageGrid() {
    if (previewUrls.isEmpty && newImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          // Existing images
          ...previewUrls.map((url) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    url,
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                  ),
                ),
                if (editing)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          imagesToDelete.add(url);
                          previewUrls.remove(url);
                        });
                      },
                      child: CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.black54,
                        child: Icon(
                          Icons.close,
                          size: 12,
                          color: Theme.of(context).colorScheme.onSecondary,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          }),

          // New images
          ...List.generate(newImages.length, (index) {
            return Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: kIsWeb
                      ? Image.memory(
                          newImageBytes[index],
                          height: 90,
                          width: 90,
                          fit: BoxFit.cover,
                        )
                      : Image.file(
                          File(newImages[index].path),
                          height: 90,
                          width: 90,
                          fit: BoxFit.cover,
                        ),
                ),
                Positioned(
                  top: 2,
                  right: 2,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        newImages.removeAt(index);
                        newImageBytes.removeAt(index);
                      });
                    },
                    child: CircleAvatar(
                      radius: 10,
                      backgroundColor: Colors.black54,
                      child: Icon(
                        Icons.close,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final currentUser = Supabase.instance.client.auth.currentUser;
    final comment = widget.comment;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              comment.avatarUrl != null
                  ? CircleAvatar(
                      backgroundImage: NetworkImage(comment.avatarUrl!),
                    )
                  : const CircleAvatar(child: Icon(Icons.person)),

              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              comment.username ?? "Unknown User",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            editing
                                ? TextField(
                                    controller: _controller,
                                    maxLines: null,
                                    decoration: const InputDecoration(
                                      border: OutlineInputBorder(),
                                      hintText: "Edit comment...",
                                    ),
                                  )
                                : Text(comment.content),

                            _buildImageGrid(),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 4),

                    Row(
                      children: [
                        if (currentUser?.id == comment.userId)
                          editing
                              ? Row(
                                  children: [
                                    IconButton(
                                      onPressed: _loading ? null : _pickImages,
                                      icon: const Icon(Icons.image_outlined),
                                    ),
                                    TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () {
                                              setState(() {
                                                editing = false;
                                                previewUrls =
                                                    widget.comment.imagesUrl!;
                                                newImages.clear();
                                                newImageBytes.clear();
                                                imagesToDelete.clear();
                                                _controller.text =
                                                    comment.content;
                                              });
                                            },
                                      child: const Text("Cancel"),
                                    ),
                                    TextButton(
                                      onPressed: _loading ? null : _saveEdit,
                                      child: const Text("Save"),
                                    ),
                                  ],
                                )
                              : Row(
                                  children: [
                                    TextButton(
                                      onPressed: _loading
                                          ? null
                                          : () =>
                                                setState(() => editing = true),
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
                                      onPressed: _loading
                                          ? null
                                          : _deleteComment,
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
              ),
            ],
          ),
        ],
      ),
    );
  }
}
