import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../match_setup/providers.dart';
import 'models/player_performance.dart';
import 'providers.dart';
import 'widgets/match_trends_chart.dart';
import 'widgets/season_filters.dart';
import 'widgets/season_overview_card.dart';
import 'widgets/top_performers_widget.dart';

class SeasonDashboardScreen extends ConsumerStatefulWidget {
  const SeasonDashboardScreen({super.key});

  @override
  ConsumerState<SeasonDashboardScreen> createState() => _SeasonDashboardScreenState();
}

class _SeasonDashboardScreenState extends ConsumerState<SeasonDashboardScreen> {
  DateTime? _startDate;
  DateTime? _endDate;
  String? _selectedSeason;

  @override
  Widget build(BuildContext context) {
    final params = SeasonStatsParams(
      startDate: _startDate,
      endDate: _endDate,
      seasonLabel: _selectedSeason,
    );

    final seasonStatsAsync = ref.watch(seasonStatsProvider(params));
    final rosterAsync = ref.watch(matchSetupRosterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Season Dashboard'),
        backgroundColor: Colors.transparent,
      ),
      body: seasonStatsAsync.when(
        data: (stats) {
          return rosterAsync.when(
            data: (roster) {
              final playerPerformances = roster
                  .map((player) {
                    final playerStat = stats.playerStats[player.id];
                    if (playerStat == null) {
                      return null;
                    }
                    return PlayerPerformance.fromPlayerStats(
                      player: player,
                      kills: playerStat['kills'] ?? 0,
                      errors: playerStat['errors'] ?? 0,
                      attempts: playerStat['attempts'] ?? 0,
                      blocks: playerStat['blocks'] ?? 0,
                      aces: playerStat['aces'] ?? 0,
                    );
                  })
                  .whereType<PlayerPerformance>()
                  .toList();

              // Sort by different categories
              final topKills = List<PlayerPerformance>.from(playerPerformances)
                ..sort((a, b) => b.kills.compareTo(a.kills));
              final topEfficiency = List<PlayerPerformance>.from(playerPerformances)
                ..sort((a, b) => b.attackEfficiency.compareTo(a.attackEfficiency));
              final topBlocks = List<PlayerPerformance>.from(playerPerformances)
                ..sort((a, b) => b.blocks.compareTo(a.blocks));
              final topAces = List<PlayerPerformance>.from(playerPerformances)
                ..sort((a, b) => b.aces.compareTo(a.aces));

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Filters
                    SeasonFilters(
                      startDate: _startDate,
                      endDate: _endDate,
                      selectedSeason: _selectedSeason,
                      onStartDateChanged: (date) {
                        setState(() {
                          _startDate = date;
                        });
                      },
                      onEndDateChanged: (date) {
                        setState(() {
                          _endDate = date;
                        });
                      },
                      onSeasonChanged: (season) {
                        setState(() {
                          _selectedSeason = season;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Season overview
                    SeasonOverviewCard(
                      totalMatches: stats.totalMatches,
                      matchesWon: stats.matchesWon,
                      matchesLost: stats.matchesLost,
                      totalSetsWon: stats.totalSetsWon,
                      totalSetsLost: stats.totalSetsLost,
                      winRate: stats.kpis.winRate,
                    ),
                    const SizedBox(height: 24),

                    // Team statistics
                    const Text(
                      'Team Statistics',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GlassLightContainer(
                      padding: const EdgeInsets.all(16),
                      borderRadius: BorderRadius.circular(12),
                      child: Column(
                        children: [
                          _StatRow('Total FBK', stats.totalFBK.toString()),
                          const Divider(color: AppColors.borderMedium),
                          _StatRow('Avg FBK per Match', stats.totalMatches > 0
                              ? (stats.totalFBK / stats.totalMatches).toStringAsFixed(1)
                              : '0'),
                          const Divider(color: AppColors.borderMedium),
                          _StatRow('Total Transition Points', stats.totalTransitionPoints.toString()),
                          const Divider(color: AppColors.borderMedium),
                          _StatRow('Avg Rallies per Match', stats.totalMatches > 0
                              ? (stats.totalRallies / stats.totalMatches).toStringAsFixed(1)
                              : '0'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Top performers
                    if (topKills.isNotEmpty) ...[
                      const Text(
                        'Top Performers',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TopPerformersWidget(players: topKills, category: 'Kills'),
                      const SizedBox(height: 12),
                      TopPerformersWidget(players: topEfficiency, category: 'Attack Efficiency'),
                      const SizedBox(height: 12),
                      TopPerformersWidget(players: topBlocks, category: 'Blocks'),
                      const SizedBox(height: 12),
                      TopPerformersWidget(players: topAces, category: 'Aces'),
                      const SizedBox(height: 24),
                    ],

                    // Match trends (placeholder)
                    MatchTrendsChart(matches: []),
                  ],
                ),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(),
            ),
            error: (error, stackTrace) => Center(
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
                    'Error loading roster',
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
                      ref.invalidate(matchSetupRosterProvider);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
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
                'Error loading season stats',
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
                  ref.invalidate(seasonStatsProvider(params));
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.indigo,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

