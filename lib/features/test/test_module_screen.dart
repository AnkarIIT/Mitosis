import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../exam_engine/cbt_test_screen.dart';
import '../dpp/dpp_neet_screen.dart';
import '../test_series/question_paper_selector.dart';
import '../../core/services/exam_engine_service.dart';
import '../../core/providers/providers.dart';

/// Unified Test Module - Consolidates all exam-related features
/// Under ONE category: "TEST"
class TestModuleScreen extends ConsumerStatefulWidget {
  const TestModuleScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<TestModuleScreen> createState() => _TestModuleScreenState();
}

class _TestModuleScreenState extends ConsumerState<TestModuleScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tests'),
        centerTitle: true,
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: theme.colorScheme.primary,
          labelColor: theme.colorScheme.primary,
          unselectedLabelColor: Colors.grey.shade600,
          tabs: const [
            Tab(icon: Icon(Icons.science), text: 'Mock Test'),
            Tab(icon: Icon(Icons.assignment), text: 'DPP'),
            Tab(icon: Icon(Icons.description), text: 'PYQ Papers'),
            Tab(icon: Icon(Icons.auto_awesome), text: 'AI Practice'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 1. Mock Tests (Exam Engine)
          Consumer(
            builder: (context, ref, _) {
              final allQuestions = ref.watch(allQuestionsProvider).valueOrNull ?? [];
              final pool = ExamEngineService.validatePool(allQuestions);
              final config = ExamConfig.neet();
              if (pool.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.warning_amber_rounded, size: 64, color: Colors.orange),
                      const SizedBox(height: 16),
                      const Text('No questions available for mock test'),
                      const SizedBox(height: 8),
                      const Text('Please import questions first'),
                    ],
                  ),
                );
              }
              return CbtTestScreen(config: config, questionPool: pool);
            },
          ),
          
          // 2. DPP (Daily Practice Problems)
          const DppNeetScreen(),
          
          // 3. PYQ Papers (via Test Series / PDF Picker)
          const QuestionPaperSelector(),
          
          // 4. AI-Powered Practice
          _aiPracticeTab(context),
        ],
      ),
    );
  }

  Widget _aiPracticeTab(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'AI Practice Generator',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _PracticeCard(
            context: context,
            icon: Icons.science,
            title: 'Generate Questions',
            description: 'Get AI-generated questions on any topic',
          ),
          const SizedBox(height: 16),
          _PracticeCard(
            context: context,
            icon: Icons.book,
            title: 'Topic Deep Dive',
            description: 'Detailed explanations with NCERT references',
          ),
          const SizedBox(height: 16),
          _PracticeCard(
            context: context,
            icon: Icons.assignment,
            title: 'Mock Question Set',
            description: 'Generate a full mock test',
          ),
          const SizedBox(height: 24),
          Text(
            'Recent Practice Sessions',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          _buildRecentSession(context),
        ],
      ),
    );
  }

  Widget _buildRecentSession(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.schedule, color: Colors.blue),
        title: const Text('Yesterday - Biology: Cell Division'),
        subtitle: const Text('10 questions | 15 min'),
        trailing: IconButton(
          icon: const Icon(Icons.play_arrow),
          onPressed: () {
            // Resume session
          },
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final BuildContext context;
  final IconData icon;
  final String title;
  final String description;

  const _PracticeCard({
    Key? key,
    required this.context,
    required this.icon,
    required this.title,
    required this.description,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
          child: Icon(icon, color: theme.colorScheme.primary),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(description, style: TextStyle(color: Colors.grey.shade600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          // Handle practice selection
        },
      ),
    );
  }
}