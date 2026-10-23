import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../core/theme/tokens.dart';

/// Modern sidebar navigation - works as desktop drawer or mobile bottom sheet
class ModernSidebar extends ConsumerStatefulWidget {
  final bool isVisible;
  final VoidCallback onToggle;
  final bool isMobile;

  const ModernSidebar({
    super.key,
    required this.isVisible,
    required this.onToggle,
    this.isMobile = false,
  });

  @override
  ConsumerState<ModernSidebar> createState() => _ModernSidebarState();
}

class _ModernSidebarState extends ConsumerState<ModernSidebar> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final progress = ref.watch(userProgressProvider);

    // If not mobile and not visible, don't render
    if (!widget.isMobile && !widget.isVisible) {
      return const SizedBox.shrink();
    }

    final sidebarWidth = 280.0;
    final isDesktop = !widget.isMobile;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: isDesktop ? sidebarWidth : double.infinity,
      height: isDesktop ? double.infinity : null,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: isDesktop
            ? Border(
                right: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  width: 1,
                ),
              )
            : null,
        boxShadow: isDesktop
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(4, 0),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: Column(
        children: [
          // Header with branding
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 16,
              left: 20,
              right: 20,
              bottom: 20,
            ),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.3,
                  ),
                  width: 1,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.asset(
                        'assets/images/mitos-app-icon-1024.png',
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NEET Mitos',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'NEET study companion',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (user != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: SubjectColors.physics.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: SubjectColors.physics.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: SubjectColors.physics,
                          child: Text(
                            user.email?.isNotEmpty == true
                                ? user.email![0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.email ?? 'Guest User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  _buildStatChip(
                                    context: context,
                                    icon: Icons.local_fire_department_outlined,
                                    label: '${progress.currentStreak}d streak',
                                    color: Colors.orange,
                                  ),
                                  const SizedBox(width: 6),
                                  _buildStatChip(
                                    context: context,
                                    icon: Icons.check_circle_outline,
                                    label: '${progress.topicsCompleted} topics',
                                    color: Colors.green,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              final router = GoRouter.of(context);
                              widget.onToggle();
                              Future.microtask(() {
                                if (!mounted) return;
                                router.go('/profile');
                              });
                            },
                            icon: const Icon(Icons.edit_outlined, size: 14),
                            label: const Text(
                              'Edit Profile',
                              style: TextStyle(fontSize: 11),
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Navigation items
          Expanded(child: _buildMenuItems(context)),

          // Footer
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildStatChip({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItems(BuildContext context) {
    final router = GoRouter.of(context);
    final currentLocation = router.routerDelegate.currentConfiguration.uri
        .toString();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildSectionHeader(context, 'YOUR STUDY SPACE'),
        _buildNavTile(
          context: context,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_filled,
          label: 'Today',
          location: '/',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book_rounded,
          label: 'Study',
          location: '/study',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          label: 'You',
          location: '/you',
          currentLocation: currentLocation,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNavTile({
    required BuildContext context,
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required String location,
    required String currentLocation,
  }) {
    final isSelected =
        currentLocation.startsWith(location) && location != '/' ||
        (location == '/' && currentLocation == '/');
    final theme = Theme.of(context);
    final router = GoRouter.of(context);

    return ListTile(
      leading: Icon(
        isSelected ? selectedIcon : icon,
        size: 22,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface,
          fontSize: 14,
        ),
      ),
      selected: isSelected,
      selectedTileColor: theme.colorScheme.primary.withValues(alpha: 0.08),
      selectedColor: theme.colorScheme.primary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      onTap: () {
        widget.onToggle();
        Future.microtask(() {
          if (!mounted) return;
          final currentLoc = router.routerDelegate.currentConfiguration.uri
              .toString();
          if (currentLoc != location) {
            router.go(location);
          }
        });
      },
    );
  }

  Widget _buildFooter(BuildContext context) {
    final router = GoRouter.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_outlined, size: 20),
            title: const Text('Settings'),
            onTap: () {
              widget.onToggle();
              Future.microtask(() {
                if (!mounted) return;
                router.go('/settings');
              });
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outlined, size: 20),
            title: const Text('About'),
            onTap: () {
              widget.onToggle();
              showDialog(context: context, builder: (_) => const AboutDialog());
            },
          ),
        ],
      ),
    );
  }
}

class AboutDialog extends StatelessWidget {
  const AboutDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('NEET Mitos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Version 1.0.0',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI-Powered NEET Preparation Platform\n'
            'Built with Flutter & Riverpod',
          ),
          const SizedBox(height: 16),
          const Text(
            '© 2024 NEET Mitos. All rights reserved.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
