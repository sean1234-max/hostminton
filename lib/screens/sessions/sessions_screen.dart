import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../widgets/common_widgets.dart';
import 'session_detail_screen.dart';
import 'create_session/create_session_screen.dart';

class SessionsScreen extends StatefulWidget {
  const SessionsScreen({super.key});

  @override
  State<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends State<SessionsScreen> {
  String _search = '';
  SessionStatus? _filterStatus;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sessions'),
        actions: [
          AppBarAction(
            label: 'Filter',
            onTap: () => _showFilterSheet(context),
          ),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          var sessions = provider.sessions.toList();
          if (_search.isNotEmpty) {
            sessions = sessions
                .where((s) =>
                    s.name.toLowerCase().contains(_search.toLowerCase()) ||
                    s.location.toLowerCase().contains(_search.toLowerCase()))
                .toList();
          }
          if (_filterStatus != null) {
            sessions = sessions.where((s) => s.status == _filterStatus).toList();
          }
          final currency = provider.settings.currency;

          return Column(
            children: [
              // ── Search bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search sessions or location...',
                    prefixIcon: const Icon(Icons.search_rounded,
                        color: AppColors.textSecondary, size: 18),
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
                      borderSide:
                          const BorderSide(color: AppColors.accent, width: 1.5),
                    ),
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // ── Session list ───────────────────────────────────────────
              Expanded(
                child: sessions.isEmpty
                    ? _EmptySessionsList(search: _search)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                        itemCount: sessions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final s = sessions[i];
                          return Dismissible(
                            key: Key(s.id),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.delete_outline_rounded,
                                  color: AppColors.red),
                            ),
                            confirmDismiss: (_) => showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: AppColors.cardBg,
                                title: const Text('Delete Session?',
                                    style:
                                        TextStyle(color: AppColors.textPrimary)),
                                content: const Text(
                                  'This action cannot be undone.',
                                  style: TextStyle(color: AppColors.textSecondary),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('Delete',
                                        style: TextStyle(color: AppColors.red)),
                                  ),
                                ],
                              ),
                            ),
                            onDismissed: (_) => provider.deleteSession(s.id),
                            child: SessionListTile(
                              session: s,
                              currency: currency,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        SessionDetailScreen(session: s)),
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 84),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateSessionScreen()),
          ),
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.dark,
          elevation: 0,
          child: const Icon(Icons.add_rounded),
        ),
      ),
    );
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(
        current: _filterStatus,
        onApply: (status) {
          setState(() => _filterStatus = status);
          Navigator.pop(context);
        },
      ),
    );
  }
}

class _EmptySessionsList extends StatelessWidget {
  final String search;
  const _EmptySessionsList({this.search = ''});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                search.isNotEmpty
                    ? Icons.search_off_rounded
                    : Icons.sports_tennis_rounded,
                color: AppColors.textMuted,
                size: 40,
              ),
              const SizedBox(height: 14),
              Text(
                search.isNotEmpty ? 'No results found' : 'No sessions yet',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                search.isNotEmpty
                    ? 'Try a different search term'
                    : 'Create your first session to get started',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13),
              ),
              if (search.isEmpty) ...[
                const SizedBox(height: 20),
                PrimaryButton(
                  label: 'Create Session',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CreateSessionScreen()),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final SessionStatus? current;
  final ValueChanged<SessionStatus?> onApply;

  const _FilterSheet({required this.current, required this.onApply});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  SessionStatus? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetHandle(),
          const Text(
            'Filter',
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text('Status:',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          _statusChip('All', null),
          const SizedBox(height: 8),
          _statusChip('Settled', SessionStatus.settled),
          const SizedBox(height: 8),
          _statusChip('Has Debt', SessionStatus.hasDebt),
          const SizedBox(height: 8),
          _statusChip('Loss', SessionStatus.loss),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Apply Filter',
            onPressed: () => widget.onApply(_selected),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _statusChip(String label, SessionStatus? value) {
    final selected = _selected == value;
    return GestureDetector(
      onTap: () => setState(() => _selected = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.12)
              : AppColors.inputBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.border,
          ),
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
