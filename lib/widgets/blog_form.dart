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

  XFile? imageFile; // Use XFile instead of File
  Uint8List? imageBytes; // For web preview
  bool removeImage = false;
  bool isLoading = false;

  bool get isEditMode => widget.blog != null;

  @override
  void initState() {
    super.initState();
    titleCtrl = TextEditingController(text: widget.blog?.title ?? '');
    subtitleCtrl = TextEditingController(text: widget.blog?.subtitle ?? '');
    descCtrl = TextEditingController(text: widget.blog?.description ?? '');
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    subtitleCtrl.dispose();
    descCtrl.dispose();
    super.dispose();
  }

  // ---------------- IMAGE PICK ----------------

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);

    if (picked == null) return;

    final byte = await picked.readAsBytes();

    if (!mounted) return;

    setState(() {
      imageFile = picked;
      imageBytes = byte;
      removeImage = false;
    });
  }

  void removeCurrentImage() {
    setState(() {
      imageFile = null;
      imageBytes = null;
      removeImage = true;
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

    setState(() => isLoading = true);

    final blogDetail = UpdateBlog(
      id: widget.blog?.id,
      userId: user?.id,
      title: title,
      subtitle: subtitle,
      description: description,
      imageUrl: widget.blog?.imageUrl,
    );

    Blog? blog;
    if (isEditMode) {
      blog = await blogProvider.editBlog(
        blogDetail,
        deleteImage: removeImage,
        file: imageFile,
      );
    } else {
      blog = await blogProvider.addBlog(blogDetail, file: imageFile);
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

    setState(() => isLoading = false);

    if (blog != null) Navigator.pop(context);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final currentImage = widget.blog?.imageUrl;

    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // IMAGE PICKER
              GestureDetector(
                onTap: pickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    image: imageFile != null
                        ? DecorationImage(
                            image: kIsWeb
                                ? MemoryImage(imageBytes!) // in web
                                : FileImage(File(imageFile!.path)) // in mob
                                      as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : (currentImage != null && !removeImage)
                        ? DecorationImage(
                            image: NetworkImage(currentImage),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child:
                      imageFile == null && (currentImage == null || removeImage)
                      ? const Center(child: Icon(Icons.add_a_photo, size: 40))
                      : Stack(
                          alignment: Alignment.topRight,
                          children: [
                            Positioned(
                              child: IconButton(
                                icon: const Icon(
                                  Icons.close,
                                  color: Colors.red,
                                ),
                                onPressed: removeCurrentImage,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

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

              isLoading
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
