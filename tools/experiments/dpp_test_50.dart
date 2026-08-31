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
