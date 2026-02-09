import 'package:go_router/go_router.dart';
import '../shell/app_shell.dart';
import '../screens/home_screen.dart';
import '../screens/my_reports_screen.dart';
import '../screens/help_screen.dart';
import '../screens/report/report_flow_screen.dart';
import 'route_observer.dart';

final router = GoRouter(
  initialLocation: '/home',
  observers: [routeObserver],
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
        GoRoute(path: '/report', builder: (_, __) => const ReportFlowScreen()),
        GoRoute(path: '/my-reports', builder: (_, __) => const MyReportsScreen()),
        GoRoute(path: '/help', builder: (_, __) => const HelpScreen()),
      ],
    ),
  ],
);
