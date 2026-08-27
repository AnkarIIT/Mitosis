import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/drift_database.dart' as db;
import '../services/ml_service.dart';
import '../services/gemini_chat_service.dart';
import '../services/connectivity_service.dart';
import 'service_providers.dart';

final mlServiceProvider = Provider<MLService>((ref) {
  final service = MLService();
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

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService.instance;
  service.init();
  return service;
});

final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});
