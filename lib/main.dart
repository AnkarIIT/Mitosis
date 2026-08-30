import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

import 'core/config/app_config.dart';
import 'core/database/question_repository.dart';
import 'core/providers/providers.dart' as app_providers;
import 'core/providers/settings_providers.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/app_colors.dart';
import 'core/constants/starter_flashcards.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    debugPrint('⚠️ .env not loaded: $e');
  }

  // Initialize notification service with timeout
  try {
    await NotificationService().init().timeout(
      const Duration(seconds: 5),
      onTimeout: () => debugPrint('⚠️ Notification Service Timeout'),
    );
  } catch (e) {
    debugPrint('❌ Initialization Error: $e');
  }

  final container = ProviderContainer();

  // Preload onboarding flag so GoRouter redirect stays synchronous.
  try {
    final prefs = await SharedPreferences.getInstance();
    container.read(onboardingCompleteProvider.notifier).state =
        prefs.getBool('onboarding_complete') ?? false;
  } catch (e) {
    debugPrint('❌ Onboarding preload failed: $e');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );

  // Defer Supabase initialization to background (non-blocking)
  _initSupabaseBackground(container);
  _backgroundInit(container);
}

Future<void> _initSupabaseBackground(ProviderContainer container) async {
  if (!AppConfig.enableCloudAuth) return;
  
  try {
    final url = AppConfig.supabaseUrl;
    final key = AppConfig.supabaseAnonKey;
    debugPrint('🔧 Supabase URL: $url');
    debugPrint('🔧 Supabase key prefix: ${key.substring(0, key.length > 10 ? 10 : key.length)}...');
    await supabase.Supabase.initialize(
      url: url,
      publishableKey: key,
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        debugPrint('⚠️ Supabase init timeout - continuing offline');
        throw TimeoutException('Supabase init timeout');
      },
    );
    debugPrint('✅ Supabase connected: ${AppConfig.supabaseUrl}');
  } on TimeoutException {
    debugPrint('⚠️ Supabase init timeout - continuing offline');
  } catch (e) {
    debugPrint('❌ Supabase init failed: $e');
  }
}

Future<void> _backgroundInit(ProviderContainer container) async {
  try {
    final repository = container.read(questionRepositoryProvider);
    await repository.importBundledQuestions('assets/questions/neet_sample_10.json');
    await repository.insertSampleQuestions();

    // Seed starter flashcard deck if empty.
    final db = container.read(app_providers.databaseProvider);
    final existing = await db.getAllFlashcards();
    if (existing.isEmpty) {
      await db.insertFlashcardsBatch(getStarterFlashcards());
      debugPrint('Seeded ${getStarterFlashcards().length} starter flashcards');
    }

    debugPrint('Background seeding complete');
  } catch (e) {
    debugPrint('Background seeding failed: $e');
  }

  // Cloud content sync is optional and OFF by default.
  // If the user later enables cloud sync in Settings, the provider
  // will initialize Supabase and sync at that time.
  if (AppConfig.enableCloudSync) {
    try {
      final contentSync = container.read(
        app_providers.contentSyncServiceProvider,
      );
      if (contentSync != null) {
        await contentSync.syncCatalog();
        container.invalidate(app_providers.allQuestionsProvider);
        debugPrint('Content catalog sync complete');
      }
    } catch (e) {
      debugPrint('Content catalog sync failed: $e');
    }
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  bool _needsBiometric = false;
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startSplash();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startSplash() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() => _splashDone = true);
        _checkBiometricLock();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _splashDone) {
      _checkBiometricLock();
    }
  }

  Future<void> _checkBiometricLock() async {
    final bioService = ref.read(app_providers.biometricServiceProvider);
    final isEnabled = await bioService.isBiometricEnabled();
    debugPrint('🔐 Biometric lock check: enabled=$isEnabled, needsBiometric=$_needsBiometric');

    if (isEnabled && !_needsBiometric) {
      setState(() => _needsBiometric = true);
      final success = await bioService.authenticate();
      debugPrint('🔐 Biometric auth result: $success');
      if (success && mounted) {
        setState(() => _needsBiometric = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(app_providers.themeProvider);

    if (!_splashDone) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: themeMode,
        home: const _BrandedSplash(),
      );
    }

    return MaterialApp.router(
      title: 'NEET Mitos Free',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        if (_needsBiometric) {
          return _BiometricLockOverlay(
            onUnlock: () => setState(() => _needsBiometric = false),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}

class _BrandedSplash extends StatelessWidget {
  const _BrandedSplash();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.school_rounded,
                size: 48,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'NEET Mitos',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AdaptiveColors.textPrimary(context),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your NEET prep companion',
              style: TextStyle(
                fontSize: 14,
                color: AdaptiveColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BiometricLockOverlay extends ConsumerStatefulWidget {
  final VoidCallback onUnlock;

  const _BiometricLockOverlay({required this.onUnlock});

  @override
  ConsumerState<_BiometricLockOverlay> createState() =>
      _BiometricLockOverlayState();
}

class _BiometricLockOverlayState extends ConsumerState<_BiometricLockOverlay> {
  bool _authenticating = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final bioService = ref.read(app_providers.biometricServiceProvider);
    final success = await bioService.authenticate();
    debugPrint('🔐 Overlay biometric auth result: $success');

    if (mounted) {
      setState(() => _authenticating = false);
      if (success) {
        widget.onUnlock();
      } else {
        setState(() => _error = 'Authentication failed. Tap to retry.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(app_providers.themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: Scaffold(
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 48,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'App Locked',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Authenticate to continue',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 32),
                if (_authenticating)
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  SizedBox(
                    width: 220,
                    child: ElevatedButton.icon(
                      onPressed: _authenticate,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('UNLOCK'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        textStyle: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: 220,
                    child: OutlinedButton.icon(
                      onPressed: _authenticateWithDeviceCredential,
                      icon: const Icon(Icons.pin_outlined, color: Colors.white),
                      label: const Text(
                        'USE PIN',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.4),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _authenticateWithDeviceCredential() async {
    setState(() {
      _authenticating = true;
      _error = null;
    });

    final bioService = ref.read(app_providers.biometricServiceProvider);
    final success = await bioService.authenticateWithDeviceCredential();
    debugPrint('🔐 Overlay device credential auth result: $success');

    if (mounted) {
      setState(() => _authenticating = false);
      if (success) {
        widget.onUnlock();
      } else {
        setState(() => _error = 'Authentication failed. Tap to retry.');
      }
    }
  }
}
