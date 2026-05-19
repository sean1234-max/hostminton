import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/models.dart';
import '../../../../providers/app_provider.dart';
import '../../../../widgets/common_widgets.dart';

// Step 7: Payments — track individual player payments
class Step7Payments extends StatefulWidget {
  final Session session;
  final VoidCallback onNext;

  const Step7Payments({super.key, required this.session, required this.onNext});

  @override
  State<Step7Payments> createState() => _Step7PaymentsState();
}

class _Step7PaymentsState extends State<Step7Payments> {
  void _showPaymentSheet(SessionPlayer player) {
    final currency = context.read<AppProvider>().settings.currency;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuickPaySheet(
        player: player,
        currency: currency,
        onSave: (amount, method, note) {
          setState(() {
            player.payments
                .add(PaymentRecord(amount: amount, method: method, note: note));
          });
        },
        onFree: () => setState(() {
          player.isFree = true;
          player.payments.clear();
        }),
        onUnfree: () => setState(() => player.isFree = false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final currency = context.watch<AppProvider>().settings.currency;

    final paidCount = session.players
        .where((p) =>
            p.status == PaymentStatus.paid || p.status == PaymentStatus.free)
        .length;
    final unpaidCount = session.players
        .where((p) =>
            p.status == PaymentStatus.unpaid ||
            p.status == PaymentStatus.partial)
        .length;

    return Column(
      children: [
        // ── Stats bar ──────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                _statPill(Icons.check_circle_rounded, AppColors.green,
                    '$paidCount paid'),
                const SizedBox(width: 12),
                _statPill(Icons.pending_rounded, AppColors.orange,
                    '$unpaidCount pending'),
                const Spacer(),
                Text(
                  '$currency ${session.totalCollected.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        // ── Player list ────────────────────────────────────────────
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: session.players.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (_, i) {
              final p = session.players[i];
              return PlayerPaymentTile(
                name: p.name,
                amount: p.amountDue,
                status: p.status,
                isOverride: p.isOverride,
                currency: currency,
                onTap: () => _showPaymentSheet(p),
              );
            },
          ),
        ),
        // ── Next button ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: PrimaryButton(
              label: 'Next → Final Summary', onPressed: widget.onNext),
        ),
      ],
    );
  }

  Widget _statPill(IconData icon, Color color, String label) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}

// ─── Quick Pay Sheet ────────────────────────────────────────────────────────

class _QuickPaySheet extends StatefulWidget {
  final SessionPlayer player;
  final String currency;
  final void Function(double, String, String) onSave;
  final VoidCallback onFree;
  final VoidCallback onUnfree;

  const _QuickPaySheet({
    required this.player,
    required this.currency,
    required this.onSave,
    required this.onFree,
    required this.onUnfree,
  });

  @override
  State<_QuickPaySheet> createState() => _QuickPaySheetState();
}

class _QuickPaySheetState extends State<_QuickPaySheet> {
  late TextEditingController _amtCtrl;
  final _noteCtrl = TextEditingController();
  String _method = 'Cash';

  @override
  void initState() {
    super.initState();
    _amtCtrl =
        TextEditingController(text: widget.player.remaining.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _amtCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.player;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          Text(
            p.isFree
                ? '${p.name} · Free'
                : '${p.name} · ${widget.currency} ${p.amountDue.toStringAsFixed(2)}',
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (p.isFree) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'This player is marked as free — no payment required',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.purple, fontSize: 13),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                widget.onUnfree();
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Undo Free'),
            ),
          ] else ...[
            DarkInputField(
              label: 'Payment Amount',
              hint: '0',
              controller: _amtCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            const Text('Payment Method',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 6),
            Container(
              decoration: BoxDecoration(
                color: AppColors.inputBg,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: DropdownButton<String>(
                value: _method,
                isExpanded: true,
                dropdownColor: AppColors.cardBg,
                underline: const SizedBox(),
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                items: ['TNG', 'Bank Transfer', 'Cash']
                    .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                    .toList(),
                onChanged: (v) => setState(() => _method = v!),
              ),
            ),
            const SizedBox(height: 12),
            DarkInputField(
                label: 'Note', hint: 'Optional...', controller: _noteCtrl),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                widget.onFree();
                Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.purple),
                foregroundColor: AppColors.purple,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Free — no payment required'),
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              label: 'Save',
              onPressed: () {
                final amount = double.tryParse(_amtCtrl.text) ?? 0;
                if (amount <= 0) return;
                widget.onSave(amount, _method, _noteCtrl.text);
                Navigator.pop(context);
              },
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
