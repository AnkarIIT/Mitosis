import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../core/providers/bootstrap_provider.dart';
import '../../core/config/app_config.dart';

import '../../core/theme/app_theme.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/mitosis_dot_matrix_background.dart';

enum AuthMode { login, signUp, forgotPassword, resetPassword, twoFactor }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  AuthMode _mode = AuthMode.login;
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _resetCodeController = TextEditingController();
  final _twoFactorController = TextEditingController();
  final _newPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _termsAccepted = false;

  String? _pendingResetEmail;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onFieldChanged);
    _passwordController.addListener(_onFieldChanged);
    _twoFactorController.addListener(_onFieldChanged);
  }

  @override
  void dispose() {
    _emailController.removeListener(_onFieldChanged);
    _passwordController.removeListener(_onFieldChanged);
    _twoFactorController.removeListener(_onFieldChanged);
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    _usernameController.dispose();
    _resetCodeController.dispose();
    _twoFactorController.dispose();
    _newPasswordController.dispose();
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
    if (_mode == AuthMode.twoFactor) {
      return _twoFactorController.text.trim().length == 6;
    }
    if (_mode == AuthMode.signUp && !_termsAccepted) return false;
    if (!_isEmailValid) return false;

    switch (_mode) {
      case AuthMode.login:
        return _passwordController.text.trim().length >= 6;
      case AuthMode.signUp:
        return _passwordController.text.trim().length >= 6;
      case AuthMode.forgotPassword:
        return true;
      case AuthMode.resetPassword:
        return _resetCodeController.text.trim().length == 6 &&
            _newPasswordController.text.trim().length >= 6;
      case AuthMode.twoFactor:
        return _twoFactorController.text.trim().length == 6;
    }
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    switch (_mode) {
      case AuthMode.login:
        await _handleLogin();
        break;
      case AuthMode.signUp:
        await _handleSignUp();
        break;
      case AuthMode.forgotPassword:
        await _handleForgotPassword();
        break;
      case AuthMode.resetPassword:
        await _handleResetPassword();
        break;
      case AuthMode.twoFactor:
        await _handleVerify2FA();
        break;
    }
  }

  Future<void> _handleVerify2FA() async {
    final code = _twoFactorController.text.trim();
    final success = await ref.read(authProvider.notifier).verifyLogin2FA(code);
    if (!mounted) return;

    if (success) {
      context.go('/');
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid or expired verification code.')),
    );
  }

  Future<void> _handleResend2FA() async {
    final success = await ref.read(authProvider.notifier).resendLogin2FA();
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success ? 'Verification code resent.' : 'Could not resend code.',
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    final success = await ref
        .read(authProvider.notifier)
        .login(email: email, password: password);

    if (success && mounted) {
      final authState = ref.read(authProvider);
      if (authState.status == AuthStatus.awaiting2FA) {
        setState(() => _mode = AuthMode.twoFactor);
        return;
      }
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

    final success = await ref
        .read(authProvider.notifier)
        .register(
          email: email,
          username: username,
          password: password,
          fullName: fullName,
        );

    if (success && mounted) {
      context.go('/');
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

    if (success) {
      setState(() {
        _pendingResetEmail = email.trim();
        _mode = AuthMode.resetPassword;
      });
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? 'Reset code sent to $email'
              : 'Could not send reset link right now. Try again later.',
        ),
      ),
    );
  }

  Future<void> _handleResetPassword() async {
    final email = _pendingResetEmail ?? _emailController.text.trim();
    final code = _resetCodeController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    final success = await ref
        .read(authProvider.notifier)
        .verifyResetCode(email: email, code: code, newPassword: newPassword);

    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _handleGuestContinue() async {
    await ref.read(authProvider.notifier).continueAsGuest();
  }

  Future<void> _handleGoogleSignIn() async {
    final success = await ref.read(authProvider.notifier).signInWithGoogle();
    if (success && mounted) context.go('/');
  }

  InputDecoration _fieldDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
    String? helperText,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      suffixIcon: suffixIcon,
      helperText: helperText,
    );
  }

  String get _title {
    switch (_mode) {
      case AuthMode.login:
        return 'Welcome back';
      case AuthMode.signUp:
        return 'Create account';
      case AuthMode.forgotPassword:
        return 'Reset password';
      case AuthMode.twoFactor:
        return 'Two-factor verification';
      case AuthMode.resetPassword:
        return 'Enter reset code';
    }
  }

  String get _subtitle {
    switch (_mode) {
      case AuthMode.login:
        return 'Sign in to continue. Your study tools work offline.';
      case AuthMode.signUp:
        return 'Create your account, then personalize your NEET study plan.';
      case AuthMode.forgotPassword:
        return 'We will send you a reset code';
      case AuthMode.twoFactor:
      case AuthMode.resetPassword:
        return 'Check your email for the 6-digit code';
    }
  }

  String? _googleSignInMessage(BootstrapStatus status) {
    if (!AppConfig.googleSignInAvailable) {
      return 'Google sign-in is not configured in this app build. Use email or guest access for now.';
    }
    switch (status) {
      case BootstrapStatus.initializing:
        return 'Preparing Google sign-in…';
      case BootstrapStatus.readyOffline:
      case BootstrapStatus.cloudUnavailable:
        return 'Google sign-in is currently unavailable. Use email or guest access.';
      case BootstrapStatus.readyWithCloud:
        return null;
    }
  }

  String get _submitLabel {
    switch (_mode) {
      case AuthMode.login:
        return 'Sign in';
      case AuthMode.signUp:
        return 'Create account';
      case AuthMode.forgotPassword:
        return 'Send reset code';
      case AuthMode.twoFactor:
        return 'Verify code';
      case AuthMode.resetPassword:
        return 'Reset password';
    }
  }

  String get _switchLabel {
    switch (_mode) {
      case AuthMode.login:
        return "Don't have an account? Sign up";
      case AuthMode.signUp:
        return 'Already have an account? Sign in';
      case AuthMode.forgotPassword:
      case AuthMode.twoFactor:
        return 'Back to sign in';
      case AuthMode.resetPassword:
        return 'Back to forgot password';
    }
  }

  void _switchMode() {
    switch (_mode) {
      case AuthMode.login:
        setState(() => _mode = AuthMode.signUp);
        break;
      case AuthMode.signUp:
      case AuthMode.forgotPassword:
      case AuthMode.twoFactor:
        setState(() => _mode = AuthMode.login);
        break;
      case AuthMode.resetPassword:
        setState(() => _mode = AuthMode.forgotPassword);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final bootstrapStatus = ref.watch(bootstrapStatusProvider);
    final isAuthLoading = authState.status == AuthStatus.loading;
    final isCloudReady = bootstrapStatus == BootstrapStatus.readyWithCloud;
    final googleSignInMessage = _googleSignInMessage(bootstrapStatus);
    final scheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AdaptiveColors.background(context),
        body: Stack(
          children: [
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: MitosisDotMatrixBackground(height: 360),
            ),
            Positioned(
              top: 280,
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.45),
                  ),
                  boxShadow: AppShadows.raised(AdaptiveColors.isDark(context)),
                ),
              ),
            ),
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                child: Form(
                  key: _formKey,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: AutofillGroup(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const SizedBox(height: 28),
                            SizedBox(
                              height: 226,
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.asset(
                                      'assets/images/mitos-app-icon-1024.png',
                                      width: 52,
                                      height: 52,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    'NEET Mitos',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 30,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'A calmer way to prepare for NEET.',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.78,
                                      ),
                                      fontSize: 14,
                                      letterSpacing: 0.15,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ),
                            Text(
                              _title,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _subtitle,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AdaptiveColors.textSecondary(
                                      context,
                                    ),
                                  ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 28),
                            if (_mode != AuthMode.resetPassword) ...[
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                autofillHints: const [AutofillHints.email],
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Email',
                                  icon: Icons.email_outlined,
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().isEmpty ||
                                      !value.contains('@')) {
                                    return 'Enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_mode == AuthMode.signUp) ...[
                              TextFormField(
                                controller: _fullNameController,
                                autofillHints: const [AutofillHints.name],
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Full Name',
                                  icon: Icons.person_outline,
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _usernameController,
                                autofillHints: const [AutofillHints.username],
                                textInputAction: TextInputAction.next,
                                decoration: _fieldDecoration(
                                  label: 'Username',
                                  icon: Icons.alternate_email,
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_mode != AuthMode.forgotPassword &&
                                _mode != AuthMode.resetPassword &&
                                _mode != AuthMode.twoFactor) ...[
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                autofillHints: _mode == AuthMode.signUp
                                    ? const [AutofillHints.newPassword]
                                    : const [AutofillHints.password],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (_canSubmit && !isAuthLoading) {
                                    _handleSubmit();
                                  }
                                },
                                decoration: _fieldDecoration(
                                  label: 'Password',
                                  icon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_mode == AuthMode.login)
                              Align(
                                alignment: Alignment.centerRight,
                                child: TextButton(
                                  onPressed: isAuthLoading
                                      ? null
                                      : () => setState(
                                          () => _mode = AuthMode.forgotPassword,
                                        ),
                                  child: const Text('Forgot password?'),
                                ),
                              ),
                            if (_mode == AuthMode.resetPassword) ...[
                              TextFormField(
                                controller: _resetCodeController,
                                keyboardType: TextInputType.number,
                                autofillHints: const [
                                  AutofillHints.oneTimeCode,
                                ],
                                textInputAction: TextInputAction.next,
                                maxLength: 6,
                                decoration: _fieldDecoration(
                                  label: 'Reset Code',
                                  icon: Icons.pin_outlined,
                                  helperText:
                                      'Check your email for the 6-digit code',
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length != 6) {
                                    return 'Enter the 6-digit code';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: _obscurePassword,
                                autofillHints: const [
                                  AutofillHints.newPassword,
                                ],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (_canSubmit && !isAuthLoading) {
                                    _handleSubmit();
                                  }
                                },
                                decoration: _fieldDecoration(
                                  label: 'New Password',
                                  icon: Icons.lock_outline,
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                    ),
                                    onPressed: () => setState(
                                      () =>
                                          _obscurePassword = !_obscurePassword,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            if (_mode == AuthMode.twoFactor) ...[
                              TextFormField(
                                controller: _twoFactorController,
                                keyboardType: TextInputType.number,
                                autofillHints: const [
                                  AutofillHints.oneTimeCode,
                                ],
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) {
                                  if (_canSubmit && !isAuthLoading) {
                                    _handleSubmit();
                                  }
                                },
                                maxLength: 6,
                                decoration: _fieldDecoration(
                                  label: 'Verification Code',
                                  icon: Icons.pin_outlined,
                                  helperText:
                                      'Check your email for the 6-digit code',
                                ),
                                validator: (value) {
                                  if (value == null ||
                                      value.trim().length != 6) {
                                    return 'Enter the 6-digit code';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 8),
                              TextButton.icon(
                                onPressed: isAuthLoading
                                    ? null
                                    : _handleResend2FA,
                                icon: const Icon(Icons.refresh_rounded),
                                label: const Text('Resend code'),
                              ),
                              const SizedBox(height: 8),
                            ],
                            if (_mode == AuthMode.signUp) ...[
                              Row(
                                children: [
                                  Checkbox(
                                    value: _termsAccepted,
                                    onChanged: (value) {
                                      setState(
                                        () => _termsAccepted = value ?? false,
                                      );
                                    },
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () => setState(
                                        () => _termsAccepted = !_termsAccepted,
                                      ),
                                      child: RichText(
                                        text: TextSpan(
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color:
                                                    AdaptiveColors.textSecondary(
                                                      context,
                                                    ),
                                              ),
                                          children: [
                                            const TextSpan(
                                              text: 'I agree to the ',
                                            ),
                                            TextSpan(
                                              text: 'Terms',
                                              style: TextStyle(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () =>
                                                    context.push('/terms'),
                                            ),
                                            const TextSpan(text: ' and '),
                                            TextSpan(
                                              text: 'Privacy Policy',
                                              style: TextStyle(
                                                color: scheme.primary,
                                                fontWeight: FontWeight.w600,
                                                decoration:
                                                    TextDecoration.underline,
                                              ),
                                              recognizer: TapGestureRecognizer()
                                                ..onTap = () =>
                                                    context.push('/privacy'),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 16),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: _canSubmit && !isAuthLoading
                                    ? _handleSubmit
                                    : null,
                                child: isAuthLoading
                                    ? SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: scheme.onPrimary,
                                        ),
                                      )
                                    : Text(_submitLabel),
                              ),
                            ),
                            if (_mode == AuthMode.login ||
                                _mode == AuthMode.signUp) ...[
                              if (AppConfig.googleSignInAvailable) ...[
                                const SizedBox(height: 12),
                                OutlinedButton.icon(
                                  onPressed:
                                      isAuthLoading ||
                                          !isCloudReady ||
                                          (_mode == AuthMode.signUp &&
                                              !_termsAccepted)
                                      ? null
                                      : _handleGoogleSignIn,
                                  icon: const Icon(
                                    Icons.account_circle_outlined,
                                  ),
                                  label: const Text('Continue with Google'),
                                ),
                              ],
                              if (googleSignInMessage != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  googleSignInMessage,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: AdaptiveColors.textSecondary(
                                          context,
                                        ),
                                      ),
                                ),
                              ],
                            ],
                            const SizedBox(height: 8),
                            Center(
                              child: TextButton(
                                onPressed: isAuthLoading ? null : _switchMode,
                                child: Text(_switchLabel),
                              ),
                            ),
                            if (authState.error != null) ...[
                              const SizedBox(height: 8),
                              Text(
                                authState.error!,
                                style: TextStyle(
                                  color: AdaptiveColors.error(context),
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: isAuthLoading
                                  ? null
                                  : _handleGuestContinue,
                              child: const Text('Continue as Guest'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
