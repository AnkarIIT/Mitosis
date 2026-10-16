import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/content_providers.dart';
import '../../core/services/dpp_engine.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

/// Daily Practice Paper setup: scope → size → difficulty → start.
///
/// One primary CTA per screen. Generation shows loading/disabled state, and
/// an empty pool recovers via retry + question import instead of dead-ending.
class DppNeetScreen extends ConsumerStatefulWidget {
  const DppNeetScreen({super.key});

  @override
  ConsumerState<DppNeetScreen> createState() => _DppNeetScreenState();
}

class _DppNeetScreenState extends ConsumerState<DppNeetScreen> {
  static const _counts = [10, 20, 30, 45];
  static const _mixes = [
    (label: 'Foundation', easy: 50, medium: 35, hard: 15, hint: 'Easy-heavy'),
    (label: 'Balanced', easy: 30, medium: 50, hard: 20, hint: 'NEET-like mix'),
    (label: 'Challenger', easy: 15, medium: 45, hard: 40, hint: 'Hard-heavy'),
  ];

  int _scopeIndex = 0; // 0 = mixed, else subjects[_scopeIndex - 1]
  int _countIndex = 1; // 20 questions
  int _mixIndex = 1; // Balanced
  bool _includeWeakTopics = true;
  bool _isGenerating = false;
  String? _error;

  Future<void> _start() async {
    if (_isGenerating) return;
    final names = ref.read(subjectsProvider).map((s) => s.name).toList();
    if (names.isEmpty) {
      setState(() => _error = 'Subjects are still loading. Please retry.');
      return;
    }
    setState(() {
      _isGenerating = true;
      _error = null;
    });
    try {
      final count = _counts[_countIndex];
      final mix = _mixes[_mixIndex];
      final config = DppConfig(
        subjects: _scopeIndex == 0 ? names : [names[_scopeIndex - 1]],
        totalQuestions: count,
        durationMinutes: count,
        easyPercent: mix.easy,
        mediumPercent: mix.medium,
        hardPercent: mix.hard,
        includeWeakTopics: _includeWeakTopics,
      );
      final result = await ref
          .read(dppEngineProvider)
          .generate(config, forceRefresh: true);
      if (!mounted) return;
      if (result.questions.isNotEmpty) {
        await GoRouter.of(context).push(
          '/dpp/attempt',
          extra: {
            'dppResult': result,
            'durationMinutes': config.durationMinutes,
            'config': config,
          },
        );
      } else {
        setState(
          () => _error =
              'Not enough unseen questions for this setup. Try fewer questions, or import more.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Could not generate the paper. Please retry.');
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final names = ref.watch(subjectsProvider).map((s) => s.name).toList();
    final count = _counts[_countIndex];
    final scopeLabel = _scopeIndex == 0
        ? 'Mixed (${names.join(' + ')})'
        : names[_scopeIndex - 1];

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(title: const Text('Daily Practice Paper')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildSummaryCard(context, scopeLabel, count),
            const SizedBox(height: 20),
            _sectionTitle(context, 'Scope'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Mixed NEET'),
                  selected: _scopeIndex == 0,
                  onSelected: _isGenerating
                      ? null
                      : (_) => setState(() => _scopeIndex = 0),
                ),
                for (var i = 0; i < names.length; i++)
                  ChoiceChip(
                    label: Text(names[i]),
                    selected: _scopeIndex == i + 1,
                    onSelected: _isGenerating
                        ? null
                        : (_) => setState(() => _scopeIndex = i + 1),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle(context, 'Questions'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _counts.length; i++)
                  ChoiceChip(
                    label: Text('${_counts[i]}'),
                    selected: _countIndex == i,
                    onSelected: _isGenerating
                        ? null
                        : (_) => setState(() => _countIndex = i),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            _sectionTitle(context, 'Difficulty'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (var i = 0; i < _mixes.length; i++)
                  ChoiceChip(
                    label: Text('${_mixes[i].label} • ${_mixes[i].hint}'),
                    selected: _mixIndex == i,
                    onSelected: _isGenerating
                        ? null
                        : (_) => setState(() => _mixIndex = i),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Prioritise weak topics'),
              subtitle: Text(
                'Bias the paper toward topics below 50% accuracy',
                style: TextStyle(
                  color: AdaptiveColors.textSecondary(context),
                  fontSize: 12,
                ),
              ),
              value: _includeWeakTopics,
              onChanged: _isGenerating
                  ? null
                  : (v) => setState(() => _includeWeakTopics = v),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              _buildErrorCard(context),
            ],
            const SizedBox(height: 96),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 16),
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _isGenerating || names.isEmpty ? null : _start,
            icon: _isGenerating
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  )
                : const Icon(Icons.play_arrow_rounded, size: 24),
            label: Text(
              _isGenerating ? 'Generating…' : 'Start DPP • $count min',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }

  Widget _buildSummaryCard(BuildContext context, String scopeLabel, int count) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AdaptiveColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AdaptiveColors.outlineVariant(context)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_note_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$count questions • $count min • ${_mixes[_mixIndex].label}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  scopeLabel,
                  style: TextStyle(
                    color: AdaptiveColors.textSecondary(context),
                    fontSize: 12,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.error.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.error_outline_rounded,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isGenerating ? null : _start,
                  child: const Text('Retry'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton(
                  onPressed: () => context.push('/settings/import'),
                  child: const Text('Import questions'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
