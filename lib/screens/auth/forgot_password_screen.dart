import 'package:flutter/material.dart';
import '../../services/otp_service.dart';
import '../../theme/app_colors.dart';
import 'otp_screen.dart';
import 'widgets/animated_background.dart';
import 'widgets/animated_primary_button.dart';
import 'widgets/auth_helpers.dart';
import 'widgets/auth_input_field.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with TickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  bool _sent = false;
  String _sentEmail = '';

  // A14 — mail icon bob
  late final AnimationController _bobCtrl;
  late final Animation<double> _bobY;

  // A15 — radiating ring
  late final AnimationController _ringCtrl;

  @override
  void initState() {
    super.initState();
    _bobCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat(reverse: true);
    _bobY = Tween<double>(begin: 0, end: -6)
        .animate(CurvedAnimation(parent: _bobCtrl, curve: Curves.easeInOut));

    _ringCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2400))
      ..repeat();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _bobCtrl.dispose();
    _ringCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    try {
      await OtpService.sendOtp(email);
    } on OtpException catch (e) {
      if (mounted) _showError(e.message);
      rethrow;
    } catch (e) {
      if (mounted) _showError('Error: ${e.runtimeType} — $e');
      rethrow;
    }
    if (mounted) setState(() { _sent = true; _sentEmail = email; });
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: AppColors.red)),
      backgroundColor: AppColors.red.withValues(alpha: 0.15),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween<Offset>(
                            begin: const Offset(0.04, 0), end: Offset.zero)
                        .animate(anim),
                    child: child,
                  ),
                ),
                child: _sent
                    ? _SentState(
                        key: const ValueKey('sent'),
                        email: _sentEmail,
                        bobY: _bobY,
                        ringCtrl: _ringCtrl,
                        onBack: () => Navigator.pop(context),
                        onTryAgain: () =>
                            setState(() { _sent = false; _emailCtrl.clear(); }),
                        onEnterCode: () => Navigator.push(
                          context,
                          authFadeSlide(OtpScreen(email: _sentEmail)),
                        ),
                      )
                    : _IdleState(
                        key: const ValueKey('idle'),
                        emailCtrl: _emailCtrl,
                        onSend: _sendCode,
                        onBack: () => Navigator.pop(context),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Idle state ────────────────────────────────────────────────────────────

class _IdleState extends StatelessWidget {
  final TextEditingController emailCtrl;
  final Future<void> Function() onSend;
  final VoidCallback onBack;

  const _IdleState({
    super.key,
    required this.emailCtrl,
    required this.onSend,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        const Text('Forgot password?',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        const SizedBox(height: 6),
        const Text(
          "Enter your email and we'll send you a 6-digit code.",
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13, height: 1.5),
        ),
        const SizedBox(height: 28),
        AuthInputField(
          label: 'Email',
          hint: 'you@gmail.com',
          prefixIcon: Icons.mail_outline,
          controller: emailCtrl,
          keyboardType: TextInputType.emailAddress,
          entranceIndex: 0,
        ),
        const SizedBox(height: 18),
        AnimatedBuilder(
          animation: emailCtrl,
          builder: (_, __) => AnimatedPrimaryButton(
            label: 'Send code',
            onPressed: emailCtrl.text.trim().isEmpty ? null : onSend,
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: onBack,
            child: const Text(
              '← Back to sign in',
              style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Sent state ────────────────────────────────────────────────────────────

class _SentState extends StatelessWidget {
  final String email;
  final Animation<double> bobY;
  final AnimationController ringCtrl;
  final VoidCallback onBack;
  final VoidCallback onTryAgain;
  final VoidCallback onEnterCode;

  const _SentState({
    super.key,
    required this.email,
    required this.bobY,
    required this.ringCtrl,
    required this.onBack,
    required this.onTryAgain,
    required this.onEnterCode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 32),
        // A14/A15 — bobbing icon + radiating ring
        AnimatedBuilder(
          animation: Listenable.merge([bobY, ringCtrl]),
          builder: (_, __) {
            final ringScale   = 1.0 + 0.6 * ringCtrl.value;
            final ringOpacity = 0.8 * (1 - ringCtrl.value);
            return SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Transform.scale(
                    scale: ringScale,
                    child: Opacity(
                      opacity: ringOpacity,
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: AppColors.accent40, width: 1),
                        ),
                      ),
                    ),
                  ),
                  Transform.translate(
                    offset: Offset(0, bobY.value),
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: const BoxDecoration(
                        color: AppColors.accent12,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_rounded,
                        color: AppColors.accent,
                        size: 36,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 28),
        const Text('Check your inbox',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2)),
        const SizedBox(height: 10),
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13, height: 1.6),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to\n'),
              TextSpan(
                text: email,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 13),
              ),
              const TextSpan(text: '\n\nEnter the code in the next screen.'),
            ],
          ),
        ),
        const SizedBox(height: 32),
        AnimatedPrimaryButton(
          label: 'Enter code →',
          onPressed: () async => onEnterCode(),
        ),
        const SizedBox(height: 12),
        Center(
          child: GestureDetector(
            onTap: onBack,
            child: const Text(
              '← Back to sign in',
              style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Didn't get it? ",
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            GestureDetector(
              onTap: onTryAgain,
              child: const Text('Resend',
                  style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
