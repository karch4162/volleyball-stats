import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'models/player_performance.dart';
import 'providers.dart';
import 'widgets/match_stats_summary.dart';
import 'widgets/player_performance_card_v2.dart';
import 'widgets/player_stats_controls.dart';
import 'widgets/set_summary_card.dart';

class MatchRecapScreen extends ConsumerStatefulWidget {
  const MatchRecapScreen({
    super.key,
    required this.matchId,
  });

  final String matchId;

  @override
  ConsumerState<MatchRecapScreen> createState() => _MatchRecapScreenState();
}

class _MatchRecapScreenState extends ConsumerState<MatchRecapScreen> {
  String _sortBy = 'efficiency';
  bool _ascending = false;

  @override
  Widget build(BuildContext context) {
    final matchDetailsAsync = ref.watch(matchDetailsProvider(widget.matchId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Match Recap'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _exportMatch(context, ref),
          ),
        ],
      ),
      body: matchDetailsAsync.when(
        data: (details) {
          if (details == null) {
            return const Center(
              child: Text('Match not found'),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Match header
                _MatchHeader(details: details),
                const SizedBox(height: 24),

                // Set summaries
                const Text(
                  'Sets',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                ...details.sets.map((set) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: SetSummaryCard(setSummary: set),
                    )),
                const SizedBox(height: 24),

                // Match statistics
                MatchStatsSummary(
                  totalRallies: details.totalRallies,
                  totalFBK: details.totalFBK,
                  totalTransitionPoints: details.totalTransitionPoints,
                  substitutions: details.substitutions,
                  timeouts: details.timeouts,
                ),
                const SizedBox(height: 24),

                // Player performances
                const Text(
                  'Player Performance',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Show message if no players found, otherwise show stats
                if (details.playerPerformances.isEmpty) ...[
                  const GlassLightContainer(
                    padding: EdgeInsets.all(24),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    child: Center(
                      child: Text(
                        'No player statistics available for this match',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Sort controls
                  PlayerStatsControls(
                    currentSortBy: _sortBy,
                    onSortChanged: (value) => setState(() => _sortBy = value),
                    ascending: _ascending,
                    onAscendingChanged: (value) => setState(() => _ascending = value),
                  ),
                  const SizedBox(height: 16),
                  
                  // Player stats cards
                  ...() {
                    final sorted = _sortPlayers(details.playerPerformances, _sortBy);
                    return sorted.asMap().entries.map((entry) {
                      final index = entry.key;
                      final player = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PlayerPerformanceCardV2(
                          performance: player,
                          expandedByDefault: index < 3, // Expand top 3 by default
                          showRank: _sortBy != 'jersey',
                          rank: _sortBy != 'jersey' ? index + 1 : null,
                        ),
                      );
                    });
                  }(),
                ],
              ],
            ),
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 64,
                color: AppColors.rose,
              ),
              const SizedBox(height: 16),
              const Text(
                'Error loading match details',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.invalidate(matchDetailsProvider(widget.matchId));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportMatch(BuildContext context, WidgetRef ref) async {
    // TODO: Implement match-specific export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality coming soon'),
      ),
    );
  }

  List<PlayerPerformance> _sortPlayers(List<PlayerPerformance> players, String sortBy) {
    final sorted = List<PlayerPerformance>.from(players);
    
    switch (sortBy) {
      case 'points':
        sorted.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
        break;
      case 'efficiency':
        sorted.sort((a, b) => b.attackEfficiency.compareTo(a.attackEfficiency));
        break;
      case 'kills':
        sorted.sort((a, b) => b.kills.compareTo(a.kills));
        break;
      case 'blocks':
        sorted.sort((a, b) => b.blocks.compareTo(a.blocks));
        break;
      case 'aces':
        sorted.sort((a, b) => b.aces.compareTo(a.aces));
        break;
      case 'servicePressure':
        sorted.sort((a, b) => b.servicePressure.compareTo(a.servicePressure));
        break;
      case 'digs':
        sorted.sort((a, b) => b.digs.compareTo(a.digs));
        break;
      case 'assists':
        sorted.sort((a, b) => b.assists.compareTo(a.assists));
        break;
      case 'fbk':
        sorted.sort((a, b) => b.fbk.compareTo(a.fbk));
        break;
      case 'jersey':
        sorted.sort((a, b) => a.jerseyNumber.compareTo(b.jerseyNumber));
        break;
      default:
        sorted.sort((a, b) => b.attackEfficiency.compareTo(a.attackEfficiency));
    }
    
    return _ascending ? sorted.reversed.toList() : sorted;
  }
}

class _MatchHeader extends StatelessWidget {
  const _MatchHeader({required this.details});

  final MatchDetails details;

  @override
  Widget build(BuildContext context) {
    final setsWon = details.sets.where((s) => s.isWin).length;
    final setsLost = details.sets.length - setsWon;

    return GlassLightContainer(
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      details.opponent,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('EEEE, MMMM d, y').format(details.matchDate),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                    if (details.location.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        details.location,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: setsWon > setsLost
                      ? AppColors.emerald.withOpacity(0.2)
                      : AppColors.rose.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: setsWon > setsLost ? AppColors.emerald : AppColors.rose,
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      setsWon > setsLost ? 'WIN' : 'LOSS',
                      style: TextStyle(
                        color: setsWon > setsLost ? AppColors.emerald : AppColors.rose,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$setsWon-$setsLost',
                      style: TextStyle(
                        color: setsWon > setsLost ? AppColors.emerald : AppColors.rose,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

