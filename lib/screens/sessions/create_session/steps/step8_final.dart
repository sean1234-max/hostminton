import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/models.dart';
import '../../../../providers/app_provider.dart';
import '../../../../widgets/common_widgets.dart';

// Step 6 (final): Final Expenses — shuttlecock + court calculation + save
class Step8Final extends StatefulWidget {
  final Session session;
  final Future<void> Function() onSave;

  const Step8Final({super.key, required this.session, required this.onSave});

  @override
  State<Step8Final> createState() => _Step8FinalState();
}

class _Step8FinalState extends State<Step8Final> {
  // Shuttlecock
  final List<String> _modelOptions = ['G2', 'Classic', 'Supreme', 'FS97'];
  late String _selectedModel;
  bool _showCustomModel = false;
  late TextEditingController _customModelCtrl;
  late TextEditingController _pricePerTubeCtrl;
  late TextEditingController _totalUsedCtrl; // individual shuttlecocks used

  // Court
  late TextEditingController _courtFeeCtrl;
  late TextEditingController _courtHoursCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.session;
    _selectedModel = s.shuttleModel.isNotEmpty ? s.shuttleModel : 'G2';
    _showCustomModel = !_modelOptions.contains(_selectedModel);

    _customModelCtrl =
        TextEditingController(text: _showCustomModel ? _selectedModel : '');
    _pricePerTubeCtrl = TextEditingController(
        text: s.shuttlePricePerTube > 0
            ? s.shuttlePricePerTube.toStringAsFixed(2)
            : '');
    // Pre-fill with last known individual count (finalShuttlecocksUsed)
    final preIndiv = s.finalShuttlecocksUsed ?? (s.tubeCount * 12);
    _totalUsedCtrl = TextEditingController(text: preIndiv.toString());

    _courtFeeCtrl = TextEditingController(
        text: s.courtFeePerHour > 0
            ? s.courtFeePerHour.toStringAsFixed(2)
            : '');
    _courtHoursCtrl = TextEditingController(
        text: s.courtHoursBooked == s.courtHoursBooked.floorToDouble()
            ? s.courtHoursBooked.toStringAsFixed(0)
            : s.courtHoursBooked.toStringAsFixed(1));
  }

  @override
  void dispose() {
    _customModelCtrl.dispose();
    _pricePerTubeCtrl.dispose();
    _totalUsedCtrl.dispose();
    _courtFeeCtrl.dispose();
    _courtHoursCtrl.dispose();
    super.dispose();
  }

  // ── Computed values ──────────────────────────────────────────────────────

  double get _pricePerTube =>
      double.tryParse(_pricePerTubeCtrl.text) ?? 0;

  double get _pricePerUnit => _pricePerTube > 0 ? _pricePerTube / 12 : 0;

  int get _totalUsed => int.tryParse(_totalUsedCtrl.text) ?? 0;

  double get _shuttleCost => _pricePerUnit * _totalUsed;

  double get _courtFee => double.tryParse(_courtFeeCtrl.text) ?? 0;

  double get _courtHours => double.tryParse(_courtHoursCtrl.text) ?? 0;

  double get _courtCost => _courtFee * _courtHours;

  double get _totalCost => _shuttleCost + _courtCost;

  @override
  Widget build(BuildContext context) {
    final currency = context.watch<AppProvider>().settings.currency;
    final session = widget.session;
    final income = session.totalCollected;
    final profit = income - _totalCost;
    final profitColor = profit >= 0 ? AppColors.green : AppColors.red;
    final profitStr = profit >= 0
        ? '+$currency ${profit.toStringAsFixed(2)}'
        : '-$currency ${profit.abs().toStringAsFixed(2)}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── SHUTTLECOCK ──────────────────────────────────────────────────
        _sectionCard(
          title: 'SHUTTLECOCK',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Model selector
              const Text('Model',
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._modelOptions.map((m) {
                    final sel = _selectedModel == m && !_showCustomModel;
                    return _modelChip(m, sel, () => setState(() {
                          _selectedModel = m;
                          _showCustomModel = false;
                        }));
                  }),
                  _modelChip('Custom', _showCustomModel,
                      () => setState(() => _showCustomModel = true)),
                ],
              ),
              if (_showCustomModel) ...[
                const SizedBox(height: 10),
                DarkInputField(
                  label: 'Custom Model Name',
                  hint: 'e.g. TiMa',
                  controller: _customModelCtrl,
                  onChanged: (v) => setState(() => _selectedModel = v),
                ),
              ],
              const SizedBox(height: 16),

              // Price per tube
              _inputRow('Price per tube (RM)', _pricePerTubeCtrl, prefix: 'RM'),
              const SizedBox(height: 8),

              // Price per unit (read-only, auto-calculated)
              _infoRow(
                'Cost per shuttlecock',
                _pricePerTube > 0
                    ? 'RM${_pricePerTube.toStringAsFixed(2)} ÷ 12 = RM${_pricePerUnit.toStringAsFixed(2)}'
                    : '—',
              ),
              const SizedBox(height: 8),

              // Total used
              _inputRow('Total shuttlecocks used', _totalUsedCtrl,
                  hint: '0', keyboardType: TextInputType.number),
              const SizedBox(height: 8),

              // Shuttlecock cost result
              _calcResult(
                'Shuttlecock Cost',
                _pricePerTube > 0 && _totalUsed > 0
                    ? 'RM${_pricePerUnit.toStringAsFixed(2)} × $_totalUsed = RM${_shuttleCost.toStringAsFixed(2)}'
                    : '—',
                _shuttleCost,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── COURT FEE ────────────────────────────────────────────────────
        _sectionCard(
          title: 'COURT FEE',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputRow('Court price per hour', _courtFeeCtrl, prefix: 'RM'),
              const SizedBox(height: 8),
              _inputRow('Total hours booked', _courtHoursCtrl,
                  hint: '2', keyboardType: const TextInputType.numberWithOptions(decimal: true)),
              const SizedBox(height: 8),
              _calcResult(
                'Court Cost',
                _courtFee > 0 && _courtHours > 0
                    ? 'RM${_courtFee.toStringAsFixed(2)} × ${_courtHoursCtrl.text} hr = RM${_courtCost.toStringAsFixed(2)}'
                    : '—',
                _courtCost,
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // ── SUMMARY ──────────────────────────────────────────────────────
        _sectionCard(
          title: 'SUMMARY',
          child: Column(
            children: [
              _summaryRow('Total Collected', '$currency ${income.toStringAsFixed(2)}',
                  AppColors.green),
              const SizedBox(height: 8),
              _summaryRow('Shuttlecock Cost',
                  '- $currency ${_shuttleCost.toStringAsFixed(2)}',
                  AppColors.textSecondary),
              const SizedBox(height: 8),
              _summaryRow('Court Cost',
                  '- $currency ${_courtCost.toStringAsFixed(2)}',
                  AppColors.textSecondary),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: AppColors.border, height: 1),
              ),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Net Profit / Loss',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Text(
                    profitStr,
                    style: TextStyle(
                      color: profitColor,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (session.totalUnpaid > 0) ...[
                const SizedBox(height: 10),
                _summaryRow(
                  'Still Unpaid',
                  '$currency ${session.totalUnpaid.toStringAsFixed(2)}',
                  AppColors.orange,
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // ── SAVE ─────────────────────────────────────────────────────────
        PrimaryButton(
          label: 'Save Session',
          onPressed: () async {
            // Commit shuttlecock data
            widget.session.shuttleModel = _showCustomModel
                ? (_customModelCtrl.text.trim().isNotEmpty
                    ? _customModelCtrl.text.trim()
                    : 'Custom')
                : _selectedModel;
            widget.session.shuttlePricePerTube = _pricePerTube;
            widget.session.finalShuttlecocksUsed =
                _totalUsed > 0 ? _totalUsed : null;
            // Derive tube count from individual used (ceil)
            if (_totalUsed > 0) {
              widget.session.tubeCount = (_totalUsed / 12).ceil();
            }
            // Commit court data
            widget.session.courtFeePerHour = _courtFee;
            widget.session.courtHoursBooked = _courtHours;

            await widget.onSave();
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 11,
              letterSpacing: 1,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  Widget _inputRow(
    String label,
    TextEditingController ctrl, {
    String prefix = '',
    String hint = '0',
    TextInputType keyboardType =
        const TextInputType.numberWithOptions(decimal: true),
  }) {
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
          if (prefix.isNotEmpty) const SizedBox(width: 4),
          SizedBox(
            width: 80,
            child: TextField(
              controller: ctrl,
              keyboardType: keyboardType,
              textAlign: TextAlign.right,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13),
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

  /// Read-only info row (e.g. auto-derived value)
  Widget _infoRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColors.accent, fontSize: 12)),
        ],
      ),
    );
  }

  /// Calculation result chip with formula + bold total
  Widget _calcResult(String label, String formula, double amount) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                if (formula != '—') ...[
                  const SizedBox(height: 2),
                  Text(formula,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 10)),
                ],
              ],
            ),
          ),
          Text(
            amount > 0 ? 'RM ${amount.toStringAsFixed(2)}' : '—',
            style: TextStyle(
              color: amount > 0 ? AppColors.accent : AppColors.textMuted,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, Color valueColor) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _modelChip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
            color:
                selected ? AppColors.accent : AppColors.textPrimary,
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
