import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/user_preferences_model.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Batch onboarding triage — a 3-step flow embedded in the onboarding
/// PageView:
///
///  1. Persona (Class 11 / Class 12 / Dropper)
///  2. Target year
///  3. Daily commitment (minutes)
///
/// Choices are persisted through [userPreferencesProvider] (device prefs +
/// write-through to the users table when logged in). [onDone] advances the
/// parent flow; the step can also be skipped without saving.
class BatchOnboardingPage extends ConsumerStatefulWidget {
  const BatchOnboardingPage({super.key, required this.onDone});

  final VoidCallback onDone;

  @override
  ConsumerState<BatchOnboardingPage> createState() => _BatchOnboardingPageState();
}

class _BatchOnboardingPageState extends ConsumerState<BatchOnboardingPage> {
  int _step = 0;
  String? _batch;
  int? _targetYear;
  int? _commitment;
  bool _saving = false;

  static const List<int> _yearOptions = [2026, 2027, 2028, 2029];
  static const List<int> _commitmentOptions = [30, 60, 90, 120];

  bool get _canProceed {
    switch (_step) {
      case 0:
        return _batch != null;
      case 1:
        return _targetYear != null;
      case 2:
        return _commitment != null;
      default:
        return false;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(userPreferencesProvider.notifier).save(
      batch: _batch,
      targetYear: _targetYear,
      dailyCommitmentMinutes: _commitment,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    widget.onDone();
  }

  void _next() {
    if (_step < 2) {
      setState(() => _step += 1);
    } else {
      _save();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Column(
        children: [
          _buildHeader(context),
          const SizedBox(height: 8),
          Expanded(child: _buildStep(context)),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final labels = ['Persona', 'Target Year', 'Commitment'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (_step > 0) ...[
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _step -= 1),
              ),
            ],
            Expanded(
              child: Center(
                child: Text(
                  labels[_step],
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            SizedBox(width: _step > 0 ? 48 : 0),
          ],
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: (_step + 1) / 3,
            minHeight: 6,
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
      ],
    );
  }

  Widget _buildStep(BuildContext context) {
    switch (_step) {
      case 0:
        return _buildPersonaStep(context);
      case 1:
        return _buildYearStep(context);
      default:
        return _buildCommitmentStep(context);
    }
  }

  Widget _buildPersonaStep(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'Which batch are you in?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AdaptiveColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This personalizes your syllabus — Class 11 & 12 students see only '
            'their NCERT chapters, while droppers get the full syllabus.',
            style: TextStyle(color: AppColors.secondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          _personaCard(
            context,
            icon: Icons.biotech,
            title: NeetBatch.class11.displayName,
            subtitle: 'Studying Class 11 NCERT',
            color: Colors.green,
          ),
          const SizedBox(height: 12),
          _personaCard(
            context,
            icon: Icons.science,
            title: NeetBatch.class12.displayName,
            subtitle: 'Studying Class 12 NCERT',
            color: Colors.blue,
          ),
          const SizedBox(height: 12),
          _personaCard(
            context,
            icon: Icons.flag,
            title: NeetBatch.dropper.displayName,
            subtitle: 'Completed 12th, full syllabus',
            color: Colors.deepPurple,
          ),
        ],
      ),
    );
  }

  Widget _personaCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    final selected = _batch == title;
    return Material(
      color: selected ? color.withValues(alpha: 0.1) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => setState(() => _batch = title),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? color : AppColors.divider,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AdaptiveColors.textPrimary(context),
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(Icons.check_circle, color: color)
              else
                Icon(Icons.circle_outlined, color: AppColors.divider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildYearStep(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'What year are you targeting?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AdaptiveColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll use this to pace your plan toward the exam.',
            style: TextStyle(color: AppColors.secondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ..._yearOptions.map(
                (year) => ChoiceChip(
                  label: Text('$year'),
                  selected: _targetYear == year,
                  onSelected: (_) => setState(() => _targetYear = year),
                  selectedColor: AppColors.primary.withValues(alpha: 0.15),
                  labelStyle: TextStyle(
                    color: _targetYear == year
                        ? AppColors.primary
                        : AdaptiveColors.textPrimary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ChoiceChip(
                label: const Text('Not sure yet'),
                selected: _targetYear != null && !_yearOptions.contains(_targetYear),
                onSelected: (_) => setState(() => _targetYear = 0),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommitmentStep(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Text(
            'How much time can you commit daily?',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AdaptiveColors.textPrimary(context),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'This sets your daily question target so the plan stays realistic.',
            style: TextStyle(color: AppColors.secondary, height: 1.4),
          ),
          const SizedBox(height: 24),
          ..._commitmentOptions.map((minutes) {
            final selected = _commitment == minutes;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: selected
                    ? AppColors.primary.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => setState(() => _commitment = minutes),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected ? AppColors.primary : AppColors.divider,
                        width: selected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          color: selected ? AppColors.primary : AppColors.secondary,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            _commitmentLabel(minutes),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AdaptiveColors.textPrimary(context),
                            ),
                          ),
                        ),
                        if (selected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.primary,
                          )
                        else
                          Icon(
                            Icons.circle_outlined,
                            color: AppColors.divider,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _commitmentLabel(int minutes) {
    if (minutes == 30) return '30 min — Light (${_targetLabel(minutes)} q/day)';
    if (minutes == 60) return '1 hour — Standard (${_targetLabel(minutes)} q/day)';
    if (minutes == 90) return '1.5 hours — Intense (${_targetLabel(minutes)} q/day)';
    return '2+ hours — Extreme (${_targetLabel(minutes)} q/day)';
  }

  String _targetLabel(int minutes) {
    return UserPreferences(dailyCommitmentMinutes: minutes)
        .recommendedDailyTarget
        .toString();
  }

  Widget _buildFooter(BuildContext context) {
    return Row(
      children: [
        TextButton(
          onPressed: _saving ? null : widget.onDone,
          child: const Text('SKIP', style: TextStyle(color: AppColors.secondary)),
        ),
        const Spacer(),
        FilledButton(
          onPressed: _canProceed && !_saving ? _next : null,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : Text(_step == 2 ? 'CONTINUE' : 'NEXT'),
        ),
      ],
    );
  }
}

