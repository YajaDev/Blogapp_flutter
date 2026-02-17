import 'dart:io';
import 'package:blogapp_flutter/models/blog.dart';
import 'package:blogapp_flutter/models/notif_message.dart';
import 'package:blogapp_flutter/providers/auth_provider.dart';
import 'package:blogapp_flutter/providers/blog_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class BlogForm extends StatefulWidget {
  final Blog? blog;

  const BlogForm({super.key, this.blog});

  @override
  State<BlogForm> createState() => _BlogFormState();
}

class _BlogFormState extends State<BlogForm> {
  late final TextEditingController titleCtrl;
  late final TextEditingController subtitleCtrl;
  late final TextEditingController descCtrl;

  List<XFile> _newImages = []; // List of new images
  List<String> _existingImages = []; // List of old images
  List<String> _imagesToDelete = []; // Track deletions
  bool _isLoading = false;

  bool get isEditMode => widget.blog != null;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.blog?.title ?? '');
    subtitleCtrl = TextEditingController(text: widget.blog?.subtitle ?? '');
    descCtrl = TextEditingController(text: widget.blog?.description ?? '');

    // Load existing images
    if (widget.blog != null) _existingImages = widget.blog!.imagesUrl;
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  // ---------------- IMAGE PICK ----------------

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();

    if (picked.isEmpty) return;

    if (!mounted) return;
    setState(() => _newImages.addAll(picked));
  }

  // ---------------- REMOVE IMAGE ----------------

  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  void _removeExistingImage(int index) {
    final url = _existingImages[index];
    setState(() {
      _imagesToDelete.add(url);
      _existingImages.removeAt(index);
    });
  }

  // ---------------- SUBMIT ----------------

  Future<void> submit() async {
    final title = titleCtrl.text.trim();
    final subtitle = subtitleCtrl.text.trim();
    final description = descCtrl.text.trim();

    final blogProvider = context.read<BlogProvider>();
    final user = context.read<AuthProvider>().profile;

    if (title.isEmpty || description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Title & description fields are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final blogDetail = UpdateBlog(
      id: widget.blog?.id,
      userId: user?.id,
      title: title,
      subtitle: subtitle,
      description: description,
      imagesUrl: widget.blog?.imagesUrl,
    );

    Blog? blog;
    if (isEditMode) {
      blog = await blogProvider.editBlog(
        blogDetail,
        imagesToDelete: _imagesToDelete,
        files: _newImages,
      );
    } else {
      blog = await blogProvider.addBlog(blogDetail, files: _newImages);
    }

    if (!mounted) return;

    final message = blogProvider.message;
    if (message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message.text),
          backgroundColor: message.type == MessageType.success
              ? Colors.green
              : Colors.red,
        ),
      );
    }

    setState(() => _isLoading = false);

    if (blog != null) Navigator.pop(context);
  }

  // ---------------- UI ----------------

  Widget _buildImageGrid() {
    final totalImages = _existingImages.length + _newImages.length;

    if (totalImages == 0) {
      return GestureDetector(
        onTap: _pickImages,
        child: Container(
          height: 160,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate,
                size: 40,
                color: Colors.grey.shade500,
              ),
              const SizedBox(height: 8),
              Text('Add images', style: TextStyle(color: Colors.grey.shade500)),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: totalImages,
          itemBuilder: (context, index) {
            // Existing images
            if (index < _existingImages.length) {
              final url = _existingImages[index];
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(url, fit: BoxFit.cover),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: GestureDetector(
                      onTap: () => _removeExistingImage(index),
                      child: const CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.black54,
                        child: Icon(Icons.close, size: 14, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              );
            }

            // New images
            final newIndex = index - _existingImages.length;
            final file = _newImages[newIndex];

            return FutureBuilder<Uint8List>(
              future: file.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    color: Colors.grey.shade200,
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                return Stack(
                  fit: StackFit.expand,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: kIsWeb
                          ? Image.memory(snapshot.data!, fit: BoxFit.cover)
                          : Image.file(File(file.path), fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeNewImage(newIndex),
                        child: const CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _pickImages,
          icon: const Icon(Icons.add_photo_alternate),
          label: const Text('Add more images'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: kIsWeb ? AppBar() : null,
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IMAGE PICKER
              _buildImageGrid(),

              const SizedBox(height: 16),

              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: subtitleCtrl,
                decoration: const InputDecoration(labelText: 'Subtitle'),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: descCtrl,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
              ),

              const SizedBox(height: 20),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      onPressed: submit,
                      child: Text(isEditMode ? 'Update Blog' : 'Publish Blog'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
