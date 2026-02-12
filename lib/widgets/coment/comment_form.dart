import 'dart:io';
import 'package:blogapp_flutter/models/comment.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blogapp_flutter/services/comment_service.dart';
import 'package:blogapp_flutter/helper/api/safe_call.dart';

class CommentForm extends StatefulWidget {
  final String blogId;
  final void Function(Comment) addComment;

  const CommentForm({
    super.key,
    required this.blogId,
    required this.addComment,
  });

  @override
  State<CommentForm> createState() => _CommentFormState();
}

class _CommentFormState extends State<CommentForm> {
  final TextEditingController _controller = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  File? selectedImage;
  bool loading = false;

  // ---------------- IMAGE PICK ----------------

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() => selectedImage = File(pickedFile.path));
    }
  }

  void _removeImage() {
    setState(() => selectedImage = null);
  }

  // ---------------- ADD COMMENT ----------------

  Future<void> _addComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty && selectedImage == null) return;

    setState(() => loading = true);

    final result = await CommentService.addComment(
      blogId: widget.blogId,
      content: content,
      imageFile: selectedImage,
    );

    if (!mounted) return;

    setState(() => loading = false);

    switch (result) {
      case SafeSuccess(data: final newComment):
        _controller.clear();
        selectedImage = null;
        widget.addComment(newComment);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comment added'),
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

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---------------- TOP ROW ----------------
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Avatar
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade300,
                child: const Icon(Icons.person, size: 20),
              ),

              const SizedBox(width: 10),

              // Text Input
              Expanded(
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  decoration: const InputDecoration(
                    hintText: "Write a comment...",
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),

          // ---------------- IMAGE PREVIEW ----------------
          if (selectedImage != null) ...[
            const SizedBox(height: 12),
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    selectedImage!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: GestureDetector(
                    onTap: _removeImage,
                    child: const CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 16, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 12),

          // ---------------- ACTION ROW ----------------
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: loading ? null : _pickImage,
              ),

              const Spacer(),

              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: loading ? null : _addComment,
                  icon: loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send, size: 18),
                  label: const Text("Post"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
