import 'package:flutter_app/features/admin/screens/admin_shell.dart';
import 'package:flutter_app/features/admin/screens/dashboard_screen.dart';
import 'package:flutter_app/features/admin/screens/forests/forest_form_screen.dart';
import 'package:flutter_app/features/admin/screens/forests/forest_list_screen.dart';
import 'package:flutter_app/features/admin/screens/forests/parcelle_draw_screen.dart';
import 'package:flutter_app/features/admin/screens/forests/parcelle_list_screen.dart';
import 'package:flutter_app/features/admin/screens/roles/role_list_screen.dart';
import 'package:flutter_app/features/admin/screens/services/service_list_screen.dart';
import 'package:flutter_app/features/admin/screens/users/user_list_screen.dart';
import 'package:flutter_app/features/agent/agent_home_screen.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/features/auth/screens/activation_screen.dart';
import 'package:flutter_app/features/auth/screens/login_screen.dart';
import 'package:flutter_app/features/auth/screens/splash_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      final isLoading = authState.status == AuthStatus.loading;
      final isAuthed = authState.status == AuthStatus.authenticated;
      final loc = state.matchedLocation;
      final onSplash = loc == '/splash';
      final onPublicPath = loc == '/login' || loc.startsWith('/activate');

      if (isLoading) return (onSplash || onPublicPath) ? null : '/splash';
      if (!isAuthed && !onPublicPath) return '/login';
      if (isAuthed && (onPublicPath || onSplash)) {
        final user = authState.user!;
        if (user.isAgent) return '/agent/home';
        return '/admin/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
        path: '/activate',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ActivationScreen(token: token);
        },
      ),
      //Agent routes
      GoRoute(path: '/agent/home', builder: (_, __) => const AgentHomeScreen()),
      //Admin routes wrapped in AdminShell
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, __) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/admin/forests',
            builder: (_, __) => const ForestListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, __) => const ForestFormScreen(),
              ),
              GoRoute(
                path: ':forestId/edit',
                builder: (_, state) => ForestFormScreen(
                  forestId: int.parse(state.pathParameters['forestId']!),
                ),
              ),
              GoRoute(
                path: ':forestId/parcelles',
                builder: (_, state) => ParcelleListScreen(
                  forestId: int.parse(state.pathParameters['forestId']!),
                ),
                routes: [
                  GoRoute(
                    path: 'draw',
                    builder: (_, state) => ParcelleDrawScreen(
                      forestId: int.parse(state.pathParameters['forestId']!),
                    ),
                  ),
                  GoRoute(
                    path: ':parcelleId/edit',
                    builder: (_, state) => ParcelleDrawScreen(
                      forestId: int.parse(state.pathParameters['forestId']!),
                      parcelleId: int.parse(state.pathParameters['parcelleId']!),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, __) => const UserListScreen(),
          ),
          GoRoute(
            path: '/admin/roles',
            builder: (_, __) => const RoleListScreen(),
          ),
          GoRoute(
            path: '/admin/services',
            builder: (_, __) => const ServiceListScreen(),
          ),
        ],
      ),
    ],
  );
});
