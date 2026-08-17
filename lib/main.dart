import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/database/question_repository.dart';
import 'core/providers/providers.dart' as app_providers;
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/services/biometric_service.dart';
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await NotificationService().init().timeout(
      const Duration(seconds: 5),
      onTimeout: () => debugPrint('⚠️ Notification Service Timeout'),
    );

    if (AppConfig.isCloudAuthConfigured) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        anonKey: AppConfig.supabaseAnonKey,
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Supabase Timeout'),
      );
    }
  } catch (e) {
    debugPrint('❌ Initialization Error: $e');
  }

  final container = ProviderContainer();

  runApp(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));

  _backgroundInit(container);
}

Future<void> _backgroundInit(ProviderContainer container) async {
  try {
    final repository = container.read(questionRepositoryProvider);
    await repository.importBundledQuestions('assets/questions/neet_sample_10.json');
    await repository.insertSampleQuestions();
    debugPrint('Background seeding complete');
  } catch (e) {
    debugPrint('Background seeding failed: $e');
  }

  try {
    final contentSync = container.read(
      app_providers.contentSyncServiceProvider,
    );
    await contentSync.syncCatalog();
    container.invalidate(app_providers.allQuestionsProvider);
    debugPrint('Content catalog sync complete');
  } catch (e) {
    debugPrint('Content catalog sync failed: $e');
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  bool _needsBiometric = false;

  @override
  void initState() {
    super.initState();
    _checkBiometricLock();
  }

  Future<void> _checkBiometricLock() async {
    final bioService = BiometricService();
    final isEnabled = await bioService.isBiometricEnabled();

    if (isEnabled) {
      setState(() => _needsBiometric = true);
      final success = await bioService.authenticate();
      if (success) {
        setState(() => _needsBiometric = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(app_providers.themeProvider);

    if (_needsBiometric) {
      return MaterialApp(
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: Colors.blue),
                const SizedBox(height: 24),
                const Text('App Locked',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _checkBiometricLock,
                  child: const Text('UNLOCK WITH BIOMETRICS'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return MaterialApp.router(
      title: 'NEET Mitos Free',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
