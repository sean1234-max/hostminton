import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final currency = provider.settings.currency;
          final chart = provider.last6MonthsProfit();
          final incomeExpense = provider.last6MonthsIncomeExpense();

          final totalIncome = provider.allTimeCollected;
          final totalExpenses = provider.allTimeCost;
          final netProfit = provider.allTimeProfit;
          final avgProfit = provider.sessions.isEmpty
              ? 0.0
              : provider.allTimeProfit / provider.sessions.length;

          // Best month
          String bestMonth = '-';
          double bestProfit = double.negativeInfinity;
          for (final e in chart) {
            final p = e['profit'] as double;
            if (p > bestProfit) {
              bestProfit = p;
              bestMonth = DateFormat('MMM yy').format(e['month'] as DateTime);
            }
          }
          if (bestProfit == double.negativeInfinity) bestMonth = '-';

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              const SectionHeader(title: 'Analytics'),
              // ── 3 stat cards ──────────────────────────────────────────
              Row(
                children: [
                  StatCard(
                    label: 'Income',
                    value: '$currency ${_fmt(totalIncome)}',
                    valueColor: AppColors.green,
                    expanded: true,
                  ),
                  const SizedBox(width: 8),
                  StatCard(
                    label: 'Expenses',
                    value: '$currency ${_fmt(totalExpenses)}',
                    valueColor: AppColors.red,
                    expanded: true,
                  ),
                  const SizedBox(width: 8),
                  StatCard(
                    label: 'Net Profit',
                    value: '$currency ${_fmt(netProfit)}',
                    valueColor:
                        netProfit >= 0 ? AppColors.green : AppColors.red,
                    expanded: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ── Monthly Profit Line Chart ──────────────────────────────
              const SectionHeader(title: 'Monthly Profit Trend'),
              Container(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                height: 200,
                child: _buildProfitLineChart(chart),
              ),
              const SizedBox(height: 20),
              // ── Income vs Expenses Bar Chart ───────────────────────────
              const SectionHeader(title: 'Income vs Expenses'),
              Container(
                padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                height: 200,
                child: _buildBarChart(incomeExpense),
              ),
              const SizedBox(height: 20),
              // ── Quick stats ───────────────────────────────────────────
              const SectionHeader(title: 'All Time Stats'),
              Row(
                children: [
                  StatCard(
                    label: 'Sessions',
                    value: '${provider.sessions.length}',
                    expanded: true,
                  ),
                  const SizedBox(width: 8),
                  StatCard(
                    label: 'Avg Profit',
                    value: '$currency ${avgProfit.toStringAsFixed(2)}',
                    valueColor:
                        avgProfit >= 0 ? AppColors.green : AppColors.red,
                    expanded: true,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  StatCard(
                    label: 'Best Month',
                    value: bestMonth,
                    valueColor: AppColors.accent,
                    expanded: true,
                  ),
                  const SizedBox(width: 8),
                  StatCard(
                    label: 'Shuttlecocks',
                    value: '${provider.totalShuttlecocksUsed}',
                    expanded: true,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProfitLineChart(List<Map<String, dynamic>> chart) {
    final profits = chart.map((e) => e['profit'] as double).toList();
    final allZero = profits.every((p) => p == 0);
    final spots = List.generate(
      profits.length,
      (i) => FlSpot(i.toDouble(), allZero ? 0 : profits[i]),
    );

    double minY = allZero ? -1 : profits.reduce((a, b) => a < b ? a : b);
    double maxY = allZero ? 1 : profits.reduce((a, b) => a > b ? a : b);
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
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
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
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
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
                radius: 3.5,
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
                  AppColors.accent.withValues(alpha: 0.2),
                  AppColors.accent.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarChart(List<Map<String, dynamic>> data) {
    double maxVal = 1;
    for (final e in data) {
      final income = e['income'] as double;
      final expense = e['expense'] as double;
      if (income > maxVal) maxVal = income;
      if (expense > maxVal) maxVal = expense;
    }

    return BarChart(
      BarChartData(
        maxY: maxVal * 1.15,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
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
                if (idx < 0 || idx >= data.length) return const SizedBox.shrink();
                final month = data[idx]['month'] as DateTime;
                return Text(
                  DateFormat('MMM').format(month),
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 9),
                );
              },
              reservedSize: 22,
            ),
          ),
        ),
        barGroups: List.generate(data.length, (i) {
          final income = data[i]['income'] as double;
          final expense = data[i]['expense'] as double;
          return BarChartGroupData(
            x: i,
            barRods: [
              BarChartRodData(
                toY: income,
                color: AppColors.green.withValues(alpha: 0.8),
                width: 8,
                borderRadius: BorderRadius.circular(3),
              ),
              BarChartRodData(
                toY: expense,
                color: AppColors.red.withValues(alpha: 0.8),
                width: 8,
                borderRadius: BorderRadius.circular(3),
              ),
            ],
            barsSpace: 3,
          );
        }),
        barTouchData: BarTouchData(enabled: false),
      ),
    );
  }

  String _fmt(double v) {
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(2);
  }
}
