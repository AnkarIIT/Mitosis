import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

import 'package:go_router/go_router.dart';

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onEmailChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onEmailChanged);
    _emailController.dispose();
    super.dispose();
  }

  void _onEmailChanged() {
    setState(() {});
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return email.isNotEmpty && email.contains('@');
  }

  bool get _canContinue => _termsAccepted && _isEmailValid;

  Future<void> _handleGoogleSignIn() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (!mounted) return;

    if (!success) {
      final error = ref.read(authProvider).error;
      if (error != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleSendOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final email = _emailController.text.trim();
    final success = await ref.read(authProvider.notifier).sendOtp(email);

    if (!mounted) {
      return;
    }

    if (success) {
      context.push('/otp');
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter your email first to reset your password.'),
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).resetPassword(email);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'A free password reset link was sent to $email.'
              : 'We could not send a reset link right now. Try again later.',
        ),
      ),
    );
  }

  Future<void> _handleGuestContinue() async {
    await ref.read(authProvider.notifier).continueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthLoading = authState.status == AuthStatus.authenticating;
    final showGoogleButton = AppConfig.googleSignInAvailable;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.85),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                const Icon(Icons.school_rounded, size: 72, color: Colors.white),
                const SizedBox(height: 16),
                const Text(
                  'NEET Mitos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Your AI-Powered NEET Partner',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 15),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: AdaptiveColors.surface(context),
                    borderRadius: const BorderRadius.all(Radius.circular(28)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Get Started',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AdaptiveColors.textPrimary(context),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to sync your progress across devices.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AdaptiveColors.textSecondary(context), fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      if (showGoogleButton) ...[
                        _GoogleSignInButton(
                          onPressed: _handleGoogleSignIn,
                          isLoading: isAuthLoading,
                        ),
                        const SizedBox(height: 16),
                        const _DividerOr(),
                        const SizedBox(height: 16),
                      ],
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: InputDecoration(
                          labelText: 'Email Address',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          hintText: 'student@example.com',
                        ),
                        validator: (value) {
                          final email = value?.trim() ?? '';
                          if (email.isEmpty || !email.contains('@')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),
                      if (!AppConfig.isCloudAuthConfigured)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppConfig.cloudAuthHelpText,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSubtle,
                            ),
                          ),
                        ),
                      const SizedBox(height: 14),
                      if (authState.error != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.chemistryAccent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.chemistryAccent.withValues(alpha: 0.18),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline_rounded, size: 18, color: AppColors.chemistryAccent),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _friendlyAuthError(authState.error),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 14),
                      // Terms & Privacy checkbox
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _termsAccepted,
                            onChanged: (value) {
                              setState(() => _termsAccepted = value ?? false);
                            },
                            activeColor: AppColors.primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 12),
                                child: Wrap(
                                  alignment: WrapAlignment.start,
                                  crossAxisAlignment: WrapCrossAlignment.center,
                                  children: [
                                    Text(
                                      'I agree to the ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSubtle,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.push('/terms'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Terms of Service',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      ' & ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSubtle,
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => context.push('/privacy'),
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 0),
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Privacy Policy',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AppColors.primary,
                                          decoration: TextDecoration.underline,
                                          decorationColor: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: isAuthLoading || !_canContinue ? null : _handleSendOtp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: isAuthLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('CONTINUE WITH EMAIL'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _handleForgotPassword,
                          child: const Text('Forgot password?'),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _handleGuestContinue,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AdaptiveColors.textPrimary(context),
                            side: BorderSide(color: AdaptiveColors.textSecondary(context).withValues(alpha: 0.3)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text('SKIP FOR NOW'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _friendlyAuthError(String? rawError) {
    if (rawError == null || rawError.isEmpty) return '';
    final lower = rawError.toLowerCase();
    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('errno = 7') ||
        lower.contains('network') ||
        lower.contains('unreachable')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (lower.contains('authretryablefetchexception') ||
        lower.contains('fetch') ||
        lower.contains('http')) {
      return 'Could not reach the auth server. Try again after checking your connection.';
    }
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_signin')) {
      return 'Invalid email or password. Please try again.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('email already exists')) {
      return 'This email is already registered. Try signing in instead.';
    }
    if (lower.contains('too many requests') ||
        lower.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    if (lower.contains('google') && lower.contains('not enabled')) {
      return 'Google sign-in is unavailable right now. Please use email sign-in.';
    }
    return rawError;
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _GoogleSignInButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.textDark,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleIcon(),
                  const SizedBox(width: 12),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Simple multi-color Google "G" using a Stack of colored circles.
    // For production, replace with official Google brand asset.
    return SizedBox(
      width: 20,
      height: 20,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: _circle(Colors.blue, 10),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _circle(Colors.red, 10),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: _circle(Colors.yellow, 10),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _circle(Colors.green, 10),
          ),
        ],
      ),
    );
  }

  Widget _circle(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _DividerOr extends StatelessWidget {
  const _DividerOr();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: AppColors.textSubtle.withValues(alpha: 0.2),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSubtle,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: AppColors.textSubtle.withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}
