import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../sessions/session_detail_screen.dart';

class ReportsDetailScreen extends StatelessWidget {
  const ReportsDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DateFormat('MMMM yyyy').format(DateTime.now())),
        actions: [
          AppBarAction(label: 'Export', onTap: () => _showExportSheet(context)),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final currency = provider.settings.currency;
          final now = DateTime.now();
          final monthSessions = provider.sessions
              .where((s) => s.date.year == now.year && s.date.month == now.month)
              .toList();

          final totalProfit = monthSessions.fold(0.0, (s, x) => s + x.profit);
          final totalUnpaid = monthSessions.fold(0.0, (s, x) => s + x.totalUnpaid);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Summary cards ────────────────────────────────────────
              Row(
                children: [
                  StatCard(
                    label: 'Net Profit',
                    value: '$currency ${totalProfit.toStringAsFixed(2)}',
                    valueColor: totalProfit >= 0 ? AppColors.green : AppColors.red,
                    expanded: true,
                  ),
                  const SizedBox(width: 12),
                  StatCard(
                    label: 'Unpaid',
                    value: '$currency ${totalUnpaid.toStringAsFixed(2)}',
                    valueColor: AppColors.orange,
                    expanded: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const SectionHeader(title: 'Sessions This Month'),
              if (monthSessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Center(
                    child: Text(
                      'No sessions this month',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...monthSessions.map((s) {
                  final profit = s.profit;
                  final profitStr = profit >= 0
                      ? '+$currency ${profit.toStringAsFixed(2)}'
                      : '-$currency ${profit.abs().toStringAsFixed(2)}';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => SessionDetailScreen(session: s)),
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    s.location.isNotEmpty ? s.location : s.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    DateFormat('d MMM yyyy').format(s.date),
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              profitStr,
                              style: TextStyle(
                                color: profit >= 0 ? AppColors.green : AppColors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            StatusBadge.fromSessionStatus(s.status),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
            ],
          );
        },
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BottomSheetHandle(),
            const Text(
              'Export Report',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Choose export format',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            _exportOption('Export as Excel (.xlsx)', 'Includes full breakdown'),
            const SizedBox(height: 8),
            _exportOption('Export as PDF', 'Shareable summary'),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Export',
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Export feature coming soon'),
                    backgroundColor: AppColors.accent,
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _exportOption(String label, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.inputBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ),
          Text(sub,
              style:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }
}
