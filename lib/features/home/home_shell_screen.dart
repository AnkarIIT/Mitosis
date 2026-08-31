import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/offline_banner.dart';

/// Modern home shell with styled bottom navigation
class HomeShellScreen extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShellScreen({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: _ModernBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}

class _ModernBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ModernBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: NavigationBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_filled),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks),
            label: 'PYQs',
          ),
          NavigationDestination(
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: 'AI Tutor',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Flashcards',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}