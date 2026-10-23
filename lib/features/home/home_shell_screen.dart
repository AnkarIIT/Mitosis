import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/offline_banner.dart';

class HomeShellScreen extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShellScreen({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      body: Row(
        children: [
          if (isWide)
            _AppNavigationRail(
              currentIndex: navigationShell.currentIndex,
              onTap: (index) => _selectBranch(index),
            ),
          Expanded(
            child: Column(
              children: [
                const OfflineBanner(),
                Expanded(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 960),
                      child: navigationShell,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : _ModernBottomNavigation(
              currentIndex: navigationShell.currentIndex,
              onTap: _selectBranch,
            ),
    );
  }

  void _selectBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

class _AppNavigationRail extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _AppNavigationRail({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      backgroundColor: AdaptiveColors.cardBackground(context),
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      labelType: NavigationRailLabelType.all,
      groupAlignment: -0.65,
      leading: Padding(
        padding: const EdgeInsets.only(bottom: 28, top: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Image.asset(
            'assets/images/mitos-app-icon-1024.png',
            width: 44,
            height: 44,
          ),
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: Text('Today'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.menu_book_outlined),
          selectedIcon: Icon(Icons.menu_book_rounded),
          label: Text('Study'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: Text('You'),
        ),
      ],
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
                icon: Icon(Icons.menu_book_outlined),
                selectedIcon: Icon(Icons.menu_book_rounded),
                label: 'Study',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'You',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
