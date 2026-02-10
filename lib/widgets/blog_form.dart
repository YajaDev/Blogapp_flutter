import 'dart:io';

import 'package:blogapp_flutter/models/blog.dart';
import 'package:blogapp_flutter/providers/auth_provider.dart';
import 'package:blogapp_flutter/providers/blog_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BlogForm extends StatefulWidget {
  const BlogForm({super.key});

  @override
  State<BlogForm> createState() => _BlogFormState();
}

class _BlogFormState extends State<BlogForm> {
  final titleCtrl = TextEditingController();
  final subtitleCtrl = TextEditingController();
  final descCtrl = TextEditingController();

  File? image;
  bool isLoading = false;

  final supabase = Supabase.instance.client;

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

    setState(() {
      image = File(picked.path);
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
          content: Text('title & description fields are required'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isLoading = true);

    final isSuccess = await blogProvider.addBlog(
      UpdateBlog(
        userId: user!.id,
        title: title,
        subtitle: subtitle,
        description: description,
      ),
      file: image,
    );

    if (!mounted) return;

    if (isSuccess) Navigator.pop(context);

    setState(() => isLoading = false);
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          MediaQuery.of(context).viewInsets.bottom + 16,
        ),
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
                    image: image != null
                        ? DecorationImage(
                            image: FileImage(image!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: image == null
                      ? const Center(child: Icon(Icons.add_a_photo, size: 40))
                      : null,
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
                      child: const Text('Publish Blog'),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
