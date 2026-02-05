import 'package:blogapp_flutter/widgets/logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RootShell extends StatelessWidget {
  final Widget child;

  const RootShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Get the current location from GoRouter
    final String currentLocation = GoRouterState.of(context).uri.toString();
    // Index for BottomNavigationBar
    int getSelectedIndex() {
      if (currentLocation == '/') return 0;
      if (currentLocation.startsWith('/profile')) return 1;
      if (currentLocation.startsWith('/blogs')) return 2;
      return 0; // default
    }

    return Scaffold(
      // Top AppBar with your logo
      appBar: AppBar(centerTitle: true, title: const Logo()),

      // The main content
      body: child,

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: getSelectedIndex(),
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
