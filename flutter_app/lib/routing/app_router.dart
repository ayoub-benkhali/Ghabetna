import 'package:flutter_app/features/admin/screens/admin_profile_screen.dart';
import 'package:flutter_app/features/admin/screens/admin_shell.dart';
import 'package:flutter_app/features/admin/screens/dashboard_screen.dart';
import 'package:flutter_app/features/admin/screens/forests/forest_form_screen.dart';
import 'package:flutter_app/features/admin/screens/forests/forest_list_screen.dart';
import 'package:flutter_app/features/admin/screens/forests/parcelle_draw_screen.dart';
import 'package:flutter_app/features/admin/screens/forests/parcelle_list_screen.dart';
import 'package:flutter_app/features/admin/screens/roles/role_list_screen.dart';
import 'package:flutter_app/features/admin/screens/services/service_list_screen.dart';
import 'package:flutter_app/features/admin/screens/users/user_list_screen.dart';
import 'package:flutter_app/features/agent/screens/agent_home_screen.dart';
import 'package:flutter_app/features/agent/screens/agent_profile_screen.dart';
import 'package:flutter_app/features/auth/providers/auth_provider.dart';
import 'package:flutter_app/features/auth/screens/activation_screen.dart';
import 'package:flutter_app/features/auth/screens/login_screen.dart';
import 'package:flutter_app/features/auth/screens/splash_screen.dart';
import 'package:flutter_app/features/agent/screens/my_incidents_screen.dart';
import 'package:flutter_app/features/agent/screens/report_incident_screen.dart';
import 'package:flutter_app/features/supervisor/screens/incident_detail_screen.dart';
import 'package:flutter_app/features/supervisor/screens/supervisor_incident_screen.dart';
import 'package:flutter_app/features/supervisor/screens/supervisor_map_screen.dart';
import 'package:flutter_app/features/supervisor/screens/supervisor_profile_screen.dart';
import 'package:flutter_app/features/supervisor/screens/supervisor_shell.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_app/features/chat/screens/chat_screen.dart';

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
        if (user.isSupervisor) return '/supervisor/map';
        return '/admin/dashboard';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/splash', builder: (_, _) => const SplashScreen()),
      GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
      GoRoute(
        path: '/activate',
        builder: (context, state) {
          final token = state.uri.queryParameters['token'] ?? '';
          return ActivationScreen(token: token);
        },
      ),
      // Agent routes
      GoRoute(path: '/agent/home', builder: (_, _) => const AgentHomeScreen()),
      GoRoute(
        path: '/agent/report',
        builder: (_, _) => const ReportIncidentScreen(),
      ),
      GoRoute(
        path: '/agent/incidents',
        builder: (_, _) => const MyIncidentsScreen(),
      ),
      GoRoute(
        path: '/agent/profile',
        builder: (_, _) => const AgentProfileScreen(),
      ),
      GoRoute(
         path: '/agent/chat',
         builder: (_, _) => const ChatScreen(),
      ),
      // Admin routes wrapped in AdminShell
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (_, _) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/admin/forests',
            builder: (_, _) => const ForestListScreen(),
            routes: [
              GoRoute(
                path: 'new',
                builder: (_, _) => const ForestFormScreen(),
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
                      parcelleId: int.parse(
                        state.pathParameters['parcelleId']!,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          GoRoute(
            path: '/admin/users',
            builder: (_, _) => const UserListScreen(),
          ),
          GoRoute(
            path: '/admin/roles',
            builder: (_, _) => const RoleListScreen(),
          ),
          GoRoute(
            path: '/admin/services',
            builder: (_, _) => const ServiceListScreen(),
          ),
          GoRoute(
            path: '/admin/profile',
            builder: (_, _) => const AdminProfileScreen(),
          ),
          GoRoute(
           path: '/admin/chat',
          builder: (_, _) => const ChatScreen(),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => SupervisorShell(child: child),
        routes: [
          GoRoute(
            path: '/supervisor/incidents',
            builder: (_, _) => const SupervisorIncidentScreen(),
          ),
          GoRoute(
            path: '/supervisor/incidents/:id',
            builder: (_, state) => IncidentDetailScreen(
              incidentId: int.parse(state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/supervisor/map',
            builder: (_, _) => const SupervisorMapScreen(),
          ),
          GoRoute(
            path: '/supervisor/profile',
            builder: (_, _) => const SupervisorProfileScreen(),
          ),
          GoRoute(
            path: '/supervisor/chat',
            builder: (_, _) => const ChatScreen(),
          ),
          // we'll add /supervisor/agents and /supervisor/analytics later
        ],
      ),
    ],
  );
});
