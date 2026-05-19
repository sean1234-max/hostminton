import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common_widgets.dart';

// Step 5: Players Editor — add/edit/remove players, override amounts
class Step5PlayersEditor extends StatefulWidget {
  final Session session;
  final double malePrice;
  final double femalePrice;
  final VoidCallback onNext;

  const Step5PlayersEditor({
    super.key,
    required this.session,
    required this.malePrice,
    required this.femalePrice,
    required this.onNext,
  });

  @override
  State<Step5PlayersEditor> createState() => _Step5PlayersEditorState();
}

class _Step5PlayersEditorState extends State<Step5PlayersEditor> {
  late double _malePrice;
  late double _femalePrice;

  @override
  void initState() {
    super.initState();
    _malePrice = widget.malePrice;
    _femalePrice = widget.femalePrice;
    _applyDefaultPrices();
  }

  void _applyDefaultPrices() {
    for (final p in widget.session.players) {
      if (!p.isOverride) {
        p.amountDue = p.gender == Gender.female ? _femalePrice : _malePrice;
      }
    }
  }

  void _addPlayer() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _AddPlayerSheet(
        malePrice: _malePrice,
        femalePrice: _femalePrice,
        onAdd: (p) => setState(() => widget.session.players.add(p)),
      ),
    );
  }

  void _editPlayer(SessionPlayer player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _EditPlayerSheet(
        player: player,
        onSave: (name, amount) {
          setState(() {
            player.name = name;
            player.amountDue = amount;
            player.isOverride = true;
          });
        },
        onDelete: () => setState(() => widget.session.players.remove(player)),
        onFree: () => setState(() {
          player.isFree = true;
          player.payments.clear();
        }),
        onUnfree: () => setState(() => player.isFree = false),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maleCount =
        widget.session.players.where((p) => p.gender == Gender.male).length;
    final femaleCount =
        widget.session.players.where((p) => p.gender == Gender.female).length;

    return Column(
      children: [
        // ── Price config ───────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DEFAULT PRICES',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 10,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _PriceInput(
                        label: 'Male',
                        value: _malePrice,
                        onChanged: (v) {
                          setState(() {
                            _malePrice = v;
                            _applyDefaultPrices();
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _PriceInput(
                        label: 'Female',
                        value: _femalePrice,
                        onChanged: (v) {
                          setState(() {
                            _femalePrice = v;
                            _applyDefaultPrices();
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (widget.session.players.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    '$maleCount male · $femaleCount female · ${widget.session.players.length} total',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ],
            ),
          ),
        ),
        // ── Player list ────────────────────────────────────────────────
        Expanded(
          child: widget.session.players.isEmpty
              ? const Center(
                  child: Text(
                    'No players yet. Add one below.',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: widget.session.players.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final p = widget.session.players[i];
                    final nameDisplay =
                        p.gender == Gender.female ? '${p.name} (F)' : p.name;
                    return PlayerPaymentTile(
                      name: nameDisplay,
                      amount: p.amountDue,
                      status: p.status,
                      isOverride: p.isOverride,
                      onEdit: () => _editPlayer(p),
                    );
                  },
                ),
        ),
        // ── Buttons ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              OutlinedButton(
                onPressed: _addPlayer,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.border),
                  foregroundColor: AppColors.accent,
                  minimumSize: const Size(double.infinity, 46),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('+ Add Player'),
              ),
              const SizedBox(height: 8),
              PrimaryButton(label: 'Next', onPressed: widget.onNext),
            ],
          ),
        ),
      ],
    );
  }
}

class _PriceInput extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;

  const _PriceInput(
      {required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final ctrl = TextEditingController(text: value.toStringAsFixed(2));
    return Row(
      children: [
        Text('$label ',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
        Expanded(
          child: TextField(
            controller: ctrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(
                color: AppColors.textPrimary, fontSize: 13),
            decoration: const InputDecoration(
              prefixText: 'RM ',
              prefixStyle:
                  TextStyle(color: AppColors.textMuted, fontSize: 12),
            ),
            onChanged: (v) => onChanged(double.tryParse(v) ?? 0),
          ),
        ),
      ],
    );
  }
}

class _AddPlayerSheet extends StatefulWidget {
  final double malePrice;
  final double femalePrice;
  final ValueChanged<SessionPlayer> onAdd;

  const _AddPlayerSheet(
      {required this.malePrice,
      required this.femalePrice,
      required this.onAdd});

  @override
  State<_AddPlayerSheet> createState() => _AddPlayerSheetState();
}

class _AddPlayerSheetState extends State<_AddPlayerSheet> {
  final _nameCtrl = TextEditingController();
  Gender _gender = Gender.male;
  late TextEditingController _amtCtrl;

  @override
  void initState() {
    super.initState();
    _amtCtrl =
        TextEditingController(text: widget.malePrice.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetHandle(),
          const Text(
            'Add Player',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          DarkInputField(label: 'Name', hint: 'Player name', controller: _nameCtrl),
          const SizedBox(height: 12),
          const Text('Gender',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          const SizedBox(height: 8),
          Row(
            children: [
              _genderChip('Male', Gender.male),
              const SizedBox(width: 8),
              _genderChip('Female', Gender.female),
            ],
          ),
          const SizedBox(height: 12),
          DarkInputField(
            label: 'Amount',
            hint: '0',
            controller: _amtCtrl,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Add',
            onPressed: () {
              final name = _nameCtrl.text.trim();
              if (name.isEmpty) return;
              widget.onAdd(SessionPlayer(
                name: name,
                gender: _gender,
                amountDue: double.tryParse(_amtCtrl.text) ??
                    (_gender == Gender.female
                        ? widget.femalePrice
                        : widget.malePrice),
              ));
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String label, Gender g) {
    final selected = _gender == g;
    return GestureDetector(
      onTap: () => setState(() {
        _gender = g;
        _amtCtrl.text =
            (g == Gender.female ? widget.femalePrice : widget.malePrice)
                .toStringAsFixed(2);
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.inputBg,
          border: Border.all(
              color: selected ? AppColors.accent : AppColors.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.accent : AppColors.textPrimary,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _EditPlayerSheet extends StatefulWidget {
  final SessionPlayer player;
  final void Function(String name, double amount) onSave;
  final VoidCallback onDelete;
  final VoidCallback onFree;
  final VoidCallback onUnfree;

  const _EditPlayerSheet({
    required this.player,
    required this.onSave,
    required this.onDelete,
    required this.onFree,
    required this.onUnfree,
  });

  @override
  State<_EditPlayerSheet> createState() => _EditPlayerSheetState();
}

class _EditPlayerSheetState extends State<_EditPlayerSheet> {
  late TextEditingController _nameCtrl;
  late TextEditingController _amtCtrl;
  late bool _isFree;

  @override
  void initState() {
    super.initState();
    _isFree = widget.player.isFree;
    _nameCtrl = TextEditingController(text: widget.player.name);
    _amtCtrl =
        TextEditingController(text: widget.player.amountDue.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amtCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const BottomSheetHandle(),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Edit Player',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: () {
                  widget.onDelete();
                  Navigator.pop(context);
                },
                child: const Text('Delete',
                    style: TextStyle(color: AppColors.red)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DarkInputField(label: 'Name', controller: _nameCtrl),
          const SizedBox(height: 12),
          if (_isFree) ...[
            // Free status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: AppColors.purple.withValues(alpha: 0.4)),
              ),
              child: const Text(
                'Marked as FREE — no payment required',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.purple, fontSize: 13),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() => _isFree = false);
                widget.onUnfree();
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textSecondary,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Undo Free'),
            ),
          ] else ...[
            DarkInputField(
              label: 'Amount (override)',
              controller: _amtCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () {
                setState(() => _isFree = true);
                widget.onFree();
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
          ],
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Save',
            onPressed: () {
              if (!_isFree) {
                widget.onSave(
                  _nameCtrl.text.trim(),
                  double.tryParse(_amtCtrl.text) ?? widget.player.amountDue,
                );
              } else {
                // Just save the name, amount stays as-is
                widget.onSave(
                  _nameCtrl.text.trim(),
                  widget.player.amountDue,
                );
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
