import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'screens/home_screen.dart';
import 'screens/x_feed_screen.dart';
import 'screens/composer_screen.dart';
import 'screens/log_screen.dart';
import 'screens/settings_screen.dart';

class AppRouter {
  static final GlobalKey<NavigatorState> _rootNavigatorKey =
      GlobalKey<NavigatorState>();
  static final GlobalKey<NavigatorState> _shellNavigatorKey =
      GlobalKey<NavigatorState>();

  static final GoRouter router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: [
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            name: 'home',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: HomeScreen(),
            ),
          ),
          GoRoute(
            path: '/x-feed',
            name: 'x-feed',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: XFeedScreen(),
            ),
          ),
          GoRoute(
            path: '/compose',
            name: 'compose',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: ComposerScreen(),
            ),
          ),
          GoRoute(
            path: '/log',
            name: 'log',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: LogScreen(),
            ),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

class ScaffoldWithNavBar extends StatelessWidget {
  final Widget child;

  const ScaffoldWithNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();

    int selectedIndex = 0;
    if (location.startsWith('/x-feed')) {
      selectedIndex = 1;
    } else if (location.startsWith('/compose')) {
      selectedIndex = 2;
    } else if (location.startsWith('/log')) {
      selectedIndex = 3;
    } else if (location.startsWith('/settings')) {
      selectedIndex = 4;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          switch (index) {
            case 0:
              context.go('/');
              break;
            case 1:
              context.go('/x-feed');
              break;
            case 2:
              context.go('/compose');
              break;
            case 3:
              context.go('/log');
              break;
            case 4:
              context.go('/settings');
              break;
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.close),
            selectedIcon: Icon(Icons.close),
            label: 'X',
          ),
          NavigationDestination(
            icon: Icon(Icons.edit_outlined),
            selectedIcon: Icon(Icons.edit),
            label: 'Compose',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Log',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
