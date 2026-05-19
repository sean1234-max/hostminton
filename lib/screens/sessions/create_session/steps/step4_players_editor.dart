import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common_widgets.dart';
import '../../../../utils/emoji_utils.dart';

// Parses a WhatsApp/Telegram join list.
List<SessionPlayer> parsePastedList(String text, double malePrice, double femalePrice) {
  final lines = text.split('\n');
  final players = <SessionPlayer>[];
  final numberedLine = RegExp(r'^\s*(\d+)[\.|\)]\s*(.*)$');

  for (final raw in lines) {
    final match = numberedLine.firstMatch(raw);
    if (match == null) continue;

    String name = match.group(2)?.trim() ?? '';
    if (name.isEmpty) continue;

    final isFemale = hasEmoji(name);
    final cleanName = stripEmoji(name);
    if (cleanName.isEmpty) continue;

    final gender = isFemale ? Gender.female : Gender.male;
    players.add(SessionPlayer(
      name: cleanName,
      gender: gender,
      amountDue: isFemale ? femalePrice : malePrice,
    ));
  }
  return players;
}

// Step 4: Paste player list from WhatsApp/Telegram
class Step4PlayersPaste extends StatefulWidget {
  final Session session;
  final double malePrice;
  final double femalePrice;
  final VoidCallback onNext;

  const Step4PlayersPaste({
    super.key,
    required this.session,
    required this.malePrice,
    required this.femalePrice,
    required this.onNext,
  });

  @override
  State<Step4PlayersPaste> createState() => _Step4PlayersPasteState();
}

class _Step4PlayersPasteState extends State<Step4PlayersPaste> {
  final _pasteCtrl = TextEditingController();
  int _maleCount = 0;
  int _femaleCount = 0;
  bool _parsed = false;
  late double _malePrice;
  late double _femalePrice;

  @override
  void initState() {
    super.initState();
    _malePrice = widget.malePrice;
    _femalePrice = widget.femalePrice;
  }

  @override
  void dispose() {
    _pasteCtrl.dispose();
    super.dispose();
  }

  void _parse() {
    // Try to extract prices from the pasted text
    final ladiesMatch = RegExp(r'Ladies\s*:?\s*RM\s*(\d+)', caseSensitive: false)
        .firstMatch(_pasteCtrl.text);
    final gentsMatch =
        RegExp(r'Gentlemen\s*:?\s*RM\s*(\d+)', caseSensitive: false)
            .firstMatch(_pasteCtrl.text);
    if (ladiesMatch != null) {
      _femalePrice =
          double.tryParse(ladiesMatch.group(1) ?? '') ?? _femalePrice;
    }
    if (gentsMatch != null) {
      _malePrice =
          double.tryParse(gentsMatch.group(1) ?? '') ?? _malePrice;
    }

    final players = parsePastedList(_pasteCtrl.text, _malePrice, _femalePrice);
    setState(() {
      widget.session.players = players;
      _maleCount = players.where((p) => p.gender == Gender.male).length;
      _femaleCount = players.where((p) => p.gender == Gender.female).length;
      _parsed = players.isNotEmpty;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
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
                'PASTE PLAYER LIST',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Paste your WhatsApp / Telegram signup list.\n'
                'Players with emojis next to their names = female price.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pasteCtrl,
                maxLines: 10,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13),
                decoration: const InputDecoration(
                  hintText: 'Paste the full signup list here...',
                  hintStyle: TextStyle(color: AppColors.textMuted),
                ),
              ),
              if (_parsed) ...[
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.green, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            'Parsed ${widget.session.players.length} players',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _statRow('Male',
                          '$_maleCount  (RM ${_malePrice.toStringAsFixed(2)})'),
                      _statRow('Female',
                          '$_femaleCount  (RM ${_femalePrice.toStringAsFixed(2)})'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Name chips preview
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: widget.session.players.map((p) {
                      final isFemale = p.gender == Gender.female;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isFemale
                              ? AppColors.orange.withValues(alpha: 0.12)
                              : AppColors.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isFemale
                                ? AppColors.orange.withValues(alpha: 0.4)
                                : AppColors.accent.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          p.name,
                          style: TextStyle(
                            color: isFemale
                                ? AppColors.orange
                                : AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: _parsed ? 'Confirm & Next' : 'Parse List',
          onPressed: () {
            if (!_parsed) {
              _parse();
            } else {
              widget.onNext();
            }
          },
        ),
        if (_parsed) ...[
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => setState(() {
              _parsed = false;
              widget.session.players = [];
            }),
            child: const Text(
              'Re-paste list',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ],
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Row(
        children: [
          SizedBox(
            width: 52,
            child: Text(label,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontSize: 12)),
        ],
      ),
    );
  }
}
