import 'package:blogapp_flutter/screens/dashboard/blog_list.dart';
import 'package:blogapp_flutter/screens/dashboard/dashboard_shell.dart';
import 'package:blogapp_flutter/screens/dashboard/profile.dart';
import 'package:go_router/go_router.dart';

import 'screens/notfound.dart';
import 'screens/auth.dart';
import 'screens/home.dart';

final GoRouter appRouter = GoRouter(
  routes: [
    GoRoute(path: '/', builder: (context, state) => const Home()),
    GoRoute(path: '/auth', builder: (context, state) => const Auth()),
    ShellRoute(
      builder: (context, state, child) => Dashboard(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          redirect: (context, state) => '/dashboard/bloglist',
        ),
        GoRoute(
          path: '/dashboard/bloglist',
          builder: (context, state) => const BlogList(),
        ),
        GoRoute(
          path: '/dashboard/profile',
          builder: (context, state) => const Profile(),
        ),
      ],
    ),
    GoRoute(path: '/:path(.*)', builder: (context, state) => const Notfound()),
  ],
);
