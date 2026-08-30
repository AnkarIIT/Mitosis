import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_providers.dart';
import '../../core/models/subject_model.dart';
import '../../core/services/dpp_engine.dart';

class DppScreen extends ConsumerStatefulWidget {
  final String subject;

  const DppScreen({super.key, required this.subject});

  @override
  ConsumerState<DppScreen> createState() => _DppScreenState();
}

class _DppScreenState extends ConsumerState<DppScreen> {
  bool _isGenerating = false;
  DppConfig? _lastConfig;
  DppResult? _currentResult;

  Future<void> _startDpp(DppResult result, DppConfig config) async {
    final durationMinutes = result.set.durationMinutes ?? config.durationMinutes;
    if (!mounted) return;

    await context.push('/dpp/attempt', extra: {
      'dppResult': result,
      'durationMinutes': durationMinutes,
      'config': config,
    });
  }

  Future<void> _generateDpp(DppConfig config) async {
    setState(() {
      _isGenerating = true;
      _lastConfig = config;
    });
    try {
      final engine = ref.read(dppEngineProvider);
      final result = await engine.generate(config, forceRefresh: true);
      if (!mounted) return;

      if (result != null && result.questions.isNotEmpty) {
        setState(() => _currentResult = result);
        await _startDpp(result, config);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough questions available for DPP. Please import more questions.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate DPP: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  Future<void> _regenerateLast() async {
    if (_lastConfig != null) {
      await _generateDpp(_lastConfig!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);
    final subject = subjects.firstWhere(
      (s) => s.id == widget.subject,
      orElse: () => subjects.isNotEmpty
          ? subjects.first
          : Subject(id: '', name: 'Unknown', icon: '📝', chapters: const []),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('${subject.name} - Daily Practice'),
        actions: [
          PopupMenuButton<DppConfig>(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Generate DPP',
            onSelected: (config) => _generateDpp(config),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: DppConfig.single(subject: widget.subject),
                child: const ListTile(
                  leading: Icon(Icons.assignment_rounded),
                  title: Text('Single Subject (20 Q, 20 min)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: DppConfig.mixed(
                  subjects: [widget.subject],
                  weights: {widget.subject: 100},
                  totalQuestions: 40,
                  durationMinutes: 40,
                ),
                child: const ListTile(
                  leading: Icon(Icons.assignment_rounded),
                  title: Text('Extended Single (40 Q, 40 min)'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              if (widget.subject == 'Physics' || widget.subject == 'Chemistry' || widget.subject == 'Biology')
                PopupMenuItem(
                  value: DppConfig.mixed(
                    subjects: ['Physics', 'Chemistry', 'Biology'],
                    weights: const {
                      'Physics': 45,
                      'Chemistry': 45,
                      'Biology': 90,
                    },
                    totalQuestions: 180,
                    durationMinutes: 180,
                  ),
                  child: const ListTile(
                    leading: Icon(Icons.science_rounded),
                    title: Text('NEET Pattern (180 Q, 180 min)'),
                    subtitle: Text('Physics 45, Chem 45, Bio 90'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
            ],
          ),
        ],
      ),
      body: _buildBody(context, subject),
    );
  }

  Widget _buildBody(BuildContext context, Subject subject) {
    if (_currentResult == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.edit_note_rounded, size: 64, color: Theme.of(context).primaryColor.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text(
                'No DPP available yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Generate your daily practice paper for ${subject.name}',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isGenerating ? null : _regenerateLast,
                icon: _isGenerating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.auto_fix_high_rounded),
                label: Text(_isGenerating ? 'Generating...' : 'Generate DPP'),
              ),
            ],
          ),
        ),
      );
    }

    final result = _currentResult!;
    final dppSet = result.set;
    final total = dppSet.totalQuestions;
    final correct = dppSet.correctCount;
    final incorrect = dppSet.incorrectCount;
    final unattempted = dppSet.unattemptedCount;
    final isCompleted = dppSet.isCompleted;
    final duration = dppSet.durationMinutes ?? 20;

    // Calculate subject-wise breakdown
    final subjectBreakdown = _calculateSubjectBreakdown(result);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
