import 'package:blogapp_flutter/providers/auth_provider.dart';
import 'package:blogapp_flutter/widgets/blog_form.dart';
import 'package:blogapp_flutter/widgets/logo.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

class RootShell extends StatelessWidget {
  final Widget child;

  const RootShell({super.key, required this.child});

  int _selectedIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location == '/') return 0;
    if (location.startsWith('/profile')) return 1;
    if (location.startsWith('/blogs')) return 2;
    return 0;
  }

  void _openCreateBlog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const BlogForm(),
    );
  }

  void _onNavTap(BuildContext context, int index) {
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
  }

  bool _showFab(String location) {
    return !(location == '/blogs' || location.startsWith('/blog/'));
  }

  Widget? _avatar(BuildContext context, bool iswide) {
    final profile = context.watch<AuthProvider>().profile;

    if (profile == null) return null;

    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: GestureDetector(
        onTap: () => context.go('/profile'),
        child: profile.avatarUrl != null
            ? CircleAvatar(
                radius: iswide ? 17 : 13,
                backgroundImage: NetworkImage(profile.avatarUrl!),
              )
            : CircleAvatar(
                radius: iswide ? 17 : 13,
                child: Icon(Icons.person, size: iswide ? null : 16),
              ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final isWide = MediaQuery.of(context).size.width > 800; // Breakpoint
    final selectedIndex = _selectedIndex(context);

    // Wide layout - side navigation rail (tablet/web)
    if (isWide) {
      return Scaffold(
        appBar: AppBar(
          title: const Logo(),
          actions: [?_avatar(context, isWide)],
          centerTitle: true,
          shape: Border(
            bottom: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 0.2,
            ),
          ),
          toolbarHeight: 70,
          backgroundColor: Theme.of(context).colorScheme.surface,
          surfaceTintColor: Colors.transparent,
        ),

        body: Row(
          children: [
            // Navigation Rail for wide screens
            Padding(
              padding: const EdgeInsets.only(top: 30),
              child: NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: (index) => _onNavTap(context, index),
                labelType: NavigationRailLabelType.all,
                trailingAtBottom: true,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(
                      Icons.home,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.person_outline),
                    selectedIcon: Icon(
                      Icons.person,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text('Profile'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.list_alt_outlined),
                    selectedIcon: Icon(
                      Icons.list_alt,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    label: Text('Blogs'),
                  ),
                ],

                // Create blog button in rail
                trailing: Container(
                  margin: EdgeInsets.only(bottom: 30),
                  child: FloatingActionButton(
                    onPressed: () => _openCreateBlog(context),
                    child: const Icon(Icons.add),
                  ),
                ),
              ),
            ),

            const VerticalDivider(thickness: 1, width: 1),

            // Main content with max width constraint
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Narrow layout - bottom navigation bar (mobile)
    return Scaffold(
      appBar: AppBar(
        title: const Logo(),
        actions: [?_avatar(context, isWide)],
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
      ),

      body: child,

      floatingActionButton: _showFab(location)
          ? FloatingActionButton(
              onPressed: () => _openCreateBlog(context),
              child: const Icon(Icons.add),
            )
          : null,

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => _onNavTap(context, index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list_alt_outlined),
            activeIcon: Icon(Icons.list_alt),
            label: 'Blogs',
          ),
        ],
      ),
    );
  }
}
