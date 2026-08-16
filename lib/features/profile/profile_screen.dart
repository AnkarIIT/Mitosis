import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';

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
          ],
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
                const Column(
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
                Text(
                  'Current Est: ${currentAccuracy.toStringAsFixed(0)}',
                  style: const TextStyle(fontSize: 12),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBadge(
              Icons.local_fire_department,
              '3 Day Streak',
              Colors.orange,
            ),
            _buildBadge(Icons.verified, 'Quick Learner', Colors.blue),
            _buildBadge(Icons.emoji_events, '70% Accuracy', Colors.amber),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
      ],
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
}
