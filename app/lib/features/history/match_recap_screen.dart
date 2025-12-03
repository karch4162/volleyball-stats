import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'providers.dart';
import 'widgets/match_stats_summary.dart';
import 'widgets/player_performance_card.dart';
import 'widgets/set_summary_card.dart';

class MatchRecapScreen extends ConsumerWidget {
  const MatchRecapScreen({
    super.key,
    required this.matchId,
  });

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchDetailsAsync = ref.watch(matchDetailsProvider(matchId));

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
                if (details.playerPerformances.isNotEmpty) ...[
                  const Text(
                    'Player Performance',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...details.playerPerformances.map((performance) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PlayerPerformanceCard(performance: performance),
                      )),
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
              Text(
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
                  ref.invalidate(matchDetailsProvider(matchId));
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

