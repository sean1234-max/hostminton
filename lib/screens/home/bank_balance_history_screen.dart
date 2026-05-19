import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';

// ─── Unified transaction model ────────────────────────────────────────────────

enum _TxCategory { capitalDeposit, capitalWithdraw, session }

class _Tx {
  final String id;
  final _TxCategory category;
  final String title;
  final String subtitle;
  final DateTime date;
  final double amount; // positive = income, negative = expense

  const _Tx({
    required this.id,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.date,
    required this.amount,
  });

  bool matchesSearch(String q) {
    final lower = q.toLowerCase();
    return title.toLowerCase().contains(lower) ||
        subtitle.toLowerCase().contains(lower);
  }
}

// ─── Filter enum ──────────────────────────────────────────────────────────────

enum _Filter { all, capital, sessions, income, expense }

// ─── Screen ───────────────────────────────────────────────────────────────────

class BankBalanceHistoryScreen extends StatefulWidget {
  const BankBalanceHistoryScreen({super.key});

  @override
  State<BankBalanceHistoryScreen> createState() =>
      _BankBalanceHistoryScreenState();
}

class _BankBalanceHistoryScreenState
    extends State<BankBalanceHistoryScreen> {
  String _search = '';
  _Filter _filter = _Filter.all;

  // Build unified transaction list from provider data
  List<_Tx> _buildTransactions(AppProvider provider) {
    final txs = <_Tx>[];

    // Capital entries
    for (final e in provider.capitalEntries) {
      txs.add(_Tx(
        id: 'cap_${e.id}',
        category:
            e.amount >= 0 ? _TxCategory.capitalDeposit : _TxCategory.capitalWithdraw,
        title: e.note.isNotEmpty
            ? e.note
            : (e.amount >= 0 ? 'Capital Deposit' : 'Capital Withdraw'),
        subtitle: e.amount >= 0 ? 'Deposit' : 'Withdraw',
        date: e.date,
        amount: e.amount,
      ));
    }

    // Sessions — one entry per session showing net profit
    for (final s in provider.sessions) {
      final collected = s.totalCollected;
      final cost = s.totalCost;
      final net = collected - cost;
      final label = s.location.isNotEmpty ? s.location : s.name;
      txs.add(_Tx(
        id: 'ses_${s.id}',
        category: _TxCategory.session,
        title: label.isNotEmpty ? label : 'Session',
        subtitle:
            'Collected ${provider.settings.currency} ${collected.toStringAsFixed(2)}  ·  '
            'Cost ${provider.settings.currency} ${cost.toStringAsFixed(2)}',
        date: s.date,
        amount: net,
      ));
    }

    // Sort newest first
    txs.sort((a, b) => b.date.compareTo(a.date));
    return txs;
  }

  List<_Tx> _applyFilters(List<_Tx> all) {
    var result = all;

    // Search
    if (_search.isNotEmpty) {
      result = result.where((t) => t.matchesSearch(_search)).toList();
    }

    // Filter
    switch (_filter) {
      case _Filter.all:
        break;
      case _Filter.capital:
        result = result
            .where((t) =>
                t.category == _TxCategory.capitalDeposit ||
                t.category == _TxCategory.capitalWithdraw)
            .toList();
      case _Filter.sessions:
        result =
            result.where((t) => t.category == _TxCategory.session).toList();
      case _Filter.income:
        result = result.where((t) => t.amount >= 0).toList();
      case _Filter.expense:
        result = result.where((t) => t.amount < 0).toList();
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final currency = provider.settings.currency;
        final allTxs = _buildTransactions(provider);
        final filtered = _applyFilters(allTxs);

        // Summary totals (always from full unfiltered data)
        final totalIncome = allTxs
            .where((t) => t.amount > 0)
            .fold(0.0, (acc, t) => acc + t.amount);
        final totalExpense = allTxs
            .where((t) => t.amount < 0)
            .fold(0.0, (acc, t) => acc + t.amount.abs());

        return Scaffold(
          appBar: AppBar(title: const Text('Bank Balance History')),
          body: Column(
            children: [
              // ── Summary card ─────────────────────────────────────────
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
                          Expanded(
                            child: _summaryItem(
                              label: 'BANK BALANCE',
                              value:
                                  '$currency ${provider.bankBalance.toStringAsFixed(2)}',
                              color: provider.bankBalance >= 0
                                  ? AppColors.accent
                                  : AppColors.red,
                              large: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _summaryItem(
                              label: 'TOTAL IN',
                              value: '+$currency ${totalIncome.toStringAsFixed(2)}',
                              color: AppColors.green,
                            ),
                          ),
                          Expanded(
                            child: _summaryItem(
                              label: 'TOTAL OUT',
                              value: '-$currency ${totalExpense.toStringAsFixed(2)}',
                              color: AppColors.red,
                            ),
                          ),
                          Expanded(
                            child: _summaryItem(
                              label: 'TRANSACTIONS',
                              value: '${allTxs.length}',
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // ── Search bar ────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search transactions...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary, size: 18),
                    suffixIcon: _search.isNotEmpty
                        ? GestureDetector(
                            onTap: () => setState(() => _search = ''),
                            child: const Icon(Icons.close_rounded,
                                color: AppColors.textMuted, size: 16),
                          )
                        : null,
                    filled: true,
                    fillColor: AppColors.inputBg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: AppColors.border),
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

              // ── Filter chips ──────────────────────────────────────────
              SizedBox(
                height: 32,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _filterChip('All', _Filter.all),
                    const SizedBox(width: 8),
                    _filterChip('Capital', _Filter.capital),
                    const SizedBox(width: 8),
                    _filterChip('Sessions', _Filter.sessions),
                    const SizedBox(width: 8),
                    _filterChip('Income (+)', _Filter.income),
                    const SizedBox(width: 8),
                    _filterChip('Expense (−)', _Filter.expense),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Count label ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      '${filtered.length} transaction${filtered.length == 1 ? '' : 's'}',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),

              // ── Transaction list ──────────────────────────────────────
              Expanded(
                child: filtered.isEmpty
                    ? const Center(
                        child: Text(
                          'No transactions found',
                          style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (_, i) =>
                            _TxCard(tx: filtered[i], currency: currency),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryItem({
    required String label,
    required String value,
    required Color color,
    bool large = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(value,
            style: TextStyle(
                color: color,
                fontSize: large ? 20 : 14,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _filterChip(String label, _Filter mode) {
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
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accent : AppColors.textSecondary,
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

// ─── Transaction card ─────────────────────────────────────────────────────────

class _TxCard extends StatelessWidget {
  final _Tx tx;
  final String currency;

  const _TxCard({required this.tx, required this.currency});

  @override
  Widget build(BuildContext context) {
    final isPositive = tx.amount >= 0;

    // Colours and icons per category
    Color iconBg;
    Color iconColor;
    IconData icon;
    Color amountColor;

    switch (tx.category) {
      case _TxCategory.capitalDeposit:
        iconBg = AppColors.green.withValues(alpha: 0.12);
        iconColor = AppColors.green;
        icon = Icons.arrow_downward_rounded;
        amountColor = AppColors.green;
      case _TxCategory.capitalWithdraw:
        iconBg = AppColors.red.withValues(alpha: 0.12);
        iconColor = AppColors.red;
        icon = Icons.arrow_upward_rounded;
        amountColor = AppColors.red;
      case _TxCategory.session:
        iconBg = AppColors.accent.withValues(alpha: 0.10);
        iconColor = AppColors.accent;
        icon = Icons.sports_tennis_rounded;
        amountColor = isPositive ? AppColors.green : AppColors.red;
    }

    final amountStr = isPositive
        ? '+$currency ${tx.amount.toStringAsFixed(2)}'
        : '-$currency ${tx.amount.abs().toStringAsFixed(2)}';

    // Date/time display
    final d = tx.date;
    final dateStr =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
    final timeStr = tx.category == _TxCategory.session
        ? '' // sessions have no precise time stored
        : '  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    // Type badge label
    final badgeLabel = switch (tx.category) {
      _TxCategory.capitalDeposit => 'Deposit',
      _TxCategory.capitalWithdraw => 'Withdraw',
      _TxCategory.session => 'Session',
    };
    final badgeColor = switch (tx.category) {
      _TxCategory.capitalDeposit => AppColors.green,
      _TxCategory.capitalWithdraw => AppColors.red,
      _TxCategory.session => AppColors.accent,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          // Icon badge
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),

          // Title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                            color: badgeColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        tx.title,
                        style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  tx.subtitle,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  '$dateStr$timeStr',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 10),
                ),
              ],
            ),
          ),

          // Amount
          const SizedBox(width: 8),
          Text(
            amountStr,
            style: TextStyle(
                color: amountColor,
                fontSize: 13,
                fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
