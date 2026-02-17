import 'dart:io';
import 'package:blogapp_flutter/models/comment.dart';
import 'package:blogapp_flutter/models/profile.dart';
import 'package:blogapp_flutter/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:blogapp_flutter/services/comment_service.dart';
import 'package:blogapp_flutter/helper/api/safe_call.dart';
import 'package:provider/provider.dart';

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

  List<XFile> selectedImage = [];
  List<Uint8List> imageBytes = []; // For web preview
  bool loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // ---------------- IMAGE PICK ----------------

  Future<void> _pickImage() async {
    final pickedFiles = await _picker.pickMultiImage();

    if (pickedFiles.isEmpty) return;

    // Read bytes for web preview
    List<Uint8List> bytes = [];
    for (final image in pickedFiles) {
      final byte = await image.readAsBytes();
      bytes.add(byte);
    }

    if (!mounted) return;

    setState(() {
      selectedImage = pickedFiles;
      imageBytes = bytes;
    });
  }

  // ---------------- ADD COMMENT ----------------

  Future<void> _addComment() async {
    final content = _controller.text.trim();
    if (content.isEmpty && selectedImage.isEmpty) return;

    if (!mounted) return;
    setState(() => loading = true);

    final result = await CommentService.addComment(
      blogId: widget.blogId,
      content: content,
      imageFiles: selectedImage,
    );

    if (!mounted) return;
    setState(() => loading = false);

    switch (result) {
      case SafeSuccess(data: final newComment):
        _controller.clear();
        setState(() {
          selectedImage = [];
          imageBytes = [];
        });
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

  Widget _buildImagePreview() {
    if (selectedImage.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 120,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: selectedImage.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Container(
                  margin: const EdgeInsets.only(right: 8),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.memory(
                            imageBytes[index],
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          )
                        : Image.file(
                            File(selectedImage[index].path),
                            height: 120,
                            width: 120,
                            fit: BoxFit.cover,
                          ),
                  ),
                ),
                Positioned(
                  top: 4,
                  right: 12,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedImage.removeAt(index);
                        imageBytes.removeAt(index);
                      });
                    },
                    child: const CircleAvatar(
                      radius: 12,
                      backgroundColor: Colors.black54,
                      child: Icon(Icons.close, size: 14, color: Colors.white),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Profile? profile = context.read<AuthProvider>().profile;

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
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundImage: profile!.avatarUrl != null
                    ? NetworkImage(profile.avatarUrl!)
                    : null,
                child: profile.avatarUrl == null ? Icon(Icons.person) : null,
              ),
              const SizedBox(width: 10),
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

          // Image preview
          _buildImagePreview(),

          const SizedBox(height: 8),

          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.image_outlined),
                onPressed: loading ? null : _pickImage,
              ),
              const Spacer(),
              ElevatedButton.icon(
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
            ],
          ),
        ],
      ),
    );
  }
}
