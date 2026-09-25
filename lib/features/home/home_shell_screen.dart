import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/modern_sidebar.dart';
import '../../core/widgets/offline_banner.dart';
import '../../core/providers/ui_providers.dart';

class HomeShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShellScreen({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sidebarVisible = ref.watch(sidebarVisibilityProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      body: Stack(
        children: [
          Column(
            children: [
              const OfflineBanner(),
              Expanded(child: navigationShell),
            ],
          ),
          if (isDesktop)
            Positioned(
              top: 0,
              right: 0,
              child: Visible(
                visible: sidebarVisible,
                maintainState: true,
                child: ModernSidebar(
                  isVisible: sidebarVisible,
                  onToggle: () =>
                      ref.read(sidebarVisibilityProvider.notifier).state =
                          false,
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
    super.key,
    required this.visible,
    required this.child,
    this.maintainState = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!visible) {
      return const SizedBox.shrink();
    }
    return child;
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
    final isDark = AdaptiveColors.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: AdaptiveColors.cardBackground(context),
        border: Border(
          top: BorderSide(color: AdaptiveColors.outlineVariant(context)),
        ),
        boxShadow: AppShadows.nav(isDark),
      ),
      child: NavigationBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedIndex: currentIndex,
        onDestinationSelected: onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.fact_check_outlined),
            selectedIcon: Icon(Icons.fact_check_rounded),
            label: 'Tests',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'PYQ',
          ),
          NavigationDestination(
            icon: Icon(Icons.style_outlined),
            selectedIcon: Icon(Icons.style_rounded),
            label: 'Flashcards',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
