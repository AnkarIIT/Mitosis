import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../core/theme/tokens.dart';

/// Modern sidebar navigation - works as desktop drawer or mobile bottom sheet
class ModernSidebar extends ConsumerWidget {
  final bool isVisible;
  final VoidCallback onToggle;
  final bool isMobile;

  const ModernSidebar({
    Key? key,
    required this.isVisible,
    required this.onToggle,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final progress = ref.watch(userProgressProvider);
    
    // If not mobile and not visible, don't render
    if (!isMobile && !isVisible) {
      return const SizedBox.shrink();
    }

    final displayName = user?.fullName ?? user?.username ?? 'Guest';
    final avatarLetter = displayName.isNotEmpty ? displayName[0].toUpperCase() : 'G';
    final streak = progress.currentStreak;
    final accuracy = (ref.watch(overallStatsProvider)['accuracy'] as double?) ?? 0.0;

    if (isMobile) {
      return _buildMobileSidebar(context, theme, avatarLetter, displayName, streak, accuracy);
    }

    return _buildDesktopSidebar(context, theme, avatarLetter, displayName, streak, accuracy);
  }

  Widget _buildDesktopSidebar(
    BuildContext context,
    ThemeData theme,
    String avatarLetter,
    String displayName,
    int streak,
    double accuracy,
  ) {
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Clickable overlay to close sidebar
          GestureDetector(
            onTap: onToggle,
            child: Container(
              color: Colors.black.withOpacity(0.3),
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height,
            ),
          ),
          // Sidebar
          Align(
            alignment: Alignment.topRight,
            child: Container(
              width: 280,
              height: MediaQuery.of(context).size.height,
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(-2, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _buildHeader(context, theme, avatarLetter, displayName, streak, accuracy),
                  const Divider(height: 1),
                  Expanded(child: _buildMenuItems(context)),
                  _buildFooter(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileSidebar(
    BuildContext context,
    ThemeData theme,
    String avatarLetter,
    String displayName,
    int streak,
    double accuracy,
  ) {
    return Column(
      children: [
        _buildHeader(context, theme, avatarLetter, displayName, streak, accuracy),
        const Divider(height: 1),
        Expanded(child: _buildMenuItems(context)),
        _buildFooter(context),
      ],
    );
  }

  Widget _buildHeader(
    BuildContext context,
    ThemeData theme,
    String avatarLetter,
    String displayName,
    int streak,
    double accuracy,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.1),
            theme.colorScheme.primary.withOpacity(0.05),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: theme.colorScheme.primary,
                child: Text(
                  avatarLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'NEET Aspirant',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              // Close button for mobile
              if (isMobile)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
            ],
          ),
          const SizedBox(height: 16),
          // Quick stats row
          Row(
            children: [
              _buildStatChip(
                context: context,
                icon: Icons.local_fire_department,
                label: '$streak',
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildStatChip(
                context: context,
                icon: Icons.trending_up,
                label: '${accuracy.toStringAsFixed(0)}%',
                color: SubjectColors.physics,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    onToggle();
                    Future.microtask(() => context.go('/profile'));
                  },
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Edit Profile', style: TextStyle(fontSize: 11)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                ),
              ),
            ],
          ),
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
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
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
    final currentLocation = router.routerDelegate.currentConfiguration.uri.toString();

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildSectionHeader('MAIN'),
        _buildNavTile(
          context: context,
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_filled,
          label: 'Home',
          location: '/',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.science_outlined,
          selectedIcon: Icons.science,
          label: 'Tests',
          location: '/test',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.bookmarks_outlined,
          selectedIcon: Icons.bookmarks,
          label: 'PYQ Downloads',
          location: '/pyq',
          currentLocation: currentLocation,
        ),

        _buildSectionHeader('STUDY TOOLS'),
        _buildNavTile(
          context: context,
          icon: Icons.psychology_outlined,
          selectedIcon: Icons.psychology,
          label: 'AI Tutor',
          location: '/chat',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.list_alt_outlined,
          selectedIcon: Icons.list_alt,
          label: 'Flashcards',
          location: '/flashcards',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.refresh_outlined,
          selectedIcon: Icons.refresh,
          label: 'Review',
          location: '/review',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.quiz_outlined,
          selectedIcon: Icons.quiz,
          label: 'Quiz',
          location: '/quiz',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.assignment_outlined,
          selectedIcon: Icons.assignment,
          label: 'DPP',
          location: '/dpp/neet',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.insert_drive_file_outlined,
          selectedIcon: Icons.insert_drive_file,
          label: 'PDF Viewer',
          location: '/pdf',
          currentLocation: currentLocation,
        ),

        _buildSectionHeader('MY PROGRESS'),
        _buildNavTile(
          context: context,
          icon: Icons.bar_chart_outlined,
          selectedIcon: Icons.bar_chart,
          label: 'Progress',
          location: '/progress',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.bookmark_border,
          selectedIcon: Icons.bookmarks,
          label: 'Bookmarks',
          location: '/bookmarks',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.error_outline,
          selectedIcon: Icons.error,
          label: 'Error Bank',
          location: '/error-book',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.flag_outlined,
          selectedIcon: Icons.flag,
          label: 'Mark Booster',
          location: '/mark-booster',
          currentLocation: currentLocation,
        ),

        _buildSectionHeader('LEARNING'),
        _buildNavTile(
          context: context,
          icon: Icons.calendar_today_outlined,
          selectedIcon: Icons.calendar_today,
          label: 'Study Plan',
          location: '/study-plan',
          currentLocation: currentLocation,
        ),
        _buildNavTile(
          context: context,
          icon: Icons.menu_book_outlined,
          selectedIcon: Icons.menu_book,
          label: 'Study Modules',
          location: '/study-modules',
          currentLocation: currentLocation,
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: Colors.grey.shade500,
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
    final theme = Theme.of(context);
    final isSelected = currentLocation == location ||
        (location != '/' && currentLocation.startsWith(location));

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      leading: Icon(
        isSelected ? selectedIcon : icon,
        color: isSelected ? theme.colorScheme.primary : Colors.grey.shade600,
        size: 22,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected
              ? theme.colorScheme.onSurface
              : Colors.grey.shade700,
          fontSize: 14,
        ),
      ),
      onTap: () {
        onToggle();
        Future.microtask(() {
          final router = GoRouter.of(context);
          final currentLoc = router.routerDelegate.currentConfiguration.uri.toString();
          if (currentLoc != location) {
            router.go(location);
          }
        });
      },
      selected: isSelected,
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.settings_outlined, size: 20),
            title: const Text('Settings'),
            onTap: () {
              onToggle();
              Future.microtask(() => context.go('/settings'));
            },
          ),
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outlined, size: 20),
            title: const Text('About'),
            onTap: () {
              onToggle();
              showDialog(context: context, builder: (_) => const AboutDialog());
            },
          ),
        ],
      ),
    );
  }
}

class AboutDialog extends StatelessWidget {
  const AboutDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('NEET Mitos'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text('Version 1.0.0'),
          SizedBox(height: 8),
          Text(
            'Your complete NEET preparation companion',
            style: TextStyle(color: Colors.grey),
          ),
          SizedBox(height: 16),
          Text('Features:', style: TextStyle(fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('• AI Tutor for doubt solving'),
          Text('• 19 years of PYQ papers'),
          Text('• Mock tests with detailed analysis'),
          Text('• Flashcards for revision'),
          Text('• DPP practice'),
          Text('• PDF viewer for NCERT'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}