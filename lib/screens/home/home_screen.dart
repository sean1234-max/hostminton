import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../sessions/create_session/create_session_screen.dart';
import '../sessions/session_detail_screen.dart';
import 'bank_balance_history_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final currency = provider.settings.currency;
          final bankBalance = provider.bankBalance;
          final capital = provider.totalCapital;
          final allCollected = provider.allTimeCollected;
          final allCost = provider.allTimeCost;
          final monthlyProfit = provider.monthlyProfit;
          final chart = provider.last6MonthsProfit();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── Bank Balance Card ─────────────────────────────────────
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BankBalanceHistoryScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border, width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'BANK BALANCE',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          const Text(
                            'View History',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 2),
                          const Icon(Icons.chevron_right_rounded,
                              color: AppColors.accent, size: 14),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$currency ${_fmt(bankBalance)}',
                        style: TextStyle(
                          color: bankBalance >= 0
                              ? AppColors.accent
                              : AppColors.red,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: AppColors.border, height: 1),
                      const SizedBox(height: 12),
                      _balanceRow(
                          'Capital',
                          '$currency ${_fmt(capital)}',
                          AppColors.textPrimary),
                      const SizedBox(height: 8),
                      _balanceRow(
                          '+ Collected',
                          '+$currency ${_fmt(allCollected)}',
                          AppColors.green),
                      const SizedBox(height: 8),
                      _balanceRow(
                          '- Costs',
                          '-$currency ${_fmt(allCost)}',
                          AppColors.red),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // ── Quick Stats 2×2 ───────────────────────────────────────
              Row(
                children: [
                  _quickStatCard(
                    icon: Icons.calendar_today_rounded,
                    label: 'Total Sessions',
                    value: '${provider.sessions.length}',
                  ),
                  const SizedBox(width: 10),
                  _quickStatCard(
                    icon: Icons.people_rounded,
                    label: 'Total Players',
                    value: '${provider.uniquePlayersCount}',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _quickStatCard(
                    icon: Icons.trending_up_rounded,
                    label: 'Monthly Profit',
                    value: '$currency ${_fmt(monthlyProfit)}',
                    valueColor: monthlyProfit >= 0 ? AppColors.green : AppColors.red,
                  ),
                  const SizedBox(width: 10),
                  _quickStatCard(
                    icon: Icons.sports_tennis_rounded,
                    label: 'Shuttlecocks',
                    value: '${provider.totalShuttlecocksUsed}',
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // ── Monthly Trend Chart ───────────────────────────────────
              const SectionHeader(title: 'Monthly Profit'),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                height: 160,
                child: _buildLineChart(chart),
              ),
              const SizedBox(height: 20),

              // ── Recent Sessions ───────────────────────────────────────
              const SectionHeader(title: 'Recent Sessions'),
              if (provider.sessions.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.sports_tennis_rounded,
                          color: AppColors.textMuted, size: 32),
                      const SizedBox(height: 12),
                      const Text(
                        'No sessions yet',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Create your first session to get started',
                        style:
                            TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      PrimaryButton(
                        label: 'Create Session',
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CreateSessionScreen()),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...provider.sessions.take(5).map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: SessionListTile(
                        session: s,
                        currency: currency,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => SessionDetailScreen(session: s)),
                        ),
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLineChart(List<Map<String, dynamic>> chart) {
    final profits = chart.map((e) => e['profit'] as double).toList();
    final allZero = profits.every((p) => p == 0);
    final spots = List.generate(
      profits.length,
      (i) => FlSpot(i.toDouble(), allZero ? 0 : profits[i]),
    );

    double minY = allZero ? -1 : (profits.reduce((a, b) => a < b ? a : b));
    double maxY = allZero ? 1 : (profits.reduce((a, b) => a > b ? a : b));
    // Add padding
    final range = (maxY - minY).abs();
    final pad = range == 0 ? 10.0 : range * 0.2;
    minY = minY - pad;
    maxY = maxY + pad;

    return LineChart(
      LineChartData(
        minY: minY,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          horizontalInterval: (maxY - minY) / 4,
          getDrawingHorizontalLine: (_) => FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
          drawVerticalLine: false,
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final idx = value.toInt();
                if (idx < 0 || idx >= chart.length) return const SizedBox.shrink();
                final month = chart[idx]['month'] as DateTime;
                return Text(
                  DateFormat('MMM').format(month),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 9,
                  ),
                );
              },
              reservedSize: 22,
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.accent,
            barWidth: 2.5,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, pct, bar, idx) => FlDotCirclePainter(
                radius: 3,
                color: AppColors.accent,
                strokeWidth: 0,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent.withValues(alpha: 0.25),
                  AppColors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _quickStatCard({
    required IconData icon,
    required String label,
    required String value,
    Color valueColor = AppColors.textPrimary,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label.toUpperCase(),
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 9,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: valueColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceRow(String label, String value, Color color) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
          ),
        ),
        Text(
          value,
          style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  String _fmt(double v) => v.abs() >= 1000
      ? '${(v / 1000).toStringAsFixed(1)}K'
      : v.toStringAsFixed(2);
}
