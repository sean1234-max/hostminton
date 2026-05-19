import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme/app_colors.dart';
import '../../../models/models.dart';
import '../../../providers/app_provider.dart';
import '../../../widgets/common_widgets.dart';

class PaymentTrackingScreen extends StatelessWidget {
  final String sessionId;

  const PaymentTrackingScreen({super.key, required this.sessionId});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final session = provider.getSession(sessionId);
        if (session == null) {
          return const Center(
            child: Text('Session not found',
                style: TextStyle(color: AppColors.textSecondary)),
          );
        }
        final currency = provider.settings.currency;

        final paidCount = session.players
            .where((p) =>
                p.status == PaymentStatus.paid ||
                p.status == PaymentStatus.free)
            .length;
        final unpaidCount = session.players
            .where((p) =>
                p.status == PaymentStatus.unpaid ||
                p.status == PaymentStatus.partial)
            .length;

        return Column(
          children: [
            // ── Stats bar ──────────────────────────────────────────────
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currency ${session.totalCollected.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$currency ${session.totalUnpaid.toStringAsFixed(2)} unpaid',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 10),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // ── Player list ────────────────────────────────────────────
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: session.players.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final p = session.players[i];
                  return PlayerPaymentTile(
                    name: p.name,
                    amount: p.amountDue,
                    status: p.status,
                    isOverride: p.isOverride,
                    currency: currency,
                    onTap: () =>
                        _showPaymentSheet(context, session, p, provider),
                  );
                },
              ),
            ),
          ],
        );
      },
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

  void _showPaymentSheet(BuildContext context, Session session,
      SessionPlayer player, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PaymentBottomSheet(
        session: session,
        player: player,
        currency: provider.settings.currency,
        onSave: (amount, method, note) async {
          final record =
              PaymentRecord(amount: amount, method: method, note: note);
          player.payments.add(record);
          await provider.updateSession(session);
        },
        onFree: () async {
          player.isFree = true;
          player.payments.clear();
          await provider.updateSession(session);
        },
        onUnfree: () async {
          player.isFree = false;
          await provider.updateSession(session);
        },
      ),
    );
  }
}

// ─── Payment Bottom Sheet ──────────────────────────────────────────────────

class _PaymentBottomSheet extends StatefulWidget {
  final Session session;
  final SessionPlayer player;
  final String currency;
  final Future<void> Function(double amount, String method, String note) onSave;
  final Future<void> Function() onFree;
  final Future<void> Function() onUnfree;

  const _PaymentBottomSheet({
    required this.session,
    required this.player,
    required this.currency,
    required this.onSave,
    required this.onFree,
    required this.onUnfree,
  });

  @override
  State<_PaymentBottomSheet> createState() => _PaymentBottomSheetState();
}

class _PaymentBottomSheetState extends State<_PaymentBottomSheet> {
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  String _method = 'Cash';

  @override
  void initState() {
    super.initState();
    final remaining = widget.player.remaining;
    _amountCtrl.text = (remaining > 0 ? remaining : 0.0).toStringAsFixed(2);
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          if (!p.isFree) ...[
            const SizedBox(height: 4),
            Builder(builder: (context) {
              final remaining = p.remaining;
              final isOverpaid = remaining < 0;
              return Text(
                isOverpaid
                    ? 'Overpaid by ${widget.currency} ${remaining.abs().toStringAsFixed(2)}'
                    : 'Paid: ${widget.currency} ${p.totalPaid.toStringAsFixed(2)} · Remaining: ${widget.currency} ${remaining.toStringAsFixed(2)}',
                style: TextStyle(
                  color: isOverpaid ? AppColors.green : AppColors.textSecondary,
                  fontSize: 12,
                ),
              );
            }),
          ],
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
              onPressed: () async {
                await widget.onUnfree();
                if (context.mounted) Navigator.pop(context);
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
              controller: _amountCtrl,
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
              label: 'Note',
              hint: 'Optional note...',
              controller: _noteCtrl,
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () async {
                await widget.onFree();
                if (context.mounted) Navigator.pop(context);
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
              onPressed: () async {
                final amount = double.tryParse(_amountCtrl.text) ?? 0;
                if (amount <= 0) return;
                await widget.onSave(amount, _method, _noteCtrl.text);
                if (context.mounted) Navigator.pop(context);
              },
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
