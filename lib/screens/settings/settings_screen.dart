import 'dart:io';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../theme/app_colors.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import '../players/player_database_screen.dart';
import '../templates/templates_screen.dart';
import 'capital_history_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _malePriceCtrl;
  late TextEditingController _femalePriceCtrl;
  final _picker = ImagePicker();
  bool _uploadingBank = false;
  bool _uploadingTng = false;

  @override
  void initState() {
    super.initState();
    final settings = context.read<AppProvider>().settings;
    _malePriceCtrl =
        TextEditingController(text: settings.defaultMalePrice.toStringAsFixed(2));
    _femalePriceCtrl =
        TextEditingController(text: settings.defaultFemalePrice.toStringAsFixed(2));
    // Refresh QR URLs from Firestore in background
    _syncQrFromFirestore();
  }

  @override
  void dispose() {
    _malePriceCtrl.dispose();
    _femalePriceCtrl.dispose();
    super.dispose();
  }

  /// On open, pull the latest imageUrl from Firestore so local settings stays in sync
  Future<void> _syncQrFromFirestore() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final db = FirebaseFirestore.instance;
      final userQrRef = db.collection('users').doc(uid).collection('payment_qr');
      final provider = context.read<AppProvider>();
      final settings = provider.settings;
      bool changed = false;

      final bankDoc = await userQrRef.doc('bank_qr').get();
      if (bankDoc.exists) {
        final url = bankDoc.data()?['imageUrl'] as String?;
        if (url != null && url.isNotEmpty && url != 'temporary') {
          settings.bankQrPath = url;
          changed = true;
        }
      }

      final tngDoc = await userQrRef.doc('tng_qr').get();
      if (tngDoc.exists) {
        final url = tngDoc.data()?['imageUrl'] as String?;
        if (url != null && url.isNotEmpty && url != 'temporary') {
          settings.tngQrPath = url;
          changed = true;
        }
      }

      if (changed) {
        await provider.updateSettings(settings);
        if (mounted) setState(() {});
      }
    } catch (_) {
      // Ignore — offline or no data yet
    }
  }

  Future<void> _pickQr(bool isBank) async {
    final provider = context.read<AppProvider>();
    // Compress image to keep it small (QR codes are simple, 70% quality is fine)
    final img = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 600,
      maxHeight: 600,
    );
    if (img == null) return;

    setState(() {
      if (isBank) {
        _uploadingBank = true;
      } else {
        _uploadingTng = true;
      }
    });

    try {
      // Read image bytes via XFile (handles Android content:// URIs correctly)
      final bytes = await img.readAsBytes();
      final base64Str = 'data:image/jpeg;base64,${base64Encode(bytes)}';

      // Check size — Firestore doc limit is 1MB
      final sizeKb = bytes.lengthInBytes / 1024;
      if (sizeKb > 900) {
        throw Exception(
            'Image too large (${sizeKb.toStringAsFixed(0)}KB). Please use a smaller image.');
      }

      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) throw Exception('Not signed in');

      final docId = isBank ? 'bank_qr' : 'tng_qr';

      // Save Base64 string under the user's own subcollection (covered by rules)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('payment_qr')
          .doc(docId)
          .set({
        'imageUrl': base64Str,
        'isActive': true,
        'type': isBank ? 'bank' : 'tng',
        'uploadedAt': FieldValue.serverTimestamp(),
      });

      // Also save locally for instant offline display
      final settings = provider.settings;
      if (isBank) {
        settings.bankQrPath = base64Str;
      } else {
        settings.tngQrPath = base64Str;
      }
      await provider.updateSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${isBank ? 'Bank' : 'TNG'} QR saved (${sizeKb.toStringAsFixed(0)}KB)'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed: $e'),
            backgroundColor: AppColors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isBank) {
            _uploadingBank = false;
          } else {
            _uploadingTng = false;
          }
        });
      }
    }
  }

  Future<void> _saveDefaults() async {
    final provider = context.read<AppProvider>();
    final s = provider.settings;
    s.defaultMalePrice =
        double.tryParse(_malePriceCtrl.text) ?? s.defaultMalePrice;
    s.defaultFemalePrice =
        double.tryParse(_femalePriceCtrl.text) ?? s.defaultFemalePrice;
    await provider.updateSettings(s);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Settings saved'),
            backgroundColor: AppColors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          final settings = provider.settings;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              // ── DEFAULT PRICING ───────────────────────────────────────
              const SectionHeader(title: 'Default Pricing'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    _settingRow('Male Player Price', _malePriceCtrl, 'RM'),
                    const SizedBox(height: 10),
                    const Divider(color: AppColors.border, height: 1),
                    const SizedBox(height: 10),
                    _settingRow('Female Player Price', _femalePriceCtrl, 'RM'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              // Currency display
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Expanded(
                      child: Text('Currency',
                          style: TextStyle(
                              color: AppColors.textPrimary, fontSize: 13)),
                    ),
                    Text('MYR (RM)',
                        style: TextStyle(
                            color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton(
                  onPressed: _saveDefaults,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.accent),
                    foregroundColor: AppColors.accent,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Save Defaults'),
                ),
              ),
              const SizedBox(height: 24),

              // ── CAPITAL ───────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'CAPITAL',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    if (provider.capitalEntries.isNotEmpty)
                      GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const CapitalHistoryScreen()),
                        ),
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            color: AppColors.accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.underline,
                            decorationColor: AppColors.accent,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Total Capital',
                              style: TextStyle(
                                  color: AppColors.textSecondary, fontSize: 12)),
                          const SizedBox(height: 2),
                          const Text('Track your deposited capital',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 10)),
                        ],
                      ),
                    ),
                    Text(
                      '${provider.settings.currency} ${provider.totalCapital.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.green,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              if (provider.capitalEntries.isNotEmpty) ...[
                ...provider.capitalEntries.take(3).map((e) => Padding(
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    e.note.isNotEmpty
                                        ? e.note
                                        : (e.amount >= 0 ? 'Deposit' : 'Withdraw'),
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13),
                                  ),
                                  Text(
                                    '${e.date.year}/${e.date.month.toString().padLeft(2, '0')}/${e.date.day.toString().padLeft(2, '0')}',
                                    style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              e.amount >= 0
                                  ? '${provider.settings.currency} ${e.amount.toStringAsFixed(2)}'
                                  : '- ${provider.settings.currency} ${e.amount.abs().toStringAsFixed(2)}',
                              style: TextStyle(
                                  color: e.amount >= 0 ? AppColors.green : AppColors.red,
                                  fontSize: 13),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _confirmDeleteCapital(
                                  context, provider, e.id),
                              child: const Icon(Icons.close_rounded,
                                  color: AppColors.textMuted, size: 18),
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showAddCapitalSheet(context, provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_rounded, color: AppColors.green, size: 16),
                            SizedBox(width: 6),
                            Text('Deposit',
                                style: TextStyle(color: AppColors.green, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _showWithdrawSheet(context, provider),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.remove_rounded, color: AppColors.red, size: 16),
                            SizedBox(width: 6),
                            Text('Withdraw',
                                style: TextStyle(color: AppColors.red, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── PAYMENT QR CODES ──────────────────────────────────────
              const SectionHeader(title: 'Payment QR Codes'),
              const Text(
                'Tap a card to upload from gallery — image is saved to Firebase',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _qrCard(
                    label: 'Bank Transfer',
                    imagePath: settings.bankQrPath,
                    isUploading: _uploadingBank,
                    onUpload: () => _pickQr(true),
                  ),
                  const SizedBox(width: 12),
                  _qrCard(
                    label: 'Touch n Go',
                    imagePath: settings.tngQrPath,
                    isUploading: _uploadingTng,
                    onUpload: () => _pickQr(false),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // ── MANAGE ────────────────────────────────────────────────
              const SectionHeader(title: 'Manage'),
              _navRow(
                context,
                icon: Icons.people_rounded,
                label: 'Player Database',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const PlayerDatabaseScreen()),
                ),
              ),
              const SizedBox(height: 8),
              _navRow(
                context,
                icon: Icons.copy_rounded,
                label: 'Templates',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TemplatesScreen()),
                ),
              ),
              const SizedBox(height: 24),

              // ── ACCOUNT ───────────────────────────────────────────────
              const SectionHeader(title: 'Account'),
              _navRow(
                context,
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                iconColor: AppColors.red,
                labelColor: AppColors.red,
                onTap: () => _confirmSignOut(context),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _qrCard({
    required String label,
    required String? imagePath,
    required bool isUploading,
    required VoidCallback onUpload,
  }) {
    final hasImage = imagePath != null && imagePath.isNotEmpty;
    final isBase64 = hasImage && imagePath.startsWith('data:image');
    final isNetwork = hasImage && imagePath.startsWith('http');

    Widget imageWidget;
    if (isUploading) {
      imageWidget = const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accent),
            ),
            SizedBox(height: 8),
            Text('Saving...',
                style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
          ],
        ),
      );
    } else if (hasImage) {
      imageWidget = ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: isBase64
            ? Image.memory(
                base64Decode(imagePath.split(',').last),
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_rounded,
                      color: AppColors.textMuted, size: 28),
                ),
              )
            : isNetwork
                ? Image.network(
                    imagePath,
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const Center(
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.accent)),
                    errorBuilder: (_, __, ___) => const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: AppColors.textMuted, size: 28),
                    ),
                  )
                : Image.file(File(imagePath), fit: BoxFit.contain),
      );
    } else {
      imageWidget = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.upload_rounded, color: AppColors.textMuted, size: 22),
          SizedBox(height: 4),
          Text('Tap to Upload',
              style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
        ],
      );
    }

    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: hasImage ? AppColors.accent.withValues(alpha: 0.4) : AppColors.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11)),
                const Spacer(),
                if (hasImage && !isUploading)
                  const Icon(Icons.cloud_done_rounded,
                      color: AppColors.green, size: 14),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: isUploading ? null : onUpload,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.inputBg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: imageWidget,
              ),
            ),
            if (hasImage && !isUploading) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onUpload,
                child: const Text(
                  'Tap image to replace',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _confirmDeleteCapital(
      BuildContext context, AppProvider provider, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Remove Entry?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text('This capital entry will be deleted.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
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

  void _showAddCapitalSheet(BuildContext context, AppProvider provider) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

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
            const Text('Add Capital',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Record deposited capital or other income',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: 16),
            DarkInputField(
              label: 'Amount (${provider.settings.currency})',
              hint: '0',
              controller: amtCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DarkInputField(
              label: 'Note',
              hint: 'e.g. Starting capital',
              controller: noteCtrl,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Save',
              onPressed: () async {
                final amount = double.tryParse(amtCtrl.text) ?? 0;
                if (amount <= 0) return;
                await provider.addCapitalEntry(
                    CapitalEntry(amount: amount, note: noteCtrl.text.trim()));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showWithdrawSheet(BuildContext context, AppProvider provider) {
    final amtCtrl = TextEditingController();
    final noteCtrl = TextEditingController();

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
            const Text('Withdraw',
                style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Current balance: ${provider.settings.currency} ${provider.totalCapital.toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 16),
            DarkInputField(
              label: 'Withdraw Amount (${provider.settings.currency})',
              hint: '0',
              controller: amtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            DarkInputField(
              label: 'Note',
              hint: 'e.g. Cash out',
              controller: noteCtrl,
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Confirm Withdraw',
              onPressed: () async {
                final amount = double.tryParse(amtCtrl.text) ?? 0;
                if (amount <= 0) return;
                await provider.addCapitalEntry(
                    CapitalEntry(amount: -amount, note: noteCtrl.text.trim()));
                if (ctx.mounted) Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingRow(
      String label, TextEditingController ctrl, String prefix) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 13)),
        ),
        SizedBox(
          width: 90,
          child: TextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            textAlign: TextAlign.right,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixText: '$prefix ',
              prefixStyle: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
              contentPadding: EdgeInsets.zero,
              fillColor: Colors.transparent,
              filled: false,
              isDense: true,
            ),
          ),
        ),
      ],
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text('Sign out?',
            style: TextStyle(color: AppColors.textPrimary)),
        content: const Text(
          'You will be returned to the sign-in screen.',
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
              await FirebaseAuth.instance.signOut();
              // AuthGate automatically navigates to SignInScreen
            },
            child: const Text('Sign out',
                style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  Widget _navRow(BuildContext context,
      {required IconData icon,
      required String label,
      required VoidCallback onTap,
      Color? iconColor,
      Color? labelColor}) {
    final iColor = iconColor ?? AppColors.accent;
    final lColor = labelColor ?? AppColors.textPrimary;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Icon(icon, color: iColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(color: lColor, fontSize: 13)),
            ),
            Icon(Icons.chevron_right_rounded,
                color: iconColor != null ? iconColor.withValues(alpha: 0.5) : AppColors.textMuted,
                size: 18),
          ],
        ),
      ),
    );
  }
}
