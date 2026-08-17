import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/app_config.dart';
import 'core/database/question_repository.dart';
import 'core/providers/providers.dart' as app_providers;
import 'core/services/notification_service.dart';
import 'core/services/biometric_service.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/otp_screen.dart';
import 'features/auth/two_factor_screen.dart';
import 'features/home/home_screen.dart';
import 'features/home/neet_home_screen.dart';
import 'features/onboarding/onboarding_screen.dart';

void main() async {
  // 1. Ensure Flutter is ready
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Wrap everything in a try-catch to prevent splash screen freeze
  try {
    // 3. Initialize background services
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

  // 4. Run the app IMMEDIATELY
  runApp(UncontrolledProviderScope(
    container: container,
    child: const MyApp(),
  ));

  // 5. Seed questions in the background
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

  // Pull the published Supabase content catalog (if configured) so the test
  // engine has the latest questions available offline.
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
  bool _isAuthenticated = false;
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
        setState(() {
          _isAuthenticated = true;
          _needsBiometric = false;
        });
      }
    } else {
      setState(() => _isAuthenticated = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(app_providers.themeProvider);
    final authState = ref.watch(app_providers.authProvider);
    final usePremiumHome = ref.watch(app_providers.usePremiumHomeProvider);

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
                const Text('App Locked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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

    return MaterialApp(
      title: 'NEET Mitos Free',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: _isAuthenticated ? _getHome(authState, usePremiumHome) : const SizedBox(),
    );
  }

  Widget _getHome(app_providers.AuthState authState, bool usePremiumHome) {
    if (authState.status == app_providers.AuthStatus.loading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Starting NEET Mitos...'),
            ],
          ),
        ),
      );
    }
    
    if (authState.status == app_providers.AuthStatus.awaiting2FA) {
      return const TwoFactorScreen();
    }

    if (authState.status == app_providers.AuthStatus.awaitingOtp) {
      return const OtpScreen();
    }

    if (authState.status == app_providers.AuthStatus.authenticated) {
      return FutureBuilder<bool>(
        future: _checkOnboarding(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.data == true) {
            return usePremiumHome ? const NeetHomeScreen() : const HomeScreen();
          }
          return const OnboardingScreen();
        },
      );
    }

    return const AuthScreen();
  }

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_complete') ?? false;
  }
}
