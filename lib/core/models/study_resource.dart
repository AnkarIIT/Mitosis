enum StudyResourceType {
  ncertPdf,
  mitosisNotes,
  revisionSheet,
  formulaSheet,
  diagramSheet,
  pyqSet,
}

class StudyResource {
  final String id;
  final String title;
  final String subject;
  final String classLevel;
  final String? chapterId;
  final String chapterTitle;
  final StudyResourceType type;
  final String source;
  final String? assetPath;
  final String? externalUrl;
  final bool offlineAvailable;

  const StudyResource({
    required this.id,
    required this.title,
    required this.subject,
    required this.classLevel,
    required this.chapterId,
    required this.chapterTitle,
    required this.type,
    required this.source,
    this.assetPath,
    this.externalUrl,
    required this.offlineAvailable,
  });
}
