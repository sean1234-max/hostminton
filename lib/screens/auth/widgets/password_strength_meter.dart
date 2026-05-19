import 'package:flutter/material.dart';
import '../../../theme/app_colors.dart';

int strengthOf(String pwd) {
  var s = 0;
  if (pwd.length >= 8) s++;
  if (RegExp(r'[A-Z]').hasMatch(pwd) && RegExp(r'[a-z]').hasMatch(pwd)) s++;
  if (RegExp(r'\d').hasMatch(pwd)) s++;
  if (RegExp(r'[^A-Za-z0-9]').hasMatch(pwd)) s++;
  return s.clamp(0, 4);
}

Color _colorFor(int strength) {
  switch (strength) {
    case 1:
      return AppColors.red;
    case 2:
    case 3:
      return AppColors.orange;
    case 4:
      return AppColors.accent;
    default:
      return AppColors.border;
  }
}

String _labelFor(int strength) {
  switch (strength) {
    case 1:
      return 'WEAK';
    case 2:
      return 'FAIR';
    case 3:
      return 'GOOD';
    case 4:
      return 'STRONG';
    default:
      return '';
  }
}

class PasswordStrengthMeter extends StatelessWidget {
  final String password;

  const PasswordStrengthMeter({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    final strength = strengthOf(password);
    final activeColor = _colorFor(strength);
    final label = _labelFor(strength);

    return Row(
      children: [
        // 4 segments
        ...List.generate(4, (i) {
          final filled = strength > i;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.only(right: i < 3 ? 4.0 : 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 3,
                decoration: BoxDecoration(
                  color: filled ? activeColor : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          );
        }),
        // Label
        const SizedBox(width: 10),
        SizedBox(
          width: 44,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Text(
              label,
              key: ValueKey(label),
              style: TextStyle(
                color: strength > 0 ? activeColor : Colors.transparent,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
