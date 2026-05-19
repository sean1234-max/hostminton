import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import 'payments/payment_tracking_screen.dart';

class SessionDetailScreen extends StatefulWidget {
  final Session session;

  const SessionDetailScreen({super.key, required this.session});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Session _session;

  @override
  void initState() {
    super.initState();
    _session = widget.session;
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showEditSheet(BuildContext context, AppProvider provider, Session session) {
    final locCtrl = TextEditingController(text: session.location);
    final startCtrl = TextEditingController(text: session.startTime);
    final endCtrl = TextEditingController(text: session.endTime);
    final noteCtrl = TextEditingController(text: session.note);
    const modelOptions = ['G2', 'Classic', 'Supreme', 'FS97'];
    String selModel = session.shuttleModel;
    bool showCustom = !modelOptions.contains(selModel);
    final customModelCtrl = TextEditingController(text: showCustom ? selModel : '');
    final shuttlePriceCtrl = TextEditingController(
        text: session.shuttlePricePerTube.toStringAsFixed(2));
    final totalUsedCtrl = TextEditingController(
        text: (session.finalShuttlecocksUsed ?? session.tubeCount * 12).toString());
    final courtFeeCtrl = TextEditingController(
        text: session.courtFeePerHour.toStringAsFixed(2));
    final courtHoursCtrl = TextEditingController(
        text: session.courtHoursBooked % 1 == 0
            ? session.courtHoursBooked.toStringAsFixed(0)
            : session.courtHoursBooked.toStringAsFixed(1));

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            left: 20, right: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 8,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BottomSheetHandle(),
                const Text('Edit Session',
                    style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DarkInputField(label: 'Location', hint: 'Venue name', controller: locCtrl),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(child: DarkInputField(label: 'Start Time', hint: '8:30 PM', controller: startCtrl)),
                  const SizedBox(width: 10),
                  Expanded(child: DarkInputField(label: 'End Time', hint: '10:30 PM', controller: endCtrl)),
                ]),
                const SizedBox(height: 10),
                DarkInputField(label: 'Note', hint: 'Optional', controller: noteCtrl),
                const SizedBox(height: 16),
                const Text('SHUTTLECOCK',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...modelOptions.map((m) {
                      final sel = selModel == m && !showCustom;
                      return GestureDetector(
                        onTap: () => setS(() { selModel = m; showCustom = false; }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: sel ? AppColors.accent.withValues(alpha: 0.15) : AppColors.inputBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? AppColors.accent : AppColors.border),
                          ),
                          child: Text(m, style: TextStyle(
                              color: sel ? AppColors.accent : AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: sel ? FontWeight.bold : FontWeight.normal)),
                        ),
                      );
                    }),
                    GestureDetector(
                      onTap: () => setS(() => showCustom = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: showCustom ? AppColors.accent.withValues(alpha: 0.15) : AppColors.inputBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: showCustom ? AppColors.accent : AppColors.border),
                        ),
                        child: Text('Custom', style: TextStyle(
                            color: showCustom ? AppColors.accent : AppColors.textPrimary,
                            fontSize: 13,
                            fontWeight: showCustom ? FontWeight.bold : FontWeight.normal)),
                      ),
                    ),
                  ],
                ),
                if (showCustom) ...[
                  const SizedBox(height: 10),
                  DarkInputField(label: 'Custom Model Name', hint: 'e.g. TiMa', controller: customModelCtrl,
                      onChanged: (v) => selModel = v),
                ],
                const SizedBox(height: 10),
                DarkInputField(
                    label: 'Price per tube (RM)', hint: '0', controller: shuttlePriceCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 10),
                DarkInputField(
                    label: 'Total shuttlecocks used', hint: '0', controller: totalUsedCtrl,
                    keyboardType: TextInputType.number),
                const SizedBox(height: 16),
                const Text('COURT FEE',
                    style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                DarkInputField(
                    label: 'Court price per hour (RM)', hint: '0', controller: courtFeeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 10),
                DarkInputField(
                    label: 'Total hours booked', hint: '2', controller: courtHoursCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Save Changes',
                  onPressed: () async {
                    session.location = locCtrl.text.trim();
                    session.startTime = startCtrl.text.trim();
                    session.endTime = endCtrl.text.trim();
                    session.note = noteCtrl.text.trim();
                    session.shuttleModel = showCustom
                        ? (customModelCtrl.text.trim().isNotEmpty ? customModelCtrl.text.trim() : 'Custom')
                        : selModel;
                    session.shuttlePricePerTube =
                        double.tryParse(shuttlePriceCtrl.text) ?? session.shuttlePricePerTube;
                    final totalUsed = int.tryParse(totalUsedCtrl.text) ?? 0;
                    session.finalShuttlecocksUsed = totalUsed > 0 ? totalUsed : null;
                    if (totalUsed > 0) session.tubeCount = (totalUsed / 12).ceil();
                    session.courtFeePerHour =
                        double.tryParse(courtFeeCtrl.text) ?? session.courtFeePerHour;
                    session.courtHoursBooked =
                        double.tryParse(courtHoursCtrl.text) ?? session.courtHoursBooked;
                    await provider.updateSession(session);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Delete Session?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'This session and all payment records will be permanently removed.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
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
              await provider.deleteSession(id);
              if (context.mounted) Navigator.pop(context);
            },
            child:
                const Text('Delete', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final live = provider.getSession(_session.id) ?? _session;
        final currency = provider.settings.currency;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              live.location.isNotEmpty ? live.location : live.name,
            ),
            actions: [
              AppBarAction(
                label: 'Edit',
                color: AppColors.accent,
                onTap: () => _showEditSheet(context, provider, live),
              ),
              AppBarAction(
                label: 'Delete',
                color: AppColors.red,
                onTap: () => _confirmDelete(context, provider, live.id),
              ),
            ],
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.accent,
              labelColor: AppColors.accent,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Costs'),
                Tab(text: 'Payments'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(session: live, currency: currency),
              _CostsTab(session: live, currency: currency),
              PaymentTrackingScreen(sessionId: live.id),
            ],
          ),
        );
      },
    );
  }
}

// ─── Overview Tab ─────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final Session session;
  final String currency;

  const _OverviewTab({required this.session, required this.currency});

  @override
  Widget build(BuildContext context) {
    final profit = session.profit;
    final profitColor = profit >= 0 ? AppColors.green : AppColors.red;
    final profitStr = profit >= 0
        ? '+$currency ${profit.toStringAsFixed(2)}'
        : '-$currency ${profit.abs().toStringAsFixed(2)}';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Profit card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'PROFIT',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                profitStr,
                style: TextStyle(
                    color: profitColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // 3 stat cards
        Row(
          children: [
            StatCard(
              label: 'Cost',
              value: '$currency ${session.totalCost.toStringAsFixed(2)}',
              expanded: true,
            ),
            const SizedBox(width: 8),
            StatCard(
              label: 'Due',
              value: '$currency ${session.totalDue.toStringAsFixed(2)}',
              expanded: true,
            ),
            const SizedBox(width: 8),
            StatCard(
              label: 'Collected',
              value: '$currency ${session.totalCollected.toStringAsFixed(2)}',
              valueColor: AppColors.green,
              expanded: true,
            ),
          ],
        ),
        const SizedBox(height: 16),
        // Session info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'SESSION INFO',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 12),
              _infoRow(
                  'Date',
                  '${session.date.day}/${session.date.month}/${session.date.year}'),
              if (session.startTime.isNotEmpty)
                _infoRow(
                    'Time',
                    '${session.startTime}'
                    '${session.endTime.isNotEmpty ? ' – ${session.endTime}' : ''}'
                    ' (${session.sessionHours.toStringAsFixed(1)} hrs)'),
              _infoRow('Location', session.location),
              _infoRow('Players', '${session.players.length}'),
              _infoRow('Shuttle Model', session.shuttleModel),
              if (session.note.isNotEmpty) _infoRow('Notes', session.note),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Unpaid list
        if (session.unpaidPlayers.isNotEmpty) ...[
          SectionHeader(
              title: 'Unpaid (${session.unpaidPlayers.length})'),
          ...session.unpaidPlayers.map((p) => Padding(
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
                      Expanded(
                        child: Text(p.name,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13)),
                      ),
                      Text(
                        '$currency ${p.remaining.toStringAsFixed(2)}',
                        style: const TextStyle(
                            color: AppColors.orange, fontSize: 12),
                      ),
                      const SizedBox(width: 8),
                      StatusBadge.fromPaymentStatus(p.status),
                    ],
                  ),
                ),
              )),
        ],
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

// ─── Costs Tab ─────────────────────────────────────────────────────────────

class _CostsTab extends StatelessWidget {
  final Session session;
  final String currency;

  const _CostsTab({required this.session, required this.currency});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SectionHeader(title: 'Cost Breakdown'),
        _costRow(
          'Shuttlecock',
          '$currency ${session.shuttleCost.toStringAsFixed(2)}',
          '${session.tubeCount} tubes (${session.shuttleModel}) × $currency${session.shuttlePricePerTube.toStringAsFixed(2)}',
        ),
        const SizedBox(height: 8),
        _costRow(
          'Court Fee',
          '$currency ${session.courtCost.toStringAsFixed(2)}',
          '$currency${session.courtFeePerHour.toStringAsFixed(2)}/hr × ${session.courtHoursBooked % 1 == 0 ? session.courtHoursBooked.toStringAsFixed(0) : session.courtHoursBooked.toStringAsFixed(1)} hr',
        ),
        ...session.extraExpenses.map((e) => Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _costRow(
                  e.category,
                  '$currency ${e.amount.toStringAsFixed(2)}',
                  e.note),
            )),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Expanded(
                child: Text('Total Cost',
                    style: TextStyle(
                        color: AppColors.textSecondary, fontSize: 13)),
              ),
              Text(
                '$currency ${session.totalCost.toStringAsFixed(2)}',
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _costRow(String label, String amount, String sub) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13)),
                if (sub.isNotEmpty)
                  Text(sub,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Text(amount,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
        ],
      ),
    );
  }
}
