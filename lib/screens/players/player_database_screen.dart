import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/app_colors.dart';
import '../../providers/app_provider.dart';
import '../../widgets/common_widgets.dart';
import 'player_profile_screen.dart';

enum _SortMode { nameAZ, mostSessions, highestDebt }

class PlayerDatabaseScreen extends StatefulWidget {
  const PlayerDatabaseScreen({super.key});

  @override
  State<PlayerDatabaseScreen> createState() => _PlayerDatabaseScreenState();
}

class _PlayerDatabaseScreenState extends State<PlayerDatabaseScreen> {
  String _search = '';
  _SortMode _sort = _SortMode.nameAZ;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Player Database')),
      body: Consumer<AppProvider>(
        builder: (context, provider, _) {
          // Collect unique names from all sessions
          final namesSet = <String>{};
          for (final s in provider.sessions) {
            for (final p in s.players) {
              namesSet.add(p.name);
            }
          }

          var names = namesSet.toList();

          // Apply search
          if (_search.isNotEmpty) {
            names = names
                .where((n) =>
                    n.toLowerCase().contains(_search.toLowerCase()))
                .toList();
          }

          // Compute stats map once for sorting & display
          final statsMap = {
            for (final n in names) n: provider.statsForPlayer(n)
          };

          // Apply sort
          switch (_sort) {
            case _SortMode.nameAZ:
              names.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
            case _SortMode.mostSessions:
              names.sort((a, b) =>
                  (statsMap[b]!['totalSessions'] as int)
                      .compareTo(statsMap[a]!['totalSessions'] as int));
            case _SortMode.highestDebt:
              names.sort((a, b) =>
                  provider.totalDebtForPlayer(b)
                      .compareTo(provider.totalDebtForPlayer(a)));
          }

          return Column(
            children: [
              // ── Search bar ─────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Search players...',
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
                      borderSide: const BorderSide(
                          color: AppColors.accent, width: 1.5),
                    ),
                    hintStyle:
                        const TextStyle(color: AppColors.textMuted),
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // ── Sort pills ─────────────────────────────────────────────
              SizedBox(
                height: 32,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  scrollDirection: Axis.horizontal,
                  children: [
                    _sortPill('Name A–Z', _SortMode.nameAZ),
                    const SizedBox(width: 8),
                    _sortPill('Most Sessions', _SortMode.mostSessions),
                    const SizedBox(width: 8),
                    _sortPill('Highest Debt', _SortMode.highestDebt),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // ── Summary chip ───────────────────────────────────────────
              if (names.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Row(
                    children: [
                      Text(
                        '${names.length} player${names.length == 1 ? '' : 's'}',
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),

              // ── List ───────────────────────────────────────────────────
              Expanded(
                child: names.isEmpty
                    ? Center(
                        child: Text(
                          _search.isNotEmpty
                              ? 'No players found'
                              : 'No players yet.\nPlayers appear when you create sessions.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                        itemCount: names.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final name = names[i];
                          final stats = statsMap[name]!;
                          final debt =
                              provider.totalDebtForPlayer(name);
                          final sessions =
                              stats['totalSessions'] as int;
                          final lastSeen =
                              stats['lastSeen'] as DateTime?;
                          final isSettled = debt <= 0;
                          final initial = name.isNotEmpty
                              ? name[0].toUpperCase()
                              : '?';

                          return GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => PlayerProfileScreen(
                                      playerName: name)),
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius:
                                    BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.border),
                              ),
                              child: Row(
                                children: [
                                  // Avatar
                                  Container(
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: AppColors.accent
                                          .withValues(alpha: 0.12),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        initial,
                                        style: const TextStyle(
                                          color: AppColors.accent,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),

                                  // Name + meta
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          name,
                                          style: const TextStyle(
                                              color:
                                                  AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight:
                                                  FontWeight.w600),
                                        ),
                                        const SizedBox(height: 3),
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons
                                                  .sports_tennis_rounded,
                                              color: AppColors.accent,
                                              size: 11,
                                            ),
                                            const SizedBox(width: 3),
                                            Text(
                                              '$sessions session${sessions == 1 ? '' : 's'}',
                                              style: const TextStyle(
                                                  color: AppColors
                                                      .textSecondary,
                                                  fontSize: 11),
                                            ),
                                            if (lastSeen != null) ...[
                                              const SizedBox(width: 8),
                                              const Icon(
                                                Icons
                                                    .schedule_rounded,
                                                color:
                                                    AppColors.textMuted,
                                                size: 11,
                                              ),
                                              const SizedBox(width: 3),
                                              Text(
                                                _formatDate(lastSeen),
                                                style: const TextStyle(
                                                    color: AppColors
                                                        .textMuted,
                                                    fontSize: 11),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Debt status
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        isSettled
                                            ? 'Settled'
                                            : 'RM ${debt.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: isSettled
                                              ? AppColors.textMuted
                                              : AppColors.orange,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      StatusBadge(
                                        label:
                                            isSettled ? 'OK' : 'Debt',
                                        bgColor: isSettled
                                            ? AppColors.green
                                                .withValues(alpha: 0.15)
                                            : AppColors.orange
                                                .withValues(alpha: 0.15),
                                        textColor: isSettled
                                            ? AppColors.green
                                            : AppColors.orange,
                                      ),
                                    ],
                                  ),
                                ],
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

  Widget _sortPill(String label, _SortMode mode) {
    final active = _sort == mode;
    return GestureDetector(
      onTap: () => setState(() => _sort = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? AppColors.accent : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? AppColors.accent : AppColors.textSecondary,
            fontSize: 12,
            fontWeight:
                active ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${d.day} ${months[d.month]}';
  }
}
