import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/models/study_resource.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/database/drift_database.dart';
import '../../core/providers/current_user_provider.dart';

class ResourcesScreen extends ConsumerStatefulWidget {
  const ResourcesScreen({super.key});

  @override
  ConsumerState<ResourcesScreen> createState() => _ResourcesScreenState();
}

class _ResourcesScreenState extends ConsumerState<ResourcesScreen> {
  String _subject = 'All';
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final progress =
        ref.watch(resourceProgressProvider).valueOrNull ?? const {};
    final resources =
        ref.watch(studyResourcesProvider).where((resource) {
          final subjectMatches =
              _subject == 'All' || resource.subject == _subject;
          final query = _query.trim().toLowerCase();
          return subjectMatches &&
              (query.isEmpty ||
                  resource.chapterTitle.toLowerCase().contains(query) ||
                  resource.title.toLowerCase().contains(query));
        }).toList()..sort((a, b) {
          final aOpened = progress[a.id]?.lastOpenedAt;
          final bOpened = progress[b.id]?.lastOpenedAt;
          if (aOpened == null && bOpened == null) return 0;
          if (aOpened == null) return 1;
          if (bOpened == null) return -1;
          return bOpened.compareTo(aOpened);
        });

    return Scaffold(
      backgroundColor: AdaptiveColors.background(context),
      appBar: AppBar(
        title: const Text('Study Resources'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: TextField(
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search chapters',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: AdaptiveColors.surface(context),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              children: ['All', 'Biology', 'Physics', 'Chemistry'].map((
                subject,
              ) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(subject),
                    selected: _subject == subject,
                    onSelected: (_) => setState(() => _subject = subject),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: resources.isEmpty
                ? const Center(child: Text('No resources found'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: resources.length,
                    itemBuilder: (context, index) =>
                        _resourceCard(context, resources[index], progress),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _resourceCard(
    BuildContext context,
    StudyResource resource,
    Map<String, ResourceProgressData> progress,
  ) {
    final state = progress[resource.id];
    final userId = ref.read(currentLocalUserIdProvider);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0x1A4F46E5),
          child: Icon(
            resource.type == StudyResourceType.pyqSet
                ? Icons.quiz
                : resource.type == StudyResourceType.diagramSheet
                ? Icons.account_tree
                : resource.type == StudyResourceType.formulaSheet
                ? Icons.functions
                : Icons.edit_note,
            color: AppColors.primary,
          ),
        ),
        title: Text(
          resource.chapterTitle,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          '${resource.subject} • ${resource.classLevel}\n'
          '${resource.source} • ${_resourceLabel(resource)}',
        ),
        isThreeLine: true,
        trailing: IconButton(
          tooltip: state?.isBookmarked == true
              ? 'Remove bookmark'
              : 'Bookmark resource',
          icon: Icon(
            state?.isBookmarked == true
                ? Icons.bookmark
                : Icons.bookmark_border,
          ),
          onPressed: userId == null
              ? null
              : () async {
                  final database = ref.read(databaseProvider);
                  await database.upsertResourceProgress(
                    ResourceProgressCompanion.insert(
                      userId: userId,
                      resourceId: resource.id,
                      chapterId: Value(resource.chapterId),
                      isBookmarked: Value(!(state?.isBookmarked ?? false)),
                      lastOpenedAt: Value(state?.lastOpenedAt),
                      lastPage: Value(state?.lastPage),
                      progressPercent: Value(state?.progressPercent ?? 0),
                    ),
                  );
                  ref.invalidate(resourceProgressProvider);
                },
        ),
        onTap: () async {
          if (userId != null) {
            await ref
                .read(databaseProvider)
                .upsertResourceProgress(
                  ResourceProgressCompanion.insert(
                    userId: userId,
                    resourceId: resource.id,
                    chapterId: Value(resource.chapterId),
                    lastOpenedAt: Value(DateTime.now()),
                    lastPage: Value(state?.lastPage),
                    progressPercent: Value(state?.progressPercent ?? 0),
                    isBookmarked: Value(state?.isBookmarked ?? false),
                  ),
                );
            ref.invalidate(resourceProgressProvider);
          }
          if (!context.mounted) return;
          if (resource.type == StudyResourceType.ncertPdf) {
            context.push(
              '/pdf?entryId=${Uri.encodeComponent(resource.assetPath!)}',
            );
          } else if (resource.chapterId != null) {
            context.push(
              '/resources/notes?chapterId=${Uri.encodeComponent(resource.chapterId!)}',
            );
          }
        },
      ),
    );
  }

  String _resourceLabel(StudyResource resource) {
    switch (resource.type) {
      case StudyResourceType.ncertPdf:
        return 'Available offline';
      case StudyResourceType.mitosisNotes:
        return 'Original notes';
      case StudyResourceType.revisionSheet:
        return 'One-page revision';
      case StudyResourceType.formulaSheet:
        return resource.subject == 'Biology' ? 'Fact sheet' : 'Formula sheet';
      case StudyResourceType.pyqSet:
        return 'Chapter practice';
      case StudyResourceType.diagramSheet:
        return 'Diagram and flow revision';
    }
  }
}
