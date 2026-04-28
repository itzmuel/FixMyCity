import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app/theme.dart';
import '../app/refresh_bus.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _index(String loc) {
    if (loc.startsWith('/home')) return 0;
    if (loc.startsWith('/report')) return 1;
    if (loc.startsWith('/my-reports')) return 2;
    if (loc.startsWith('/community-reports')) return 3;
    return 4;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _index(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500),
        onTap: (i) {
          switch (i) {
            case 0:
              refreshBus
                  .pingHome(); //  auto-refresh Home when selecting Home tab
              context.go('/home');
              break;
            case 1:
              context.go('/report');
              break;
            case 2:
              refreshBus.pingMyReports();
              context.go('/my-reports');
              break;
            case 3:
              context.go('/community-reports');
              break;
            case 4:
              context.go('/help');
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(LucideIcons.home), label: 'Home'),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.plusCircle),
            label: 'Report',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.list),
            label: 'My Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.users),
            label: 'Community',
          ),
          BottomNavigationBarItem(
            icon: Icon(LucideIcons.helpCircle),
            label: 'Help',
          ),
        ],
      ),
    );
  }
}
