import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import 'sign_in_screen.dart';
import 'widgets/animated_background.dart';
import 'widgets/animated_brand_mark.dart';
import 'widgets/animated_primary_button.dart';
import 'widgets/auth_helpers.dart';
import 'widgets/auth_input_field.dart';
import 'widgets/password_strength_meter.dart';
import 'widgets/success_burst.dart';

class ResetPasswordScreen extends StatefulWidget {
  /// oobCode from a Firebase password-reset deep link (optional / future use).
  final String? oobCode;

  /// Pre-fill the email for display.
  final String? email;

  const ResetPasswordScreen({super.key, this.oobCode, this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen>
    with TickerProviderStateMixin {
  // ── Form ────────────────────────────────────────────────────────────────────
  final _newCtrl     = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscureNew     = true;
  bool _obscureConfirm = true;

  // ── State ───────────────────────────────────────────────────────────────────
  bool _done = false;

  // ── Success animations ───────────────────────────────────────────────────────
  late final AnimationController _circleCtrl;
  late final AnimationController _auraCtrl;
  final _burstKey = GlobalKey<SuccessBurstState>();

  @override
  void initState() {
    super.initState();
    _circleCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _auraCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    _circleCtrl.dispose();
    _auraCtrl.dispose();
    super.dispose();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  bool get _passwordsMatch =>
      _confirmCtrl.text.isNotEmpty && _newCtrl.text == _confirmCtrl.text;

  bool get _canSubmit => strengthOf(_newCtrl.text) >= 2 && _passwordsMatch;

  // ── Submit ───────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    final newPwd = _newCtrl.text;

    try {
      if (widget.oobCode != null) {
        // ── Deep-link flow (future use) ───────────────────────────────────────
        await FirebaseAuth.instance.confirmPasswordReset(
          code: widget.oobCode!,
          newPassword: newPwd,
        );
      } else {
        // ── OTP flow OR logged-in "change password" flow ──────────────────────
        // signInWithCustomToken (called from OtpScreen) already signed the user in.
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) throw Exception('Session expired. Please start over.');
        await user.updatePassword(newPwd);

        // Update Firestore
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .update({'lastPasswordChange': FieldValue.serverTimestamp()});
      }

      if (!mounted) return;
      setState(() => _done = true);
      await _circleCtrl.forward();
      _burstKey.currentState?.play();

    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      String msg;
      switch (e.code) {
        case 'expired-action-code':
          msg = 'This link has expired. Please start over.';
        case 'invalid-action-code':
          msg = 'Invalid reset link.';
        case 'weak-password':
          msg = 'Password too weak — try a stronger one.';
        case 'requires-recent-login':
          msg = 'Session expired. Please start over.';
        default:
          msg = e.message ?? 'Something went wrong.';
      }
      _showError(msg);
      rethrow;
    } catch (e) {
      if (!mounted) return;
      _showError(e.toString());
      rethrow;
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

  // ── Navigation ───────────────────────────────────────────────────────────────

  Future<void> _onContinue() async {
    // Always sign out and return to sign-in so the user logs in with the new password.
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const SignInScreen()),
      (_) => false,
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────────

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
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0, 0.04), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: _done ? _buildSuccess() : _buildForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form state ───────────────────────────────────────────────────────────────

  Widget _buildForm() {
    return Column(
      key: const ValueKey('form'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: AnimatedBrandMark()),
        const SizedBox(height: 18),

        const Text('Create new password',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        const SizedBox(height: 4),
        const Text(
          "Pick something you haven't used before. 8 characters minimum.",
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 18),

        // New password
        AuthInputField(
          label: 'New password',
          hint: 'At least 8 characters',
          prefixIcon: Icons.lock_outline,
          controller: _newCtrl,
          obscureText: _obscureNew,
          entranceIndex: 0,
          onChanged: (_) => setState(() {}),
          suffixIcon: GestureDetector(
            onTap: () => setState(() => _obscureNew = !_obscureNew),
            child: Icon(
              _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: AppColors.textMuted,
              size: 18,
            ),
          ),
        ),

        const SizedBox(height: 8),
        AnimatedBuilder(
          animation: _newCtrl,
          builder: (_, __) => PasswordStrengthMeter(password: _newCtrl.text),
        ),
        const SizedBox(height: 14),

        // Confirm password
        AuthInputField(
          label: 'Confirm password',
          hint: 'Type it again',
          prefixIcon: Icons.lock_reset,
          controller: _confirmCtrl,
          obscureText: _obscureConfirm,
          entranceIndex: 1,
          onChanged: (_) => setState(() {}),
          suffixIcon: _confirmCtrl.text.isEmpty
              ? GestureDetector(
                  onTap: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  child: Icon(
                    _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: AppColors.textMuted,
                    size: 18,
                  ),
                )
              : AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, anim) => ScaleTransition(
                      scale: anim,
                      child: FadeTransition(opacity: anim, child: child)),
                  child: _passwordsMatch
                      ? const Icon(
                          key: ValueKey('match'),
                          Icons.check_circle,
                          color: AppColors.accent,
                          size: 18)
                      : const Icon(
                          key: ValueKey('mismatch'),
                          Icons.cancel,
                          color: AppColors.red,
                          size: 18),
                ),
        ),

        if (_confirmCtrl.text.isNotEmpty && !_passwordsMatch) ...[
          const SizedBox(height: 6),
          const Text(
            "Passwords don't match",
            style: TextStyle(
                color: AppColors.red,
                fontSize: 11,
                fontWeight: FontWeight.w500),
          ),
        ],
        const SizedBox(height: 18),

        AnimatedPrimaryButton(
          label: 'Update password',
          onPressed: _canSubmit ? _submit : null,
        ),
        const SizedBox(height: 24),

        Center(
          child: AuthSwitchLink(
            prefix: '',
            action: '← Back',
            onTap: () => Navigator.pop(context),
          ),
        ),
      ],
    );
  }

  // ── Success state ─────────────────────────────────────────────────────────────

  Widget _buildSuccess() {
    return Column(
      key: const ValueKey('success'),
      children: [
        const SizedBox(height: 40),

        Center(
          child: SuccessBurst(
            key: _burstKey,
            child: AnimatedBuilder(
              animation: Listenable.merge([_circleCtrl, _auraCtrl]),
              builder: (_, __) {
                final popScale = TweenSequence<double>([
                  TweenSequenceItem(
                      tween: Tween(begin: 0.2, end: 1.15), weight: 60),
                  TweenSequenceItem(
                      tween: Tween(begin: 1.15, end: 1.0), weight: 40),
                ]).animate(CurvedAnimation(
                        parent: _circleCtrl, curve: Curves.elasticOut))
                    .value;

                final auraSpread  = _auraCtrl.value * 28;
                final auraOpacity = 0.5 * (1 - _auraCtrl.value);

                return Transform.scale(
                  scale: popScale,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: auraOpacity),
                          blurRadius: auraSpread,
                          spreadRadius: auraSpread / 2,
                        ),
                      ],
                    ),
                    child: CustomPaint(painter: _CheckPainter()),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 32),

        const Text('Password updated!',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        const SizedBox(height: 8),
        const Text(
          'Use your new password to sign in.',
          textAlign: TextAlign.center,
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 32),

        AnimatedPrimaryButton(
          label: 'Continue to sign in',
          onPressed: _onContinue,
        ),
      ],
    );
  }
}

// ── Checkmark painter ─────────────────────────────────────────────────────────

class _CheckPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.dark
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(
      Path()
        ..moveTo(size.width * 0.22, size.height * 0.52)
        ..lineTo(size.width * 0.44, size.height * 0.72)
        ..lineTo(size.width * 0.78, size.height * 0.32),
      paint,
    );
  }

  @override
  bool shouldRepaint(_CheckPainter _) => false;
}
