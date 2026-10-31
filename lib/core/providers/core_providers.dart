import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/drift_database.dart' as db;
import '../services/ml_service.dart';
import '../services/gemini_chat_service.dart';
import '../services/ncert_text_index_service.dart';
import '../services/user_pdf_index_service.dart';
import '../services/connectivity_service.dart';
import 'service_providers.dart';

final mlServiceProvider = Provider<MLService>((ref) {
  final service = createMLService();
  service.initializeModels();
  return service;
});

final databaseProvider = Provider<db.AppDatabase>((ref) => db.AppDatabase());

final geminiServiceProvider = Provider<GeminiChatService>((ref) {
  final proxy = ref.watch(geminiProxyServiceProvider);
  final service = GeminiChatService(proxy: proxy);
  service.init();
  return service;
});

/// Lazy loader for the extracted NCERT chapter text (`assets/ncert_text/`).
/// Feeds the grounded AI tutor in the chat.
final ncertTextIndexProvider = Provider<NcertTextIndexService>(
  (ref) => NcertTextIndexService(),
);

/// Service for managing user-uploaded PDF indices (grounding source).
final userPdfIndexProvider = Provider<UserPdfIndexService>(
  (ref) => UserPdfIndexService(),
);

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService.instance;
  service.init();
  return service;
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});
