import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import '../sessions/create_session/create_session_screen.dart';

class TemplatesScreen extends StatelessWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Templates'),
        actions: [
          AppBarAction(
            label: '+ New',
            onTap: () => _showAddTemplate(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final templates = provider.templates;
          if (templates.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.copy_rounded,
                        color: AppColors.textMuted, size: 40),
                    const SizedBox(height: 16),
                    const Text(
                      'No Templates',
                      style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Save common session settings for quick reuse',
                      textAlign: TextAlign.center,
                      style:
                          TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: '+ New Template',
                      onPressed: () => _showAddTemplate(context),
                    ),
                  ],
                ),
              ),
            );
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          color: AppColors.textSecondary, size: 14),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Templates save default values — amounts can still be adjusted when creating a session.',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: templates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final t = templates[i];
                    return Dismissible(
                      key: Key(t.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 16),
                        decoration: BoxDecoration(
                          color: AppColors.red.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.red.withValues(alpha: 0.4)),
                        ),
                        child: const Icon(Icons.delete_outline_rounded,
                            color: AppColors.red),
                      ),
                      onDismissed: (_) => provider.deleteTemplate(t.id),
                      child: GestureDetector(
                        onTap: () => _useTemplate(context, t),
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
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.copy_rounded,
                                    color: AppColors.accent, size: 16),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t.name,
                                      style: const TextStyle(
                                          color: AppColors.textPrimary,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600),
                                    ),
                                    Text(
                                      t.location,
                                      style: const TextStyle(
                                          color: AppColors.textSecondary,
                                          fontSize: 11),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    'M RM${t.malePrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11),
                                  ),
                                  Text(
                                    'F RM${t.femalePrice.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right_rounded,
                                  color: AppColors.textMuted, size: 18),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _useTemplate(BuildContext context, Template t) {
    final session = Session(
      name: t.name,
      date: DateTime.now(),
      location: t.location,
      shuttlePricePerTube: t.shuttlePrice,
      tubeCount: t.tubeCount,
      courtFeePerHour: t.courtFee,
    );
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSessionScreen(template: session),
      ),
    );
  }

  void _showAddTemplate(BuildContext context) {
    final nameCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    final malePriceCtrl = TextEditingController(text: '23');
    final femalePriceCtrl = TextEditingController(text: '20');

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BottomSheetHandle(),
            const Text(
              'New Template',
              style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Text(
              'Save session defaults for quick reuse',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            DarkInputField(
                label: 'Name',
                hint: 'e.g. Tue Night',
                controller: nameCtrl),
            const SizedBox(height: 12),
            DarkInputField(
                label: 'Location',
                hint: 'e.g. Cheras Sports Hall',
                controller: locationCtrl),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: DarkInputField(
                      label: 'Male Price (RM)',
                      hint: '23',
                      controller: malePriceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DarkInputField(
                      label: 'Female Price (RM)',
                      hint: '20',
                      controller: femalePriceCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true)),
                ),
              ],
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Save Template',
              onPressed: () {
                final name = nameCtrl.text.trim();
                final loc = locationCtrl.text.trim();
                if (name.isEmpty || loc.isEmpty) return;
                context.read<AppProvider>().addTemplate(Template(
                      name: name,
                      location: loc,
                      malePrice:
                          double.tryParse(malePriceCtrl.text) ?? 23,
                      femalePrice:
                          double.tryParse(femalePriceCtrl.text) ?? 20,
                    ));
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
