import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/content_providers.dart';
import '../../core/services/dpp_engine.dart';
import '../../core/models/subject_model.dart';

class DppNeetScreen extends ConsumerWidget {
  const DppNeetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);
    final primary = subjects.isNotEmpty
        ? subjects.first
        : Subject(id: '', name: 'NEET', icon: '📝', chapters: const []);

    return Scaffold(
      appBar: AppBar(title: Text('${primary.name} - NEET Pattern DPP')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.assignment_rounded,
                size: 64,
                color: Theme.of(context).primaryColor.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                'NEET Pattern Practice',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text(
                '180 questions • 180 minutes • Physics + Chemistry + Biology',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () async {
                  final engine = ref.read(dppEngineProvider);
                  final config = DppConfig.neetPattern();
                  final result = await engine.generate(
                    config,
                    forceRefresh: true,
                  );

                  if (!context.mounted) return;

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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Not enough questions for NEET pattern. Please import more questions.',
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start NEET DPP'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
