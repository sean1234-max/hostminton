import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/models.dart';
import '../../../../providers/app_provider.dart';
import '../../../../widgets/common_widgets.dart';

// Step 6: QR Codes + Payment Tracking (combined)
class Step6QrAndPayments extends StatefulWidget {
  final Session session;
  final VoidCallback onNext;

  const Step6QrAndPayments({
    super.key,
    required this.session,
    required this.onNext,
  });

  @override
  State<Step6QrAndPayments> createState() => _Step6QrAndPaymentsState();
}

class _Step6QrAndPaymentsState extends State<Step6QrAndPayments> {
  // 0 = bank, 1 = tng — auto-select whichever exists
  int _selectedTab = 0;

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
    final settings = context.watch<AppProvider>().settings;
    final currency = settings.currency;
    final session = widget.session;
    final bankQr = settings.bankQrPath;
    final tngQr = settings.tngQrPath;
    final hasBank = bankQr != null && bankQr.isNotEmpty;
    final hasTng = tngQr != null && tngQr.isNotEmpty;
    final hasQr = hasBank || hasTng;

    // Build tab labels dynamically based on what QRs exist
    final tabs = <String>[];
    if (hasBank) tabs.add('Bank Transfer');
    if (hasTng) tabs.add('Touch n Go');

    // Active QR path for the selected tab
    String? activeQr;
    if (tabs.isNotEmpty) {
      final safeTab = _selectedTab.clamp(0, tabs.length - 1);
      if (tabs[safeTab] == 'Bank Transfer') {
        activeQr = bankQr;
      } else {
        activeQr = tngQr;
      }
    }

    final paidCount = session.players
        .where((p) =>
            p.status == PaymentStatus.paid || p.status == PaymentStatus.free)
        .length;
    final unpaidCount = session.players
        .where((p) =>
            p.status == PaymentStatus.unpaid ||
            p.status == PaymentStatus.partial)
        .length;

    return CustomScrollView(
      slivers: [
        // ── QR Section with tab switcher ──────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  // ── Top bar: title + tab pills ──────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
                    child: Row(
                      children: [
                        const Icon(Icons.qr_code_rounded,
                            color: AppColors.accent, size: 16),
                        const SizedBox(width: 6),
                        const Text(
                          'Scan to Pay',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        // Tab pills — only shown if both QRs exist
                        if (hasBank && hasTng)
                          Container(
                            height: 30,
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: AppColors.inputBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _tabPill('Bank', 0),
                                const SizedBox(width: 2),
                                _tabPill('Touch n Go', 1),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── QR Image ────────────────────────────────────────
                  if (!hasQr)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        decoration: BoxDecoration(
                          color: AppColors.inputBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.qr_code_rounded,
                                color: AppColors.textMuted, size: 40),
                            SizedBox(height: 10),
                            Text('No QR codes uploaded',
                                style: TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 13)),
                            SizedBox(height: 4),
                            Text(
                              'Go to Settings → Payment QR Codes',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    // Large full-width QR on white bg for easy scanning
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            Text(
                              tabs.isNotEmpty
                                  ? tabs[_selectedTab.clamp(0, tabs.length - 1)]
                                  : '',
                              style: const TextStyle(
                                color: Color(0xFF111111),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 10),
                            AspectRatio(
                              aspectRatio: 1,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: activeQr != null
                                    ? _buildQrImage(activeQr)
                                    : const SizedBox(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // ── Stats bar ─────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$currency ${session.totalCollected.toStringAsFixed(2)} collected',
                        style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (session.totalUnpaid > 0)
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
          ),
        ),

        // ── Player list ───────────────────────────────────────────────
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          sliver: SliverList.separated(
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

        // ── Next button ───────────────────────────────────────────────
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: PrimaryButton(
              label: 'Next → Final Summary',
              onPressed: widget.onNext,
            ),
          ),
        ),
      ],
    );
  }

  /// Small pill tab button
  Widget _tabPill(String label, int index) {
    final selected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.dark : AppColors.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  /// Renders a QR image from base64, network URL, or file path
  Widget _buildQrImage(String path) {
    if (path.startsWith('data:image')) {
      return Image.memory(
        base64Decode(path.split(',').last),
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.qr_code_rounded,
                color: AppColors.textMuted, size: 56)),
      );
    } else if (path.startsWith('http')) {
      return Image.network(
        path,
        fit: BoxFit.contain,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : const Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.accent)),
        errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.qr_code_rounded,
                color: AppColors.textMuted, size: 56)),
      );
    } else {
      return Image.file(File(path), fit: BoxFit.contain);
    }
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
    // Fix: never pre-fill a negative amount; use 0 if already overpaid
    final remaining = widget.player.remaining;
    _amtCtrl = TextEditingController(
        text: (remaining > 0 ? remaining : 0.0).toStringAsFixed(2));
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
    final remaining = p.remaining;
    final isOverpaid = !p.isFree && remaining < 0;

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
          if (!p.isFree) ...[
            const SizedBox(height: 4),
            Text(
              isOverpaid
                  ? 'Overpaid by ${widget.currency} ${remaining.abs().toStringAsFixed(2)}'
                  : 'Paid: ${widget.currency} ${p.totalPaid.toStringAsFixed(2)} · Remaining: ${widget.currency} ${remaining.toStringAsFixed(2)}',
              style: TextStyle(
                color: isOverpaid ? AppColors.green : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
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
