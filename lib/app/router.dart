import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../shell/app_shell.dart';
import '../screens/home_screen.dart';
import '../screens/my_reports_screen.dart';
import '../screens/community_reports_screen.dart';
import '../screens/help_screen.dart';
import '../screens/auth/auth_screen.dart';
import '../screens/report/report_flow_screen.dart';
import 'route_observer.dart';
import 'auth_state_notifier.dart';

final router = GoRouter(
  refreshListenable: authStateNotifier,
  initialLocation: '/home',
  observers: [routeObserver],
  redirect: (context, state) {
    final isSignedIn = Supabase.instance.client.auth.currentSession != null;
    final isAuthRoute = state.matchedLocation == '/auth';

    if (!isSignedIn) {
      return isAuthRoute ? null : '/auth';
    }

    if (isAuthRoute) return '/home';
    return null;
  },
  routes: [
    GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/report', builder: (_, __) => const ReportFlowScreen()),
        GoRoute(
          path: '/my-reports',
          builder: (_, __) => const MyReportsScreen(),
        ),
        GoRoute(
          path: '/community-reports',
          builder: (_, __) => const CommunityReportsScreen(),
        ),
        GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
      ],
    ),
  ],
);
