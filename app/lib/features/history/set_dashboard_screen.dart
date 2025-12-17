import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../rally_capture/providers.dart';
import 'models/player_performance.dart';
import 'providers.dart';
import 'widgets/player_performance_card_v2.dart';
import 'widgets/player_stats_controls.dart';

class SetDashboardScreen extends ConsumerStatefulWidget {
  const SetDashboardScreen({
    super.key,
    required this.matchId,
    required this.setNumber,
  });

  final String matchId;
  final int setNumber;

  @override
  ConsumerState<SetDashboardScreen> createState() => _SetDashboardScreenState();
}

class _SetDashboardScreenState extends ConsumerState<SetDashboardScreen> {
  String _sortBy = 'efficiency'; // Default sort by efficiency as requested
  bool _ascending = false; // Descending by default (highest first)

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(rallyCaptureSessionProvider(widget.matchId));
    final totals = ref.watch(runningTotalsProvider(widget.matchId));
    final playerStatsAsync = ref.watch(setPlayerStatsProvider(SetPlayerStatsParams(
      matchId: widget.matchId,
      setNumber: widget.setNumber,
    )));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Set ${widget.setNumber} Dashboard'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Set overview
            GlassLightContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  Text(
                    'Set ${widget.setNumber}',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatDisplay(
                        label: 'Rallies',
                        value: session.completedRallies.length.toString(),
                      ),
                      _StatDisplay(
                        label: 'FBK',
                        value: totals.fbk.toString(),
                      ),
                      _StatDisplay(
                        label: 'Wins',
                        value: totals.wins.toString(),
                      ),
                      _StatDisplay(
                        label: 'Losses',
                        value: totals.losses.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Running totals
            const Text(
              'Running Totals',
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
                  _RunningTotalRow(
                    icon: Icons.star_rounded,
                    label: 'First Ball Kills',
                    value: totals.fbk.toString(),
                    color: AppColors.indigo,
                  ),
                  const Divider(color: AppColors.borderMedium),
                  _RunningTotalRow(
                    icon: Icons.check_circle_rounded,
                    label: 'Wins',
                    value: totals.wins.toString(),
                    color: AppColors.emerald,
                  ),
                  const Divider(color: AppColors.borderMedium),
                  _RunningTotalRow(
                    icon: Icons.cancel_rounded,
                    label: 'Losses',
                    value: totals.losses.toString(),
                    color: AppColors.rose,
                  ),
                  const Divider(color: AppColors.borderMedium),
                  _RunningTotalRow(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Transition Points',
                    value: totals.transitionPoints.toString(),
                    color: AppColors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Player Performance Section
            const Text(
              'Player Performance',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            
            // Sort controls
            PlayerStatsControls(
              currentSortBy: _sortBy,
              onSortChanged: (value) => setState(() => _sortBy = value),
              ascending: _ascending,
              onAscendingChanged: (value) => setState(() => _ascending = value),
            ),
            const SizedBox(height: 16),
            
            // Player stats list
            playerStatsAsync.when(
              data: (players) {
                if (players.isEmpty) {
                  return const GlassLightContainer(
                    padding: EdgeInsets.all(24),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                    child: Center(
                      child: Text(
                        'No player statistics available for this set',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }
                
                final sortedPlayers = _sortPlayers(players, _sortBy);
                
                return Column(
                  children: sortedPlayers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final player = entry.value;
                    return Padding(
                      key: ValueKey('player-perf-${player.playerId}'),
                      padding: const EdgeInsets.only(bottom: 12),
                      child: PlayerPerformanceCardV2(
                        performance: player,
                        expandedByDefault: index < 3, // Expand top 3 by default
                        showRank: _sortBy != 'jersey',
                        rank: _sortBy != 'jersey' ? index + 1 : null,
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, stack) => GlassLightContainer(
                padding: const EdgeInsets.all(20),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
                child: Column(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      size: 48,
                      color: AppColors.rose,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Error loading player stats',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

class _StatDisplay extends StatelessWidget {
  const _StatDisplay({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _RunningTotalRow extends StatelessWidget {
  const _RunningTotalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}


