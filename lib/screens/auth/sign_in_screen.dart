import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../main_shell.dart';
import 'forgot_password_screen.dart';
import 'sign_up_screen.dart';
import 'widgets/animated_background.dart';
import 'widgets/animated_brand_mark.dart';
import 'widgets/animated_primary_button.dart';
import 'widgets/auth_helpers.dart';
import 'widgets/auth_input_field.dart';
import 'widgets/google_sign_in_button.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) &&
        pass.length >= 6;
  }

  Future<void> _signIn() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_mapError(e));
      rethrow; // Let button know it failed → resets to idle
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email or password';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      case 'network-request-failed':
        return 'Check your connection';
      default:
        return e.message ?? 'Something went wrong';
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: AppColors.red)),
      backgroundColor: AppColors.red.withValues(alpha: 0.15),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  void _goForgot() => Navigator.push(context,
      authFadeSlide(const ForgotPasswordScreen()));

  void _goSignUp() => Navigator.pushReplacement(context,
      authFadeSlide(const SignUpScreen()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Center(child: AnimatedBrandMark()),
                  const SizedBox(height: 18),
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Sign in to keep tracking your sessions',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                  const SizedBox(height: 18),

                  // Email
                  AuthInputField(
                    label: 'Email',
                    hint: 'you@gmail.com',
                    prefixIcon: Icons.mail_outline,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    entranceIndex: 0,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  AuthInputField(
                    label: 'Password',
                    hint: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    controller: _passCtrl,
                    obscureText: _obscure,
                    entranceIndex: 1,
                    onChanged: (_) => setState(() {}),
                    suffixIcon: GestureDetector(
                      onTap: () => setState(() => _obscure = !_obscure),
                      child: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: AppColors.textMuted,
                        size: 18,
                      ),
                    ),
                  ),

                  // Forgot password link
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: _goForgot,
                      child: const Text(
                        'Forgot password?',
                        style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  AnimatedPrimaryButton(
                    label: 'Sign in',
                    onPressed: _canSubmit ? _signIn : null,
                  ),

                  if (kEnableGoogleSignIn) ...[
                    const SizedBox(height: 14),
                    const AuthDivider(label: 'or continue with'),
                    const SizedBox(height: 14),
                    const GoogleSignInButton(label: 'Continue with Google'),
                  ],

                  const SizedBox(height: 32),
                  Center(
                    child: AuthSwitchLink(
                      prefix: 'New here? ',
                      action: 'Create account',
                      onTap: _goSignUp,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

