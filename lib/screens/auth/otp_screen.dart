import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/otp_service.dart';
import '../../theme/app_colors.dart';
import 'reset_password_screen.dart';
import 'widgets/animated_background.dart';
import 'widgets/animated_brand_mark.dart';
import 'widgets/animated_primary_button.dart';
import 'widgets/auth_helpers.dart';
import 'widgets/otp_input.dart';
import 'widgets/resend_timer.dart';

class OtpScreen extends StatefulWidget {
  final String email;

  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen>
    with SingleTickerProviderStateMixin {
  final _otpKey   = GlobalKey<OtpInputState>();
  final _timerKey = GlobalKey<ResendTimerState>();

  bool _ready   = false;
  bool _loading = false;
  bool _locked  = false;

  // Entrance animation (A18)
  late final AnimationController _entranceCtrl;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700))
      ..forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    super.dispose();
  }

  // ── Verify ──────────────────────────────────────────────────────────────────

  Future<void> _verify() async {
    if (!_ready || _loading || _locked) return;
    final code = _otpKey.currentState?.code ?? '';
    if (code.length < 6) return;

    setState(() => _loading = true);

    try {
      final result = await OtpService.verifyOtp(widget.email, code);

      if (!mounted) return;
      setState(() => _loading = false);

      if (result.success) {
        // ── Correct code ──────────────────────────────────────────────────
        _otpKey.currentState?.triggerSuccess();
        await Future.delayed(const Duration(milliseconds: 700));
        if (!mounted) return;

        // Sign the user into Firebase using the custom token returned by the worker.
        // This allows ResetPasswordScreen to call user.updatePassword() directly.
        await FirebaseAuth.instance.signInWithCustomToken(result.customToken!);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          authFadeSlide(ResetPasswordScreen(email: widget.email)),
        );
      } else {
        // ── Wrong code ────────────────────────────────────────────────────
        _otpKey.currentState?.triggerShake();
        setState(() => _ready = false);

        if (result.attemptsLeft <= 0) {
          setState(() => _locked = true);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Too many tries. Please request a new code.'),
              backgroundColor: AppColors.red,
            ));
          }
        }
      }
    } on OtpException catch (e) {
      if (!mounted) return;
      setState(() { _loading = false; _ready = false; _locked = true; });
      _otpKey.currentState?.triggerShake();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(e.message, style: const TextStyle(color: AppColors.red)),
        backgroundColor: AppColors.red.withValues(alpha: 0.15),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _ready = false; });
      _otpKey.currentState?.triggerShake();
    }
  }

  Future<void> _resend() async {
    try {
      await OtpService.sendOtp(widget.email);
    } catch (_) {}
    _otpKey.currentState?.clear();
    setState(() { _ready = false; _locked = false; });
  }

  // ── Build ───────────────────────────────────────────────────────────────────

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
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const AnimatedBrandMark(),
                  const SizedBox(height: 18),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Verify your email',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),

                  Align(
                    alignment: Alignment.centerLeft,
                    child: RichText(
                      text: TextSpan(
                        style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5),
                        children: [
                          const TextSpan(text: 'We sent a 6-digit code to\n'),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // OTP input boxes (A18 entrance)
                  AnimatedBuilder(
                    animation: _entranceCtrl,
                    builder: (_, child) => Transform.translate(
                      offset: Offset(
                          0,
                          20 *
                              (1 -
                                  CurvedAnimation(
                                    parent: _entranceCtrl,
                                    curve: Curves.easeOutQuint,
                                  ).value)),
                      child: Opacity(
                        opacity: _entranceCtrl.value.clamp(0.0, 1.0),
                        child: child,
                      ),
                    ),
                    child: OtpInput(
                      key: _otpKey,
                      onCompleted: (code) {
                        setState(() => _ready = true);
                        Future.delayed(
                            const Duration(milliseconds: 200), _verify);
                      },
                      onChanged: (code) =>
                          setState(() => _ready = code.length == 6),
                    ),
                  ),
                  const SizedBox(height: 28),

                  ResendTimer(
                    key: _timerKey,
                    totalSeconds: 60,
                    onResend: _resend,
                  ),
                  const SizedBox(height: 28),

                  AnimatedPrimaryButton(
                    label: 'Verify',
                    onPressed: (_ready && !_locked) ? _verify : null,
                  ),
                  const SizedBox(height: 24),

                  AuthSwitchLink(
                    prefix: 'Wrong email? ',
                    action: 'Go back',
                    onTap: () => Navigator.pop(context),
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
