import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/modern_sidebar.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/providers/ui_providers.dart';

/// Modern home shell with styled bottom navigation and sidebar
class HomeShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShellScreen({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarVisible = ref.watch(sidebarVisibilityProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              const OfflineBanner(),
              Expanded(child: navigationShell),
            ],
          ),
          // Sidebar - only visible on desktop
          if (isDesktop)
            Positioned(
              top: 0,
              right: 0,
              child: Visible(
                visible: sidebarVisible,
                maintainState: true,
                child: ModernSidebar(
                  isVisible: sidebarVisible,
                  onToggle: () => ref.read(sidebarVisibilityProvider.notifier).state = false,
                ),
              ),
            ),
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

class Visible extends StatelessWidget {
  final bool visible;
  final Widget child;
  final bool maintainState;

  const Visible({
    Key? key,
    required this.visible,
    required this.child,
    this.maintainState = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return child;
  }
}

class _ModernBottomNavigation extends ConsumerWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _ModernBottomNavigation({
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            icon: Icon(Icons.science_outlined),
            selectedIcon: Icon(Icons.science),
            label: 'Tests',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmarks_outlined),
            selectedIcon: Icon(Icons.bookmarks),
            label: 'PYQ',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Flashcards',
          ),
NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}