import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

enum _CapitalFilter { all, deposit, withdraw }

class CapitalHistoryScreen extends StatefulWidget {
  const CapitalHistoryScreen({super.key});

  @override
  State<CapitalHistoryScreen> createState() => _CapitalHistoryScreenState();
}

class _CapitalHistoryScreenState extends State<CapitalHistoryScreen> {
  String _search = '';
  _CapitalFilter _filter = _CapitalFilter.all;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final allEntries = provider.capitalEntries; // newest-first
        final currency = provider.settings.currency;

        // Totals always from full data
        final totalDeposit = allEntries
            .where((e) => e.amount >= 0)
            .fold(0.0, (acc, e) => acc + e.amount);
        final totalWithdraw = allEntries
            .where((e) => e.amount < 0)
            .fold(0.0, (acc, e) => acc + e.amount.abs());
        final net = provider.totalCapital;

        // Apply filter + search
        var entries = allEntries.where((e) {
          final matchFilter = switch (_filter) {
            _CapitalFilter.all => true,
            _CapitalFilter.deposit => e.amount >= 0,
            _CapitalFilter.withdraw => e.amount < 0,
          };
          final matchSearch = _search.isEmpty ||
              e.note.toLowerCase().contains(_search.toLowerCase());
          return matchFilter && matchSearch;
        }).toList();

        return Scaffold(
          appBar: AppBar(title: const Text('Capital History')),
          body: allEntries.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.account_balance_wallet_outlined,
                          color: AppColors.textMuted, size: 48),
                      SizedBox(height: 12),
                      Text('No records yet',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 14)),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // ── Summary card ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                _summaryChip(
                                  label: 'Net Balance',
                                  amount: net,
                                  currency: currency,
                                  color: net >= 0
                                      ? AppColors.green
                                      : AppColors.red,
                                  isLarge: true,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Divider(color: AppColors.border, height: 1),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _summaryChip(
                                    label: 'Total Deposited',
                                    amount: totalDeposit,
                                    currency: currency,
                                    color: AppColors.green,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _summaryChip(
                                    label: 'Total Withdrawn',
                                    amount: totalWithdraw,
                                    currency: currency,
                                    color: AppColors.red,
                                    isNegative: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ── Search bar ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: TextField(
                        onChanged: (v) => setState(() => _search = v),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Search by note...',
                          prefixIcon: const Icon(Icons.search_rounded,
                              color: AppColors.textSecondary, size: 18),
                          suffixIcon: _search.isNotEmpty
                              ? GestureDetector(
                                  onTap: () =>
                                      setState(() => _search = ''),
                                  child: const Icon(Icons.close_rounded,
                                      color: AppColors.textMuted, size: 16),
                                )
                              : null,
                          filled: true,
                          fillColor: AppColors.inputBg,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: AppColors.border),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.accent, width: 1.5),
                          ),
                          hintStyle:
                              const TextStyle(color: AppColors.textMuted),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // ── Filter chips ────────────────────────────────────
                    SizedBox(
                      height: 32,
                      child: ListView(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        children: [
                          _filterChip('All', _CapitalFilter.all,
                              allEntries.length),
                          const SizedBox(width: 8),
                          _filterChip(
                              'Deposits',
                              _CapitalFilter.deposit,
                              allEntries
                                  .where((e) => e.amount >= 0)
                                  .length),
                          const SizedBox(width: 8),
                          _filterChip(
                              'Withdrawals',
                              _CapitalFilter.withdraw,
                              allEntries
                                  .where((e) => e.amount < 0)
                                  .length),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Count ───────────────────────────────────────────
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          const SectionHeader(title: 'Records'),
                          const Spacer(),
                          Text(
                            '${entries.length} of ${allEntries.length}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // ── List ────────────────────────────────────────────
                    Expanded(
                      child: entries.isEmpty
                          ? const Center(
                              child: Text(
                                'No records match',
                                style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 0, 16, 32),
                              itemCount: entries.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, i) {
                                final e = entries[i];
                                return _CapitalEntryCard(
                                  entry: e,
                                  currency: currency,
                                  onDelete: () => _confirmDelete(
                                      context, provider, e.id),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Widget _filterChip(String label, _CapitalFilter mode, int count) {
    final active = _filter == mode;
    return GestureDetector(
      onTap: () => setState(() => _filter = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color:
                    active ? AppColors.accent : AppColors.textSecondary,
                fontSize: 12,
                fontWeight:
                    active ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
            const SizedBox(width: 5),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: active
                    ? AppColors.accent.withValues(alpha: 0.2)
                    : AppColors.border,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color:
                      active ? AppColors.accent : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryChip({
    required String label,
    required double amount,
    required String currency,
    required Color color,
    bool isLarge = false,
    bool isNegative = false,
  }) {
    final display = isNegative
        ? '- $currency ${amount.toStringAsFixed(2)}'
        : '$currency ${amount.toStringAsFixed(2)}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          display,
          style: TextStyle(
            color: color,
            fontSize: isLarge ? 22 : 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Remove Entry?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This record will be permanently deleted.',
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
              await provider.deleteCapitalEntry(id);
            },
            child: const Text('Delete',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Single entry card ────────────────────────────────────────────────────────

class _CapitalEntryCard extends StatelessWidget {
  final CapitalEntry entry;
  final String currency;
  final VoidCallback onDelete;

  const _CapitalEntryCard({
    required this.entry,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDeposit = entry.amount >= 0;
    final typeColor = isDeposit ? AppColors.green : AppColors.red;
    final typeLabel = isDeposit ? 'Deposit' : 'Withdraw';
    final typeIcon = isDeposit
        ? Icons.arrow_downward_rounded
        : Icons.arrow_upward_rounded;

    final d = entry.date;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final timeStr =
        '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    final amountStr = isDeposit
        ? '+ $currency ${entry.amount.toStringAsFixed(2)}'
        : '- $currency ${entry.amount.abs().toStringAsFixed(2)}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Type icon badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: typeColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(typeIcon, color: typeColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Label + date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: typeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                            color: typeColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          entry.note,
                          style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '$dateStr  $timeStr',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                ),
              ],
            ),
          ),

          // Amount + delete
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountStr,
                style: TextStyle(
                    color: typeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              GestureDetector(
                onTap: onDelete,
                child: const Text(
                  'Delete',
                  style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 10,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.textMuted),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
