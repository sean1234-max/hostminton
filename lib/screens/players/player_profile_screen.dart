import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';

class PlayerProfileScreen extends StatelessWidget {
  final String playerName;

  const PlayerProfileScreen({super.key, required this.playerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(playerName),
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, _) => AppBarAction(
              label: 'Delete',
              color: AppColors.red,
              onTap: () => _confirmDelete(context, provider),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final currency = provider.settings.currency;
          final debt = provider.totalDebtForPlayer(playerName);
          final history = provider.paymentHistoryForPlayer(playerName);
          final stats = provider.statsForPlayer(playerName);

          final totalSessions = stats['totalSessions'] as int;
          final totalPaid = stats['totalPaid'] as double;
          final paymentRate = stats['paymentRate'] as int;
          final lastSeen = stats['lastSeen'] as DateTime?;
          final firstSeen = stats['firstSeen'] as DateTime?;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Avatar + name header ────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          playerName.isNotEmpty
                              ? playerName[0].toUpperCase()
                              : '?',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      playerName,
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w700),
                    ),
                    if (firstSeen != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Member since ${_formatDate(firstSeen)}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 11),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 4 stat tiles ────────────────────────────────────────
              Row(
                children: [
                  _statTile(
                    icon: Icons.sports_tennis_rounded,
                    label: 'Sessions',
                    value: '$totalSessions',
                    color: AppColors.accent,
                  ),
                  const SizedBox(width: 8),
                  _statTile(
                    icon: Icons.payments_outlined,
                    label: 'Total Paid',
                    value: '$currency ${totalPaid.toStringAsFixed(2)}',
                    color: AppColors.green,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  _statTile(
                    icon: Icons.verified_outlined,
                    label: 'Pay Rate',
                    value: '$paymentRate%',
                    color: paymentRate >= 80
                        ? AppColors.green
                        : paymentRate >= 50
                            ? AppColors.orange
                            : AppColors.red,
                  ),
                  const SizedBox(width: 8),
                  _statTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Last Seen',
                    value: lastSeen != null
                        ? _formatDate(lastSeen)
                        : '—',
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Outstanding debt card ───────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: debt > 0
                        ? AppColors.orange.withValues(alpha: 0.4)
                        : AppColors.border,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'OUTSTANDING DEBT',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '$currency ${debt.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: debt > 0
                                  ? AppColors.orange
                                  : AppColors.green,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            debt <= 0
                                ? 'All payments settled ✓'
                                : 'Has unpaid sessions',
                            style: TextStyle(
                                color: debt <= 0
                                    ? AppColors.green
                                    : AppColors.textMuted,
                                fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    if (debt > 0)
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: AppColors.orange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(Icons.warning_amber_rounded,
                              color: AppColors.orange, size: 20),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Session history ─────────────────────────────────────
              const SectionHeader(title: 'Session History'),
              if (history.isEmpty)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text('No history yet',
                        style: TextStyle(
                            color: AppColors.textSecondary)),
                  ),
                )
              else
                ...history.map((entry) {
                  final session = entry['session'] as Session;
                  final player = entry['player'] as SessionPlayer;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          // Date column
                          Container(
                            width: 38,
                            alignment: Alignment.center,
                            child: Column(
                              children: [
                                Text(
                                  '${session.date.day}',
                                  style: const TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  _monthShort(session.date.month),
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          const VerticalDivider(
                              color: AppColors.border,
                              width: 1,
                              thickness: 1),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  session.location.isNotEmpty
                                      ? session.location
                                      : session.name,
                                  style: const TextStyle(
                                      color: AppColors.textPrimary,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Due: $currency ${player.amountDue.toStringAsFixed(2)}'
                                  '  ·  Paid: $currency ${player.totalPaid.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              StatusBadge.fromPaymentStatus(
                                  player.status),
                              if (player.remaining > 0)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    '−$currency ${player.remaining.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: AppColors.orange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 24),

              // ── Record payment ──────────────────────────────────────
              if (debt > 0)
                PrimaryButton(
                  label: 'Record Payment',
                  onPressed: () => _showRecordPaymentSheet(
                      context, provider, currency),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _statTile({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 16),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: Text('Delete $playerName?',
            style: const TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This will remove this player from all sessions. This cannot be undone.',
          style: TextStyle(
              color: AppColors.textSecondary, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              for (final session in provider.sessions) {
                final before = session.players.length;
                session.players.removeWhere((p) =>
                    p.name.toLowerCase() == playerName.toLowerCase());
                if (session.players.length != before) {
                  await provider.updateSession(session);
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  void _showRecordPaymentSheet(
      BuildContext context, AppProvider provider, String currency) {
    final history = provider.paymentHistoryForPlayer(playerName);
    if (history.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sessions found for this player.'),
          backgroundColor: AppColors.orange,
        ),
      );
      return;
    }

    Map<String, dynamic>? unpaid;
    for (final entry in history) {
      final p = entry['player'] as SessionPlayer;
      if (p.status != PaymentStatus.paid &&
          p.status != PaymentStatus.free) {
        unpaid = entry;
        break;
      }
    }

    if (unpaid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All payments are settled!'),
          backgroundColor: AppColors.green,
        ),
      );
      return;
    }

    final player = unpaid['player'] as SessionPlayer;
    final session = unpaid['session'] as Session;
    final amtCtrl =
        TextEditingController(text: player.remaining.toStringAsFixed(2));
    final noteCtrl = TextEditingController();
    String method = 'Cash';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const BottomSheetHandle(),
              Text(
                '$playerName · Owes $currency ${player.remaining.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                'Session: ${session.location.isNotEmpty ? session.location : session.name}',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
              const SizedBox(height: 16),
              DarkInputField(
                label: 'Amount',
                hint: '0',
                controller: amtCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<String>(
                  value: method,
                  isExpanded: true,
                  dropdownColor: AppColors.cardBg,
                  underline: const SizedBox(),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  items: ['TNG', 'Bank Transfer', 'Cash']
                      .map((m) =>
                          DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setS(() => method = v!),
                ),
              ),
              const SizedBox(height: 12),
              DarkInputField(
                  label: 'Note',
                  hint: 'Optional...',
                  controller: noteCtrl),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: () async {
                  player.isFree = true;
                  player.payments.clear();
                  await provider.updateSession(session);
                  if (ctx.mounted) Navigator.pop(ctx);
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
                  final amount =
                      double.tryParse(amtCtrl.text) ?? 0;
                  if (amount <= 0) return;
                  player.payments.add(PaymentRecord(
                      amount: amount,
                      method: method,
                      note: noteCtrl.text));
                  await provider.updateSession(session);
                  if (ctx.mounted) Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]} ${d.year}';
  }

  String _monthShort(int month) {
    const m = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return m[month];
  }
}
