import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/models.dart';

// ─── Status Badge ──────────────────────────────────────────────────────────

class StatusBadge extends StatelessWidget {
  final String label;
  final Color bgColor;
  final Color textColor;
  const StatusBadge({
    super.key,
    required this.label,
    required this.bgColor,
    this.textColor = AppColors.dark,
  });

  factory StatusBadge.fromPaymentStatus(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.paid:
        return StatusBadge(
          label: 'Paid',
          bgColor: AppColors.green.withValues(alpha: 0.15),
          textColor: AppColors.green,
        );
      case PaymentStatus.partial:
        return StatusBadge(
          label: 'Partial',
          bgColor: AppColors.orange.withValues(alpha: 0.15),
          textColor: AppColors.orange,
        );
      case PaymentStatus.unpaid:
        return StatusBadge(
          label: 'Unpaid',
          bgColor: AppColors.red.withValues(alpha: 0.15),
          textColor: AppColors.red,
        );
      case PaymentStatus.free:
        return StatusBadge(
          label: 'Free',
          bgColor: AppColors.purple.withValues(alpha: 0.15),
          textColor: AppColors.purple,
        );
    }
  }

  factory StatusBadge.fromSessionStatus(SessionStatus status) {
    switch (status) {
      case SessionStatus.settled:
        return StatusBadge(
          label: 'Settled',
          bgColor: AppColors.green.withValues(alpha: 0.15),
          textColor: AppColors.green,
        );
      case SessionStatus.hasDebt:
        return StatusBadge(
          label: 'Has Debt',
          bgColor: AppColors.orange.withValues(alpha: 0.15),
          textColor: AppColors.orange,
        );
      case SessionStatus.loss:
        return StatusBadge(
          label: 'Loss',
          bgColor: AppColors.red.withValues(alpha: 0.15),
          textColor: AppColors.red,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: textColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─── App Bar Action ────────────────────────────────────────────────────────

class AppBarAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const AppBarAction({super.key, required this.label, required this.onTap, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.accent;
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: c,
        padding: const EdgeInsets.symmetric(horizontal: 16),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: c,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── Stat Card ─────────────────────────────────────────────────────────────

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color valueColor;
  final bool expanded;
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.valueColor = AppColors.textPrimary,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
    return expanded ? Expanded(child: child) : child;
  }
}

// ─── Section Header ────────────────────────────────────────────────────────

class SectionHeader extends StatelessWidget {
  final String title;
  const SectionHeader({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 14,
            decoration: BoxDecoration(
              color: AppColors.accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Dark Input Field ──────────────────────────────────────────────────────

class DarkInputField extends StatelessWidget {
  final String label;
  final String? hint;
  final TextEditingController? controller;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;
  final bool readOnly;
  final VoidCallback? onTap;

  const DarkInputField({
    super.key,
    required this.label,
    this.hint,
    this.controller,
    this.keyboardType,
    this.maxLines = 1,
    this.suffix,
    this.onChanged,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          readOnly: readOnly,
          onTap: onTap,
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            suffixIcon: suffix,
            filled: true,
            fillColor: AppColors.inputBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.border, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppColors.accent, width: 1.5),
            ),
            hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─── Primary Button ────────────────────────────────────────────────────────

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const PrimaryButton({super.key, required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.dark,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            color: AppColors.dark,
          ),
        ),
      ),
    );
  }
}

// ─── Bottom Sheet Handle ───────────────────────────────────────────────────

class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        margin: const EdgeInsets.only(top: 12, bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ─── Step Progress Bar ─────────────────────────────────────────────────────

class StepProgressBar extends StatelessWidget {
  final int current;
  final int total;
  const StepProgressBar({super.key, required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Step $current',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              ' / $total',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(total, (i) {
            final filled = i < current;
            return Expanded(
              child: Container(
                height: 3,
                margin: EdgeInsets.only(right: i < total - 1 ? 3 : 0),
                decoration: BoxDecoration(
                  color: filled ? AppColors.accent : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Player Payment Tile ──────────────────────────────────────────────────

class PlayerPaymentTile extends StatelessWidget {
  final String name;
  final double amount;
  final PaymentStatus status;
  final bool isOverride;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final String currency;

  const PlayerPaymentTile({
    super.key,
    required this.name,
    required this.amount,
    required this.status,
    this.isOverride = false,
    this.onTap,
    this.onEdit,
    this.currency = 'RM',
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isOverride)
                    const Text(
                      'override',
                      style: TextStyle(color: AppColors.orange, fontSize: 10),
                    ),
                ],
              ),
            ),
            Text(
              '$currency${amount.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(width: 8),
            StatusBadge.fromPaymentStatus(status),
            if (onEdit != null) ...[
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onEdit,
                child: const Icon(Icons.edit_outlined,
                    color: AppColors.textSecondary, size: 16),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Session List Tile ─────────────────────────────────────────────────────

class SessionListTile extends StatelessWidget {
  final Session session;
  final VoidCallback onTap;
  final String currency;

  const SessionListTile({
    super.key,
    required this.session,
    required this.onTap,
    this.currency = 'RM',
  });

  @override
  Widget build(BuildContext context) {
    final profit = session.profit;
    final profitColor = profit >= 0 ? AppColors.green : AppColors.red;
    final profitStr = profit >= 0
        ? '+$currency${profit.abs().toStringAsFixed(2)}'
        : '-$currency${profit.abs().toStringAsFixed(2)}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    session.location.isNotEmpty ? session.location : session.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${session.date.day}/${session.date.month}/${session.date.year} · ${session.players.length} players',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  profitStr,
                  style: TextStyle(
                    color: profitColor,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                StatusBadge.fromSessionStatus(session.status),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── QR Upload Card ────────────────────────────────────────────────────────

class QrUploadCard extends StatelessWidget {
  final String label;
  final String? imagePath;
  final VoidCallback onUpload;

  const QrUploadCard({
    super.key,
    required this.label,
    this.imagePath,
    required this.onUpload,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 11),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: onUpload,
              child: Container(
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: imagePath != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.asset(imagePath!, fit: BoxFit.cover))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(Icons.qr_code_rounded,
                              color: AppColors.textMuted, size: 24),
                          SizedBox(height: 4),
                          Text(
                            'Tap to upload',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
