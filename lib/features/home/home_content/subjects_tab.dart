import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme.dart';
import 'package:go_router/go_router.dart';

class SubjectsTab extends ConsumerWidget {
  const SubjectsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: const Text('Subjects'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: IconThemeData(color: AdaptiveColors.textPrimary(context)),
        titleTextStyle: TextStyle(
          color: AdaptiveColors.textPrimary(context),
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
        ],
      ),
      body: subjects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: AppColors.secondary.withValues(alpha: 0.4),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No subjects available',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.secondary.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
            )
          : GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: subjects.length,
              itemBuilder: (context, index) {
                final subject = subjects[index];
                final subjectStats = ref.watch(subjectStatsProvider(subject.name));
                final accuracy = subjectStats['accuracy'] as double;
                final chapterCount = subject.chapters.length;

                return GestureDetector(
                  onTap: () {
                    context.push('/subjects', extra: {'subjectId': subject.id, 'subjectName': subject.name});
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _getSubjectColor(subject.id).withValues(alpha: 0.95),
                          _getSubjectColor(subject.id).withValues(alpha: 0.65),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _getSubjectColor(subject.id).withValues(alpha: 0.2),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          context.push('/subjects', extra: {'subjectId': subject.id, 'subjectName': subject.name});
                        },
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subject.icon,
                                          style: const TextStyle(fontSize: 28),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          subject.name,
                                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                            color: AppColors.textLight,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: AppColors.secondary.withValues(alpha: 0.3),
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '$accuracy%',
                                          style: const TextStyle(
                                            color: AppColors.textLight,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        '$chapterCount chapters',
                                        style: const TextStyle(
                                          color: AppColors.textLight,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  Color _getSubjectColor(String subjectId) {
    switch (subjectId.toLowerCase()) {
      case 'biology':
        return AppColors.biologyAccent;
      case 'chemistry':
        return AppColors.chemistryAccent;
      case 'physics':
        return AppColors.physicsAccent;
      default:
        return AppColors.primary;
    }
  }
}
