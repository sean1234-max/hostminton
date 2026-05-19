import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common_widgets.dart';

// Step 2: Pricing — configure male/female price for this session
class Step2Pricing extends StatefulWidget {
  final Session session;
  final double initialMalePrice;
  final double initialFemalePrice;
  final void Function(double male, double female) onNext;

  const Step2Pricing({
    super.key,
    required this.session,
    required this.initialMalePrice,
    required this.initialFemalePrice,
    required this.onNext,
  });

  @override
  State<Step2Pricing> createState() => _Step2PricingState();
}

class _Step2PricingState extends State<Step2Pricing> {
  late TextEditingController _malePriceCtrl;
  late TextEditingController _femalePriceCtrl;

  @override
  void initState() {
    super.initState();
    _malePriceCtrl =
        TextEditingController(text: widget.initialMalePrice.toStringAsFixed(2));
    _femalePriceCtrl =
        TextEditingController(text: widget.initialFemalePrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _malePriceCtrl.dispose();
    _femalePriceCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PRICING',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Set the player fee for this session',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              // Male price
              _priceCard(
                icon: Icons.male_rounded,
                label: 'Male Player Price',
                controller: _malePriceCtrl,
                iconColor: const Color(0xFF60A5FA),
              ),
              const SizedBox(height: 12),
              // Female price
              _priceCard(
                icon: Icons.female_rounded,
                label: 'Female Player Price',
                controller: _femalePriceCtrl,
                iconColor: const Color(0xFFF472B6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
          ),
          child: const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'These prices apply to all players. You can override individual prices in the next step.',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Next',
          onPressed: () {
            final male = double.tryParse(_malePriceCtrl.text) ??
                widget.initialMalePrice;
            final female = double.tryParse(_femalePriceCtrl.text) ??
                widget.initialFemalePrice;
            widget.onNext(male, female);
          },
        ),
      ],
    );
  }

  Widget _priceCard({
    required IconData icon,
    required String label,
    required TextEditingController controller,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Text('RM ',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 14)),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                          fillColor: Colors.transparent,
                          filled: false,
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
