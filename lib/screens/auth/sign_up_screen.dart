import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../main_shell.dart';
import 'sign_in_screen.dart';
import 'widgets/animated_background.dart';
import 'widgets/animated_brand_mark.dart';
import 'widgets/animated_primary_button.dart';
import 'widgets/auth_helpers.dart';
import 'widgets/auth_input_field.dart';
import 'widgets/google_sign_in_button.dart';
import 'widgets/password_strength_meter.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    return name.length >= 2 &&
        RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email) &&
        pass.length >= 8;
  }

  Future<void> _signUp() async {
    try {
      final cred =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // Update display name in Firebase Auth
      await cred.user?.updateDisplayName(_nameCtrl.text.trim());

      // Write user document to Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set({
        'uid': cred.user!.uid,
        'displayName': _nameCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
        'lastSignIn': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShell()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (mounted) _showError(_mapError(e));
      rethrow;
    }
  }

  String _mapError(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'That email is already registered';
      case 'invalid-email':
        return 'Enter a valid email address';
      case 'weak-password':
        return 'Password is too weak — try a stronger one';
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

  void _goSignIn() => Navigator.pushReplacement(
      context, authFadeSlide(const SignInScreen()));

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
                    'Host your first session',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Free forever. No card, no nonsense.',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        height: 1.5),
                  ),
                  const SizedBox(height: 18),

                  // Name
                  AuthInputField(
                    label: 'Your name',
                    hint: 'What players will see',
                    prefixIcon: Icons.person_outline,
                    controller: _nameCtrl,
                    entranceIndex: 0,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // Email
                  AuthInputField(
                    label: 'Email',
                    hint: 'you@gmail.com',
                    prefixIcon: Icons.mail_outline,
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    entranceIndex: 1,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // Password
                  AuthInputField(
                    label: 'Password',
                    hint: 'At least 8 characters',
                    prefixIcon: Icons.lock_outline,
                    controller: _passCtrl,
                    obscureText: _obscure,
                    entranceIndex: 2,
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

                  // Strength meter
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: _passCtrl,
                    builder: (_, __) => PasswordStrengthMeter(
                        password: _passCtrl.text),
                  ),

                  const SizedBox(height: 18),
                  AnimatedPrimaryButton(
                    label: 'Create account',
                    onPressed: _canSubmit ? _signUp : null,
                  ),

                  if (kEnableGoogleSignIn) ...[
                    const SizedBox(height: 14),
                    const AuthDivider(label: 'or'),
                    const SizedBox(height: 14),
                    const GoogleSignInButton(label: 'Sign up with Google'),
                  ],

                  const SizedBox(height: 24),
                  Center(
                    child: AuthSwitchLink(
                      prefix: 'Already have one? ',
                      action: 'Sign in',
                      onTap: _goSignIn,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Terms fine print
                  Center(
                    child: Text(
                      'By creating an account you agree to the Terms\nand Privacy Policy.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 10,
                          height: 1.6),
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
