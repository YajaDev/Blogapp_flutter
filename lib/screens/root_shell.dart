import 'package:blogapp_flutter/widgets/blog_form.dart';
import 'package:blogapp_flutter/widgets/logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootShell extends StatelessWidget {
  final Widget child;

  const RootShell({super.key, required this.child});

  // Index for BottomNavigationBar
  int getSelectedIndex(BuildContext context) {
    final String currentLocation = GoRouterState.of(context).uri.toString();

    if (currentLocation == '/') return 0;
    if (currentLocation.startsWith('/profile')) return 1;
    if (currentLocation.startsWith('/blogs')) return 2;
    return 0; // default
  }

  void openCreateBlog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BlogForm(),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current location from GoRouter

    return Scaffold(
      // Top AppBar with your logo
      appBar: AppBar(
        centerTitle: true,
        title: const Logo(),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),

      // The main content
      body: child,

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          openCreateBlog(context);
        },
        child: const Icon(Icons.add),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: getSelectedIndex(context),
        onTap: (index) {
          // Navigate to the right page when tapped
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/profile');
              break;
            case 2:
              context.go('/blogs');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'Blogs'),
        ],
      ),
    );
  }
}
