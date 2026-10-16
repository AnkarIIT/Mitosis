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
          if (isDesktop && sidebarVisible)
            Positioned(
              top: 0,
              right: 0,
              child: ModernSidebar(
                isVisible: sidebarVisible,
                onToggle: () =>
                    ref.read(sidebarVisibilityProvider.notifier).state = false,
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

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Container(
        decoration: BoxDecoration(
          color: AdaptiveColors.cardBackground(context),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: AdaptiveColors.outlineVariant(
              context,
            ).withValues(alpha: 0.7),
          ),
          boxShadow: AppShadows.raised(isDark),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: NavigationBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            height: 72,
            labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
            selectedIndex: currentIndex,
            onDestinationSelected: onTap,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Today',
              ),
              NavigationDestination(
                icon: Icon(Icons.school_outlined),
                selectedIcon: Icon(Icons.school_rounded),
                label: 'Learn',
              ),
              NavigationDestination(
                icon: Icon(Icons.edit_note_outlined),
                selectedIcon: Icon(Icons.edit_note_rounded),
                label: 'Practice',
              ),
              NavigationDestination(
                icon: Icon(Icons.replay_outlined),
                selectedIcon: Icon(Icons.replay_rounded),
                label: 'Review',
              ),
              NavigationDestination(
                icon: Icon(Icons.insights_outlined),
                selectedIcon: Icon(Icons.insights_rounded),
                label: 'Progress',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
