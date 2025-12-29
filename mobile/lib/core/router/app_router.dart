import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/login_screen.dart';
import '../../features/citizen/citizen_home_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    routes: [
      // Auth
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),

      // Citizen routes
      GoRoute(
        path: '/citizen/home',
        name: 'citizen-home',
        builder: (context, state) => const CitizenHomeScreen(),
      ),

      // Admin routes (to be implemented)
      GoRoute(
        path: '/admin/dashboard',
        name: 'admin-dashboard',
        builder: (context, state) => const Placeholder(), // TODO: Implement
      ),

      // Collector routes (to be implemented)
      GoRoute(
        path: '/collector/tasks',
        name: 'collector-tasks',
        builder: (context, state) => const Placeholder(), // TODO: Implement
      ),
    ],
  );
});
