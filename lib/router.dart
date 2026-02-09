import 'package:blogapp_flutter/providers/auth_provider.dart';
import 'package:blogapp_flutter/screens/blog_list.dart';
import 'package:blogapp_flutter/screens/profile_screen.dart';
import 'package:blogapp_flutter/screens/root_shell.dart';
import 'package:go_router/go_router.dart';

import 'screens/notfound.dart';
import 'screens/auth_screen.dart';
import 'screens/home.dart';

GoRouter appRouter(AuthProvider authProvider) {
  return GoRouter(
    refreshListenable: authProvider,
    redirect: (context, state) {
      final user = authProvider.user;
      final loggingIn = state.matchedLocation == '/auth';

      if (user == null && !loggingIn) {
        // If not signed in, redirect to /auth
        return '/auth';
      }
      if (user != null && loggingIn) {
        // If signed in and tries to go to /auth, redirect to home
        return '/';
      }
      // No redirect needed
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => RootShell(child: child),
        routes: [
          GoRoute(path: '/', builder: (context, state) => const Home()),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/blogs',
            builder: (context, state) => const BlogList(),
          ),
        ],
      ),

      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),

      GoRoute(
        path: '/:path(.*)',
        builder: (context, state) => const Notfound(),
      ),
    ],
  );
}
