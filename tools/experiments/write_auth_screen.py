content = r"""import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';

enum AuthMode { login, signUp, forgotPassword, resetPassword }

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
  final _newPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _termsAccepted = false;

  String? _pendingResetEmail;

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
    _resetCodeController.dispose();
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
    if (!_termsAccepted) return false;
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
    }
  }

  Future<void> _handleLogin() async {
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

    final success = await ref.read(authProvider.notifier).verifyResetCode(
          email: email,
          code: code,
          newPassword: newPassword,
        );

    if (success && mounted) {
      context.go('/');
    }
  }

  Future<void> _handleGuestContinue() async {
    await ref.read(authProvider.notifier).continueAsGuest();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isAuthLoading = authState.status == AuthStatus.loading;

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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.school_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _mode == AuthMode.login
                        ? 'Welcome back'
                        : _mode == AuthMode.signUp
                            ? 'Create account'
                            : _mode == AuthMode.forgotPassword
                                ? 'Reset password'
                                : 'Enter reset code',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _mode == AuthMode.login
                        ? 'Sign in to sync your progress across devices'
                        : _mode == AuthMode.signUp
                            ? 'Start your NEET prep journey'
                            : _mode == AuthMode.forgotPassword
                                ? 'We will send you a reset code'
                                : 'Check your email for the 6-digit code',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  if (_mode != AuthMode.resetPassword) ...[
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty || !value.contains('@')) {
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
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_mode == AuthMode.signUp) ...[
                    TextFormField(
                      controller: _usernameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.alternate_email, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_mode != AuthMode.forgotPassword && _mode != AuthMode.resetPassword) ...[
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (_mode == AuthMode.resetPassword) ...[
                    TextFormField(
                      controller: _resetCodeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Reset Code',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.pin_outlined, color: Colors.white70),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length != 6) {
                          return 'Enter the 6-digit code';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _newPasswordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.white70,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                  Row(
                    children: [
                      Checkbox(
                        value: _termsAccepted,
                        onChanged: (value) {
                          setState(() => _termsAccepted = value ?? false);
                        },
                        fillColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return Colors.white;
                          }
                          return Colors.white.withValues(alpha: 0.3);
                        }),
                        checkColor: AppColors.primary,
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _termsAccepted = !_termsAccepted),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12),
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms',
                                  style: const TextStyle(decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => context.push('/terms'),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(decoration: TextDecoration.underline),
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () => context.push('/privacy'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _canSubmit && !isAuthLoading ? _handleSubmit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      child: isAuthLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                            )
                          : Text(
                              _mode == AuthMode.login
                                  ? 'SIGN IN'
                                  : _mode == AuthMode.signUp
                                      ? 'CREATE ACCOUNT'
                                      : _mode == AuthMode.forgotPassword
                                          ? 'SEND RESET CODE'
                                          : 'RESET PASSWORD',
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: isAuthLoading
                          ? null
                          : () {
                              switch (_mode) {
                                case AuthMode.login:
                                  setState(() => _mode = AuthMode.signUp);
                                  break;
                                case AuthMode.signUp:
                                  setState(() => _mode = AuthMode.login);
                                  break;
                                case AuthMode.forgotPassword:
                                  setState(() => _mode = AuthMode.login);
                                  break;
                                case AuthMode.resetPassword:
                                  setState(() => _mode = AuthMode.forgotPassword);
                                  break;
                              }
                            },
                      child: Text(
                        _mode == AuthMode.login
                            ? 'Don\'t have an account? Sign up'
                            : _mode == AuthMode.signUp
                                ? 'Already have an account? Sign in'
                                : _mode == AuthMode.forgotPassword
                                    ? 'Back to sign in'
                                    : 'Back to forgot password',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                      ),
                    ),
                  ),
                  if (_mode == AuthMode.login) ...[
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: isAuthLoading
                            ? null
                            : () => setState(() => _mode = AuthMode.forgotPassword),
                        child: Text(
                          'Forgot password?',
                          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  if (authState.error != null)
                    Center(
                      child: Text(
                        authState.error!,
                        style: const TextStyle(color: Colors.redAccent, fontSize: 13),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    onPressed: isAuthLoading ? null : _handleGuestContinue,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.white.withValues(alpha: 0.4)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text(
                      'Continue as Guest',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
"""
with open('lib/features/auth/auth_screen.dart', 'w') as f:
    f.write(content)
print('done', len(content))
