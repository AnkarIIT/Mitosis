import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/achievement_model.dart';
import '../../core/services/achievement_service.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _targetScoreController = TextEditingController();
  bool _isEditing = false;
  int _targetScore = 650;

  static const _targetScoreKey = 'neet_target_score';

  @override
  void initState() {
    super.initState();
    _loadTargetScore();
  }

  @override
  void dispose() {
    _targetScoreController.dispose();
    super.dispose();
  }

  Future<void> _loadTargetScore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTarget = prefs.getInt(_targetScoreKey) ?? 650;

    if (!mounted) return;

    setState(() {
      _targetScore = savedTarget;
      _targetScoreController.text = savedTarget.toString();
    });
  }

  Future<void> _saveTargetScore() async {
    final parsed = int.tryParse(_targetScoreController.text.trim());
    final nextTarget = parsed ?? _targetScore;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_targetScoreKey, nextTarget);

    if (!mounted) return;

    setState(() {
      _targetScore = nextTarget;
      _isEditing = false;
      _targetScoreController.text = nextTarget.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = ref.watch(overallStatsProvider);
    final authState = ref.watch(authProvider);
    final currentAccuracy = (stats['accuracy'] as double);
    final progress = _targetScore == 0
        ? 0.0
        : (currentAccuracy / _targetScore).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(title: const Text('Student Profile'), elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildProfileHeader(authState),
            const SizedBox(height: 32),
            _buildTargetScoreCard(currentAccuracy, progress),
            const SizedBox(height: 24),
            _buildAchievementSection(stats),
            const SizedBox(height: 24),
            _buildStatsOverview(stats),
            const SizedBox(height: 24),
            _buildSettingsCard(context),
            const SizedBox(height: 24),
            _buildLogoutButton(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () async {
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(onPressed: () => context.pop(false), child: const Text('CANCEL')),
                TextButton(onPressed: () => context.pop(true), child: const Text('LOGOUT')),
              ],
            ),
          );
          if (confirm != true) return;
          await ref.read(authProvider.notifier).logout();
          if (!context.mounted) return;
          context.go('/auth');
        },
        icon: const Icon(Icons.logout_rounded),
        label: const Text('Logout'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red.shade400,
          side: BorderSide(color: Colors.red.shade400.withValues(alpha: 0.3)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(AuthState auth) {
    return Column(
      children: [
        Stack(
          children: [
            const CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.primary,
              child: Icon(Icons.person, size: 60, color: Colors.white),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.secondary,
                child: IconButton(
                  icon: const Icon(
                    Icons.edit,
                    size: 18,
                    color: AppColors.primary,
                  ),
                  onPressed: () {},
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          auth.user?.username ?? 'Guest Learner',
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(
          auth.user?.email ?? 'Complete your profile to sync data',
          style: const TextStyle(color: AppColors.textSubtle),
        ),
      ],
    );
  }

  Widget _buildTargetScoreCard(double currentAccuracy, double progress) {
    return Card(
      elevation: 0,
      color: AppColors.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: AppColors.primary, width: 0.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'NEET Target Score',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Aim high, work hard',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSubtle,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isEditing)
                  Text(
                    _targetScore.toString(),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  )
                else
                  SizedBox(
                    width: 80,
                    child: TextField(
                      controller: _targetScoreController,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(isDense: true),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              borderRadius: BorderRadius.circular(10),
              minHeight: 10,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Current Est: ${currentAccuracy.toStringAsFixed(0)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (_isEditing) {
                      await _saveTargetScore();
                      return;
                    }

                    setState(() => _isEditing = true);
                  },
                  child: Text(_isEditing ? 'SAVE' : 'UPDATE GOAL'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementSection(Map<String, dynamic> stats) {
    final progress = ref.read(userProgressProvider);
    final board = AchievementService.achievementBoard(progress);
    final earned = board.where((item) => item['earned'] == true).toList();
    final locked = board.where((item) => item['earned'] != true).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Text(
                'Achievements',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ),
            if (locked.isNotEmpty)
              TextButton.icon(
                onPressed: () => _showAllAchievements(context, board),
                icon: const Icon(Icons.lock_open, size: 16),
                label: const Text('View all'),
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (earned.isEmpty)
          _GitHubStyleAchievementTile(
            icon: Icons.lock_outline,
            title: 'No achievements yet',
            description: 'Start solving questions to earn your first trophy.',
            color: AppColors.divider,
            locked: true,
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: earned
                  .map((item) {
                    final achievement = item['achievement'] as Achievement;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: _GitHubStyleAchievementTile(
                        icon: achievement.icon,
                        title: achievement.title,
                        description: achievement.description,
                        color: achievement.color,
                        locked: false,
                      ),
                    );
                  })
                  .toList(),
            ),
          ),
        if (locked.isNotEmpty) const SizedBox(height: 12),
        if (locked.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: locked
                .take(6)
                .map((item) {
                  final achievement = item['achievement'] as Achievement;
                  return _LockedAchievementChip(achievement: achievement);
                })
                .toList(),
          ),
      ],
    );
  }

  void _showAllAchievements(
    BuildContext context,
    List<Map<String, dynamic>> board,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'All Achievements',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: board.length,
                itemBuilder: (context, index) {
                  final item = board[index];
                  final achievement = item['achievement'] as Achievement;
                  final earned = item['earned'] == true;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _GitHubStyleAchievementTile(
                      icon: achievement.icon,
                      title: achievement.title,
                      description: achievement.description,
                      color: achievement.color,
                      locked: !earned,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsOverview(Map<String, dynamic> stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Solved',
          '${stats['totalAttempted']}',
          Icons.check_circle_outline,
        ),
        _buildStatCard(
          'Accuracy',
          '${(stats['accuracy'] as double).toStringAsFixed(1)}%',
          Icons.track_changes,
        ),
        _buildStatCard('Quizzes', '${stats['quizCount']}', Icons.quiz_outlined),
        _buildStatCard(
          'Topics Done',
          '${stats['topicsCompleted']}',
          Icons.menu_book,
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: AppColors.textSubtle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context) {
    return Card(
      elevation: 0,
      color: AdaptiveColors.surface(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.divider.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.settings_rounded, color: AppColors.primary, size: 22),
        ),
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Appearance, sync, AI preferences'),
        trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey.shade400),
        onTap: () => context.push('/settings'),
      ),
    );
  }
}

class _GitHubStyleAchievementTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final bool locked;

  const _GitHubStyleAchievementTile({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.locked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 180, maxWidth: 220),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: locked
            ? AppColors.surface
            : color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: locked
              ? AppColors.divider.withValues(alpha: 0.4)
              : color.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (locked ? AppColors.divider : color)
                  .withValues(alpha: locked ? 0.1 : 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              locked ? Icons.lock_outline : icon,
              color: locked ? AppColors.divider : color,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: locked ? AppColors.divider : AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: locked
                        ? AppColors.divider
                        : AppColors.textSubtle,
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (!locked)
            Icon(Icons.verified_rounded, color: color, size: 18),
        ],
      ),
    );
  }
}

class _LockedAchievementChip extends StatelessWidget {
  final Achievement achievement;

  const _LockedAchievementChip({required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.lock_outline,
            size: 14,
            color: AppColors.divider,
          ),
          const SizedBox(width: 6),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.divider,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
