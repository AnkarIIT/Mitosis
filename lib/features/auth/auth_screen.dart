import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_config.dart';
import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum AuthMode {
  passwordLogin,
  signUp,
  otpLogin,
}

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthMode _mode = AuthMode.passwordLogin;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();

  bool _obscurePassword = true;
  bool _termsAccepted = false;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    setState(() {});
  }

  bool get _isEmailValid {
    final email = _emailController.text.trim();
    return email.isNotEmpty && email.contains('@');
  }

  bool get _canSubmit {
    if (!_termsAccepted) return false;
    if (!_isEmailValid) return false;

    switch (_mode) {
      case AuthMode.passwordLogin:
        return _passwordController.text.trim().length >= 6;
      case AuthMode.signUp:
        return _passwordController.text.trim().length >= 6;
      case AuthMode.otpLogin:
        return true;
    }
  }

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

  Future<void> _handleMicrosoftSignIn() async {
    final success = await ref.read(authProvider.notifier).signInWithMicrosoft();
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    switch (_mode) {
      case AuthMode.passwordLogin:
        await _handlePasswordLogin();
        break;
      case AuthMode.signUp:
        await _handleSignUp();
        break;
      case AuthMode.otpLogin:
        await _handleSendOtp();
        break;
    }
  }

  Future<void> _handlePasswordLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await ref.read(authProvider.notifier).login(
          email: email,
          password: password,
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _handleSignUp() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();
    final username = _usernameController.text.trim().isNotEmpty
        ? _usernameController.text.trim()
        : email.split('@').first;

    final success = await ref.read(authProvider.notifier).register(
          email: email,
          password: password,
          username: username,
          fullName: fullName,
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    final success = await ref.read(authProvider.notifier).sendOtp(email);

    if (success && mounted) {
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
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'A password reset link was sent to $email.'
              : 'Could not send reset link right now. Try again later.',
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
    final showMicrosoftButton = AppConfig.isCloudAuthConfigured;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.primary.withValues(alpha: 0.88),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                const Icon(Icons.school_rounded, size: 68, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'NEET Mitos',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Your AI-Powered NEET Partner',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 28),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(24)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Welcome',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AdaptiveColors.textPrimary(context),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sign in or create an account to sync your progress.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AdaptiveColors.textSecondary(context), fontSize: 13),
                        ),
                        const SizedBox(height: 20),

                        // Social OAuth Buttons
                        if (showGoogleButton || showMicrosoftButton) ...[
                          Column(
                            children: [
                              if (showGoogleButton) ...[
                                _GoogleSignInButton(
                                  onPressed: _handleGoogleSignIn,
                                  isLoading: isAuthLoading,
                                ),
                                const SizedBox(height: 10),
                              ],
                              if (showMicrosoftButton) ...[
                                _MicrosoftSignInButton(
                                  onPressed: _handleMicrosoftSignIn,
                                  isLoading: isAuthLoading,
                                ),
                                const SizedBox(height: 10),
                              ],
                            ],
                          ),
                          const SizedBox(height: 10),
                          const _DividerOr(),
                          const SizedBox(height: 16),
                        ],

                        // Mode Selector (Password, Sign Up, OTP)
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _ModeTabButton(
                                  label: 'Log In',
                                  isSelected: _mode == AuthMode.passwordLogin,
                                  onTap: () => setState(() => _mode = AuthMode.passwordLogin),
                                ),
                              ),
                              Expanded(
                                child: _ModeTabButton(
                                  label: 'Sign Up',
                                  isSelected: _mode == AuthMode.signUp,
                                  onTap: () => setState(() => _mode = AuthMode.signUp),
                                ),
                              ),
                              Expanded(
                                child: _ModeTabButton(
                                  label: 'OTP',
                                  isSelected: _mode == AuthMode.otpLogin,
                                  onTap: () => setState(() => _mode = AuthMode.otpLogin),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Fields according to selected Mode
                        if (_mode == AuthMode.signUp) ...[
                          TextFormField(
                            controller: _fullNameController,
                            textCapitalization: TextCapitalization.words,
                            decoration: InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: const Icon(Icons.person_outline),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              hintText: 'Rahul Sharma',
                            ),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _usernameController,
                            decoration: InputDecoration(
                              labelText: 'Username (Optional)',
                              prefixIcon: const Icon(Icons.alternate_email),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              hintText: 'rahul_neet2025',
                            ),
                          ),
                          const SizedBox(height: 14),
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

                        if (_mode != AuthMode.otpLogin) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            autofillHints: const [AutofillHints.password],
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock_outline),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                ),
                                onPressed: () {
                                  setState(() => _obscurePassword = !_obscurePassword);
                                },
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              hintText: 'Minimum 6 characters',
                            ),
                            validator: (value) {
                              final pass = value?.trim() ?? '';
                              if (pass.length < 6) {
                                return 'Password must be at least 6 characters';
                              }
                              return null;
                            },
                          ),
                        ],

                        if (_mode == AuthMode.passwordLogin) ...[
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              child: const Text('Forgot password?'),
                            ),
                          ),
                        ],

                        const SizedBox(height: 12),

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
                              style: TextStyle(
                                fontSize: 12,
                                color: AdaptiveColors.textSecondary(context),
                              ),
                            ),
                          ),

                        if (authState.error != null) ...[
                          const SizedBox(height: 12),
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
                                Icon(Icons.info_outline_rounded,
                                    size: 18, color: AppColors.chemistryAccent),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _friendlyAuthError(authState.error),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AdaptiveColors.textPrimary(context),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        // Terms & Privacy Acceptance
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Checkbox(
                              value: _termsAccepted,
                              onChanged: (value) {
                                setState(() => _termsAccepted = value ?? false);
                              },
                              activeColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 10),
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    children: [
                                      Text(
                                        'I agree to the ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AdaptiveColors.textSecondary(context),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context.push('/terms'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Terms of Service',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            decoration: TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        ' & ',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: AdaptiveColors.textSecondary(context),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => context.push('/privacy'),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: const Size(0, 0),
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                        child: const Text(
                                          'Privacy Policy',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.primary,
                                            decoration: TextDecoration.underline,
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

                        const SizedBox(height: 16),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: isAuthLoading || !_canSubmit ? null : _handleSubmit,
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
                                : Text(
                                    _mode == AuthMode.passwordLogin
                                        ? 'LOG IN'
                                        : _mode == AuthMode.signUp
                                            ? 'CREATE ACCOUNT'
                                            : 'SEND VERIFICATION OTP',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 12),

                        // Guest Skip Button
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _handleGuestContinue,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AdaptiveColors.textPrimary(context),
                              side: BorderSide(
                                color: AdaptiveColors.textSecondary(context).withValues(alpha: 0.3),
                              ),
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
    if (lower.contains('invalid login credentials') ||
        lower.contains('invalid_signin')) {
      return 'Invalid email or password. Please try again.';
    }
    if (lower.contains('user already registered') ||
        lower.contains('email already exists')) {
      return 'This email is already registered. Try logging in instead.';
    }
    if (lower.contains('too many requests') || lower.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    }
    return rawError;
  }
}

class _ModeTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? AppColors.primary : AppColors.textSubtle,
          ),
        ),
      ),
    );
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
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: AdaptiveColors.textPrimary(context),
          elevation: 0,
          side: BorderSide(
            color: AdaptiveColors.textSecondary(context).withValues(alpha: 0.25),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _GoogleIcon(),
                  const SizedBox(width: 10),
                  const Text(
                    'Continue with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _MicrosoftSignInButton extends StatelessWidget {
  final VoidCallback onPressed;
  final bool isLoading;

  const _MicrosoftSignInButton({
    required this.onPressed,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2F2F2F),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _MicrosoftIcon(),
                  const SizedBox(width: 10),
                  const Text(
                    'Continue with Microsoft',
                    style: TextStyle(
                      fontSize: 14,
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
    return SizedBox(
      width: 18,
      height: 18,
      child: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: _circle(const Color(0xFF4285F4), 9),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: _circle(const Color(0xFFEA4335), 9),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: _circle(const Color(0xFFFBBC05), 9),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: _circle(const Color(0xFF34A853), 9),
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

class _MicrosoftIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 18,
      height: 18,
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          Container(width: 8, height: 8, color: const Color(0xFFF25022)),
          Container(width: 8, height: 8, color: const Color(0xFF7FBA00)),
          Container(width: 8, height: 8, color: const Color(0xFF00A4EF)),
          Container(width: 8, height: 8, color: const Color(0xFFFFB900)),
        ],
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
            color: AdaptiveColors.textSecondary(context).withValues(alpha: 0.2),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'or continue with email',
            style: TextStyle(
              fontSize: 12,
              color: AdaptiveColors.textSecondary(context),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Divider(
            height: 1,
            thickness: 1,
            color: AdaptiveColors.textSecondary(context).withValues(alpha: 0.2),
          ),
        ),
      ],
    );
  }
}

