import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common_widgets.dart';

// Step 3: Costs — shuttlecock + court fee
class Step3Costs extends StatefulWidget {
  final Session session;
  final VoidCallback onNext;

  const Step3Costs({super.key, required this.session, required this.onNext});

  @override
  State<Step3Costs> createState() => _Step3CostsState();
}

class _Step3CostsState extends State<Step3Costs> {
  late TextEditingController _shuttlePriceCtrl;
  late TextEditingController _tubeCountCtrl;
  late TextEditingController _courtFeeCtrl;
  late TextEditingController _courtHoursCtrl;
  late TextEditingController _customModelCtrl;

  String _selectedModel = 'G2';
  bool _showCustomModel = false;

  final List<String> _modelOptions = ['G2', 'Classic', 'Supreme', 'FS97'];

  @override
  void initState() {
    super.initState();
    _selectedModel = widget.session.shuttleModel;
    _showCustomModel = !_modelOptions.contains(_selectedModel);
    _shuttlePriceCtrl = TextEditingController(
        text: widget.session.shuttlePricePerTube.toStringAsFixed(2));
    _tubeCountCtrl =
        TextEditingController(text: widget.session.tubeCount.toString());
    _courtFeeCtrl = TextEditingController(
        text: widget.session.courtFeePerHour.toStringAsFixed(2));
    _courtHoursCtrl = TextEditingController(
        text: widget.session.courtHoursBooked == widget.session.courtHoursBooked.floorToDouble()
            ? widget.session.courtHoursBooked.toStringAsFixed(0)
            : widget.session.courtHoursBooked.toStringAsFixed(1));
    _customModelCtrl = TextEditingController(
        text: _showCustomModel ? _selectedModel : '');
  }

  @override
  void dispose() {
    _shuttlePriceCtrl.dispose();
    _tubeCountCtrl.dispose();
    _courtFeeCtrl.dispose();
    _courtHoursCtrl.dispose();
    _customModelCtrl.dispose();
    super.dispose();
  }

  double get _shuttleCost =>
      (double.tryParse(_shuttlePriceCtrl.text) ?? 0) *
      (int.tryParse(_tubeCountCtrl.text) ?? 0);
  double get _courtCost =>
      (double.tryParse(_courtFeeCtrl.text) ?? 0) *
      (double.tryParse(_courtHoursCtrl.text) ?? 0);
  double get _totalCost => _shuttleCost + _courtCost;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Shuttlecock section ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SHUTTLECOCK',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              // Model chips
              const Text('Model',
                  style:
                      TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._modelOptions.map((m) {
                    final selected = _selectedModel == m && !_showCustomModel;
                    return _modelChip(m, selected, () {
                      setState(() {
                        _selectedModel = m;
                        _showCustomModel = false;
                      });
                    });
                  }),
                  _modelChip('Custom', _showCustomModel, () {
                    setState(() => _showCustomModel = true);
                  }),
                ],
              ),
              if (_showCustomModel) ...[
                const SizedBox(height: 10),
                DarkInputField(
                  label: 'Custom Model Name',
                  hint: 'e.g. TiMa',
                  controller: _customModelCtrl,
                  onChanged: (v) => _selectedModel = v,
                ),
              ],
              const SizedBox(height: 14),
              _inputRow('Price per tube', _shuttlePriceCtrl, 'RM'),
              const SizedBox(height: 8),
              _inputRow('Number of tubes', _tubeCountCtrl, ''),
              const SizedBox(height: 10),
              _calcRow(
                  'Shuttlecock Total',
                  'RM${(double.tryParse(_shuttlePriceCtrl.text) ?? 0).toStringAsFixed(2)}'
                  ' × ${_tubeCountCtrl.text} = RM${_shuttleCost.toStringAsFixed(2)}'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Court section ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'COURT FEE',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _inputRow('Court price per hour', _courtFeeCtrl, 'RM'),
              const SizedBox(height: 8),
              _inputRow('Total hours booked', _courtHoursCtrl, ''),
              const SizedBox(height: 8),
              _calcRow(
                'Court Total',
                'RM${(double.tryParse(_courtFeeCtrl.text) ?? 0).toStringAsFixed(2)}'
                ' × ${_courtHoursCtrl.text} hr = RM${_courtCost.toStringAsFixed(2)}',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // ── Total preview ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'ESTIMATED COST',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'RM ${_totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Next',
          onPressed: () {
            widget.session.shuttleModel = _showCustomModel
                ? (_customModelCtrl.text.trim().isNotEmpty
                    ? _customModelCtrl.text.trim()
                    : 'Custom')
                : _selectedModel;
            widget.session.shuttlePricePerTube =
                double.tryParse(_shuttlePriceCtrl.text) ?? 90;
            widget.session.tubeCount = int.tryParse(_tubeCountCtrl.text) ?? 2;
            widget.session.courtFeePerHour =
                double.tryParse(_courtFeeCtrl.text) ?? 0;
            widget.session.courtHoursBooked =
                double.tryParse(_courtHoursCtrl.text) ?? 2.0;
            widget.onNext();
          },
        ),
      ],
    );
  }

  Widget _modelChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.inputBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textPrimary,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _inputRow(String label, TextEditingController ctrl, String prefix) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          ),
          if (prefix.isNotEmpty)
            Text(prefix,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 12)),
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13),
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                fillColor: Colors.transparent,
                filled: false,
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calcRow(String label, String formula) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(formula,
          style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
    );
  }
}
