import 'package:flutter/material.dart';
import '../../../../theme/app_colors.dart';
import '../../../../models/models.dart';
import '../../../../widgets/common_widgets.dart';

class Step1BasicInfo extends StatefulWidget {
  final Session session;
  final VoidCallback onNext;

  const Step1BasicInfo({super.key, required this.session, required this.onNext});

  @override
  State<Step1BasicInfo> createState() => _Step1BasicInfoState();
}

class _Step1BasicInfoState extends State<Step1BasicInfo> {
  late TextEditingController _locationCtrl;
  late TextEditingController _noteCtrl;
  late TextEditingController _startTimeCtrl;
  DateTime _date = DateTime.now();
  double _durationHours = 2.0;

  final List<double> _durationOptions = [1.0, 1.5, 2.0, 2.5, 3.0];

  @override
  void initState() {
    super.initState();
    _locationCtrl = TextEditingController(text: widget.session.location);
    _noteCtrl = TextEditingController(text: widget.session.note);
    _startTimeCtrl = TextEditingController(text: widget.session.startTime);
    _date = widget.session.date;
    // Try to restore duration
    if (widget.session.startTime.isNotEmpty && widget.session.endTime.isNotEmpty) {
      final h = sessionHoursBetween(widget.session.startTime, widget.session.endTime);
      if (h > 0 && h <= 3) _durationHours = h;
    }
  }

  @override
  void dispose() {
    _locationCtrl.dispose();
    _noteCtrl.dispose();
    _startTimeCtrl.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  String _calcEndTime() {
    final start = _startTimeCtrl.text;
    if (start.isEmpty) return '';
    final mins = _timeToMinutes(start);
    if (mins == null) return '';
    final total = mins + (_durationHours * 60).round();
    final h = (total % (24 * 60)) ~/ 60;
    final m = total % 60;
    final period = h >= 12 ? 'PM' : 'AM';
    final displayH = h > 12 ? h - 12 : (h == 0 ? 12 : h);
    return '$displayH:${m.toString().padLeft(2, '0')} $period';
  }

  int? _timeToMinutes(String t) {
    final s = t.trim().toUpperCase();
    final isPm = s.contains('PM');
    final isAm = s.contains('AM');
    final clean = s.replaceAll(RegExp(r'[APM\s]'), '');
    final parts = clean.split(':');
    if (parts.isEmpty || parts[0].isEmpty) return null;
    int hour = int.tryParse(parts[0]) ?? 0;
    int minute = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    if (isPm && hour != 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    return hour * 60 + minute;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickStartTime() async {
    TimeOfDay initTime = TimeOfDay.now();
    final mins = _timeToMinutes(_startTimeCtrl.text);
    if (mins != null) {
      initTime = TimeOfDay(hour: mins ~/ 60, minute: mins % 60);
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.accent,
            surface: AppColors.cardBg,
          ),
        ),
        child: child!,
      ),
    );
    if (picked == null || !mounted) return;
    setState(() => _startTimeCtrl.text = picked.format(context));
  }

  String _durationLabel(double h) {
    final whole = h.floor();
    final mins = ((h - whole) * 60).round();
    if (mins == 0) return '${whole}h';
    final fracStr = mins == 30 ? '5' : '0';
    return '$whole.${fracStr}h';
  }

  @override
  Widget build(BuildContext context) {
    final endTime = _calcEndTime();

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
                'BASIC INFO',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 11,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              // ── Date ──────────────────────────────────────────────────
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_rounded,
                          color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: 10),
                      const Text('Date',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const Spacer(),
                      Text(
                        _formatDate(_date),
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Start Time ────────────────────────────────────────────
              GestureDetector(
                onTap: _pickStartTime,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.inputBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          color: AppColors.textSecondary, size: 16),
                      const SizedBox(width: 10),
                      const Text('Start Time',
                          style: TextStyle(
                              color: AppColors.textSecondary, fontSize: 13)),
                      const Spacer(),
                      Text(
                        _startTimeCtrl.text.isNotEmpty
                            ? _startTimeCtrl.text
                            : 'Tap to set',
                        style: TextStyle(
                          color: _startTimeCtrl.text.isNotEmpty
                              ? AppColors.textPrimary
                              : AppColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              // ── Duration chips ────────────────────────────────────────
              const Text('Duration',
                  style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _durationOptions.map((h) {
                  final selected = _durationHours == h;
                  return GestureDetector(
                    onTap: () => setState(() => _durationHours = h),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.accent.withValues(alpha: 0.15)
                            : AppColors.inputBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? AppColors.accent : AppColors.border,
                        ),
                      ),
                      child: Text(
                        _durationLabel(h),
                        style: TextStyle(
                          color: selected
                              ? AppColors.accent
                              : AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: selected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (endTime.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.arrow_forward_rounded,
                        color: AppColors.accent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'End time: $endTime',
                      style: const TextStyle(
                          color: AppColors.accent, fontSize: 12),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              // ── Location ──────────────────────────────────────────────
              DarkInputField(
                label: 'Location / Court',
                hint: 'e.g. Cheras Sports Centre',
                controller: _locationCtrl,
              ),
              const SizedBox(height: 12),
              // ── Note ──────────────────────────────────────────────────
              DarkInputField(
                label: 'Notes (optional)',
                hint: 'Any additional notes...',
                controller: _noteCtrl,
                maxLines: 2,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Next',
          onPressed: () {
            final loc = _locationCtrl.text.trim();
            widget.session.name = loc.isNotEmpty
                ? loc
                : '${_date.day}/${_date.month}/${_date.year}';
            widget.session.date = _date;
            widget.session.startTime = _startTimeCtrl.text;
            widget.session.endTime = _calcEndTime();
            widget.session.location = loc;
            widget.session.note = _noteCtrl.text;
            widget.onNext();
          },
        ),
      ],
    );
  }
}
