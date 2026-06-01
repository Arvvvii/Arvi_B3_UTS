import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:arvi_b3_uts/features/auth/presentation/screens/splash_screen.dart';
import 'package:arvi_b3_uts/features/auth/presentation/screens/login_screen.dart';
import 'package:arvi_b3_uts/features/auth/presentation/screens/register_screen.dart';
import 'package:arvi_b3_uts/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:arvi_b3_uts/features/dashboard/presentation/screens/main_scaffold.dart';
import 'package:arvi_b3_uts/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:arvi_b3_uts/features/dashboard/presentation/screens/profile_screen.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/screens/ticket_list_screen.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/screens/create_ticket_screen.dart';
import 'package:arvi_b3_uts/features/ticket/presentation/screens/ticket_detail_screen.dart';
import 'package:arvi_b3_uts/features/notification/presentation/screens/notification_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot_password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      // Stateful shell for Bottom Navigation Bar
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScaffold(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard/pelapor',
                name: 'dashboard_pelapor',
                builder: (context, state) => const DashboardScreen(),
              ),
              GoRoute(
                path: '/dashboard/management',
                name: 'dashboard_management',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/tickets',
                name: 'tickets',
                builder: (context, state) => const TicketListScreen(),
                routes: [
                  GoRoute(
                    path: 'create',
                    name: 'create_ticket',
                    builder: (context, state) => const CreateTicketScreen(),
                  ),
                  GoRoute(
                    path: ':id',
                    name: 'ticket_detail',
                    builder: (context, state) {
                      final id = state.pathParameters['id']!;
                      return TicketDetailScreen(ticketId: id);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notifications',
                name: 'notifications',
                builder: (context, state) => const NotificationScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
