import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:neet_mitos/core/models/batch_model.dart';
import 'package:neet_mitos/core/providers/service_providers.dart';

class BatchSelectionScreen extends ConsumerStatefulWidget {
  const BatchSelectionScreen({super.key});

  @override
  ConsumerState<BatchSelectionScreen> createState() =>
      _BatchSelectionScreenState();
}

class _BatchSelectionScreenState extends ConsumerState<BatchSelectionScreen> {
  late BatchType _selectedBatch;
  late StudyMode _selectedMode;
  int _dailyGoalHours = 2;

  @override
  void initState() {
    super.initState();
    _selectedBatch = BatchType.class11_2026;
    _selectedMode = StudyMode.selfStudy;
  }

  void _continue() {
    final batch = UserBatch(
      type: _selectedBatch,
      studyMode: _selectedMode,
      dailyGoalHours: _dailyGoalHours,
    );
    ref.read(batchServiceProvider.notifier).saveBatch(batch);
    if (!mounted) return;
    Navigator.of(context).pushNamed('/goal-setting');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Select Your Batch')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBatchDropdown(),
            const SizedBox(height: 32),
            _buildStudyModeDropdown(),
            const SizedBox(height: 32),
            _buildDailyGoalSlider(),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _continue,
              child: const Text('Continue to Goal Setting'),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildBatchDropdown() {
    return DropdownButtonFormField<BatchType>(
      value: _selectedBatch,
      decoration: const InputDecoration(
        labelText: 'Batch Type',
        border: OutlineInputBorder(),
      ),
      items: BatchType.values.map((BatchType type) {
        return DropdownMenuItem<BatchType>(
          value: type,
          child: Text(_batchTypeLabel(type)),
        );
      }).toList(),
      onChanged: (BatchType? value) {
        if (value != null) {
          setState(() => _selectedBatch = value);
        }
      },
    );
  }

  String _batchTypeLabel(BatchType type) {
    switch (type) {
      case BatchType.class11_2026:
        return 'Class 11 (2026 Batch)';
      case BatchType.class12_2026:
        return 'Class 12 (2026 Batch)';
      case BatchType.dropper_2026:
        return 'Dropper (2026 Batch)';
      case BatchType.class11_2027:
        return 'Class 11 (2027 Batch)';
      case BatchType.class12_2027:
        return 'Class 12 (2027 Batch)';
      case BatchType.dropper_2027:
        return 'Dropper (2027 Batch)';
    }
  }

  Widget _buildStudyModeDropdown() {
    return DropdownButtonFormField<StudyMode>(
      value: _selectedMode,
      decoration: const InputDecoration(
        labelText: 'Study Mode',
        border: OutlineInputBorder(),
      ),
      items: StudyMode.values.map((StudyMode mode) {
        return DropdownMenuItem<StudyMode>(
          value: mode,
          child: Text(_studyModeLabel(mode)),
        );
      }).toList(),
      onChanged: (StudyMode? value) {
        if (value != null) {
          setState(() => _selectedMode = value);
        }
      },
    );
  }

  String _studyModeLabel(StudyMode mode) {
    switch (mode) {
      case StudyMode.selfStudy:
        return 'Self Study';
      case StudyMode.coachingStudent:
        return 'Coaching Student';
      case StudyMode.onlineCourse:
        return 'Online Course';
    }
  }

  Widget _buildDailyGoalSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Daily Study Goal (hours)',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        Slider(
          value: _dailyGoalHours.toDouble(),
          min: 1,
          max: 6,
          divisions: 5,
          label: '$_dailyGoalHours',
          onChanged: (double value) {
            setState(() => _dailyGoalHours = value.round());
          },
        ),
        Text(
          '$_dailyGoalHours hours per day',
          style: const TextStyle(fontSize: 16),
        ),
      ],
    );
  }
}

class GoalSettingScreen extends ConsumerStatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  ConsumerState<GoalSettingScreen> createState() =>
      _GoalSettingScreenState();
}

class _GoalSettingScreenState extends ConsumerState<GoalSettingScreen> {
  int _targetScore = 600;
  bool _aimingForMedical = true;

  @override
  void initState() {
    super.initState();
    final batch = ref.watch(batchServiceProvider);
    if (batch != null) {
      _targetScore = batch.type.targetScoreBase;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Your Goal')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Target NEET Score',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Slider(
              value: _targetScore.toDouble(),
              min: 400,
              max: 720,
              divisions: 64,
              label: '$_targetScore',
              onChanged: (double value) {
                setState(() => _targetScore = value.round());
              },
            ),
            Text(
              '$_targetScore / 720',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 32),
            const Text(
              'Target Goal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            Row(
              children: [
                Expanded(
                  child: _GoalChip(
                    label: 'Medical College',
                    isSelected: _aimingForMedical,
                    onSelected: (selected) {
                      setState(() => _aimingForMedical = selected);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _GoalChip(
                    label: 'State College',
                    isSelected: !_aimingForMedical,
                    onSelected: (selected) {
                      setState(() => _aimingForMedical = selected);
                    },
                  ),
                ),
              ],
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: () {
                final batch = ref.watch(batchServiceProvider);
                if (batch != null) {
                  final updatedBatch = batch.copyWith(
                    studyMode: _aimingForMedical ? StudyMode.coachingStudent : StudyMode.selfStudy,
                  );
                  ref.read(batchServiceProvider.notifier).saveBatch(updatedBatch);
                }
                if (!mounted) return;
                Navigator.of(context).pop();
              },
              child: const Text('Finish Onboarding'),
            )
          ],
        ),
      ),
    );
  }
}

class _GoalChip extends StatefulWidget {
  final String label;
  final bool isSelected;
  final ValueChanged<bool> onSelected;

  const _GoalChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  @override
  State<_GoalChip> createState() => _GoalChipState();
}

class _GoalChipState extends State<_GoalChip> {
  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(widget.label),
      selected: widget.isSelected,
      onSelected: widget.onSelected,
      checkmarkColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      backgroundColor: Theme.of(context).colorScheme.surface,
      selectedColor: Theme.of(context).colorScheme.primary,
      disabledColor: Theme.of(context).colorScheme.outline,
    );
  }
}