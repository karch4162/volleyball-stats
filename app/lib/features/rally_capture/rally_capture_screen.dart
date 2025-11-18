import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import 'providers.dart';
import 'models/rally_models.dart';
import '../match_setup/match_setup_flow.dart';
import '../match_setup/models/match_player.dart';
import '../export/export_screen.dart';

class RallyCaptureScreen extends ConsumerWidget {
  const RallyCaptureScreen({
    super.key,
    required this.matchId,
  });

  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(rallyCaptureStateProvider(matchId));

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _CustomAppBar(
            matchId: matchId,
            onEdit: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MatchSetupFlow(matchId: matchId),
                ),
              );
              if (!context.mounted) return;
              ref.invalidate(rallyCaptureStateProvider(matchId));
            },
            onExport: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ExportScreen(),
                ),
              );
            },
            onPlayerStats: () async {
              await _showPlayerStatsDialog(context, ref, matchId);
            },
          ),
          Expanded(
            child: asyncState.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.indigo),
        ),
        error: (error, stackTrace) => _ErrorState(
          error: error,
          onRetry: () => ref.refresh(rallyCaptureStateProvider(matchId)),
        ),
              data: (state) => _RallyCaptureBody(state: state, matchId: matchId),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _BottomNavigationBar(),
    );
  }

  static Future<void> _showPlayerStatsDialog(
    BuildContext context,
    WidgetRef ref,
    String matchId,
  ) async {
    final playerStats = ref.read(playerStatsProvider(matchId));
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Player Statistics'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: playerStats.length,
            itemBuilder: (context, index) {
              final stats = playerStats[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '#${stats.player.jerseyNumber} ${stats.player.name}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _StatChip('K', stats.attackKills),
                          _StatChip('E', stats.attackErrors),
                          _StatChip('A', stats.attackAttempts),
                          _StatChip('B', stats.blocks),
                          _StatChip('D', stats.digs),
                          _StatChip('Asst', stats.assists),
                          _StatChip('SA', stats.serveAces),
                          _StatChip('SE', stats.serveErrors),
                          _StatChip('FBK', stats.fbk),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip(this.label, this.value);

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      labelStyle: Theme.of(context).textTheme.bodySmall,
    );
  }
}

class _CustomAppBar extends StatelessWidget {
  const _CustomAppBar({
    required this.matchId,
    required this.onEdit,
    required this.onExport,
    required this.onPlayerStats,
  });

  final String matchId;
  final VoidCallback onEdit;
  final VoidCallback onExport;
  final VoidCallback onPlayerStats;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.zero,
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            const Text(
              'RC',
              style: TextStyle(
                color: AppColors.indigo,
                fontSize: 18,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.5,
              ),
            ),
            Container(
              width: 1,
              height: 16,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: AppColors.textDivider,
            ),
            const Text(
              'Rally Capture',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 20),
              color: AppColors.textTertiary,
              onPressed: onEdit,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                hoverColor: AppColors.hoverOverlay,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.download_rounded, size: 20),
              color: AppColors.textTertiary,
              onPressed: onExport,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                hoverColor: AppColors.hoverOverlay,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.people_rounded, size: 20),
              color: AppColors.textTertiary,
              onPressed: onPlayerStats,
              style: IconButton.styleFrom(
                backgroundColor: Colors.transparent,
                hoverColor: AppColors.hoverOverlay,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RallyCaptureBody extends ConsumerWidget {
  const _RallyCaptureBody({
    required this.state,
    required this.matchId,
  });

  final RallyCaptureState state;
  final String matchId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(rallyCaptureSessionProvider(matchId));
    final sessionController =
        ref.read(rallyCaptureSessionProvider(matchId).notifier);
    final totals = ref.watch(runningTotalsProvider(matchId));
    final playerStats = ref.watch(playerStatsProvider(matchId));

    Future<void> onQuickPlayerAction(MatchPlayer player, RallyActionTypes type) async {
      HapticFeedback.lightImpact();
      sessionController.logAction(type, player: player);
      
      if (type == RallyActionTypes.firstBallKill) {
        await sessionController.completeRallyWithWin(player: player, actionType: type);
        _showSnackBar(context, 'FBK by #${player.jerseyNumber}!');
      }
    }

    Future<void> onPoint() async {
      HapticFeedback.mediumImpact();
      final completed = await sessionController.completeRallyWithWin();
      if (completed) {
        _showSnackBar(context, 'Point scored!');
      } else {
        _showSnackBar(context, 'Add an action before completing the rally.');
      }
    }

    Future<void> onRotate() async {
      HapticFeedback.lightImpact();
      // TODO: Implement rotation logic
      _showSnackBar(context, 'Rotation feature coming soon');
    }

    void onUndo() {
      final success = sessionController.undo();
      if (!success) {
        _showSnackBar(context, 'Nothing to undo.');
      } else {
        HapticFeedback.lightImpact();
      }
    }

    Future<void> onTimeout() async {
      final selection = await _showTimeoutDialog(context);
      if (selection == null) return;
      sessionController.logAction(
        RallyActionTypes.timeout,
        note: selection,
      );
    }

    Future<void> onSubstitution() async {
      if (!totals.canSubstitute) {
        _showSnackBar(
            context, 'Substitution limit reached (15 per set). Cannot substitute.');
        return;
      }
      
      if (state.activePlayers.isEmpty) {
        _showSnackBar(
            context, 'Assign active players before recording a substitution.');
        return;
      }
      if (state.benchPlayers.isEmpty) {
        _showSnackBar(context, 'No bench players available for substitution.');
        return;
      }
      final selection = await _showSubstitutionDialog(
        context,
        activePlayers: state.activePlayers,
        benchPlayers: state.benchPlayers,
        substitutionsRemaining: totals.substitutionsRemaining,
      );
      if (selection == null) return;
      sessionController.logAction(
        RallyActionTypes.substitution,
        note:
            'Out: #${selection.outgoing.jerseyNumber} ${selection.outgoing.name} • In: #${selection.incoming.jerseyNumber} ${selection.incoming.name}',
      );
    }

    final matchInfo = [
      if (state.draft.opponent.isNotEmpty) state.draft.opponent,
      if (state.draft.matchDate != null)
        MaterialLocalizations.of(context)
            .formatMediumDate(state.draft.matchDate!),
    ].join(' • ');

    // Get top 3 players by stats (prioritize kills, then assists, then blocks)
    final topPlayers = playerStats.take(3).toList();

    // Get recent rallies (last 4)
    final recentRallies = session.completedRallies
        .take(4)
        .toList()
        .reversed
        .toList();

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Match Header
          Padding(
            padding: const EdgeInsets.all(16),
            child: GlassAccentContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.school_rounded,
                        size: 14,
                        color: AppColors.textTertiary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        matchInfo.isEmpty ? 'Match' : matchInfo,
                        style: const TextStyle(
                          color: AppColors.textTertiary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Our Team',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totals.wins}',
                              style: const TextStyle(
                                color: AppColors.indigoLight,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.surface.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Set',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '1',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              state.draft.opponent.isNotEmpty
                                  ? state.draft.opponent
                                  : 'Opponent',
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${totals.losses}',
                              style: const TextStyle(
                                color: AppColors.roseLight,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Current Set Score
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: GlassLightContainer(
              padding: const EdgeInsets.all(12),
              borderRadius: BorderRadius.circular(16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Current Set',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totals.wins}',
                          style: const TextStyle(
                            color: AppColors.indigoLight,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 48,
                    color: AppColors.textDivider,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Current Set',
                          style: TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${totals.losses}',
                          style: const TextStyle(
                            color: AppColors.roseLight,
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Quick Actions
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Point',
                    color: AppColors.indigo,
                    onPressed: onPoint,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.undo_rounded,
                    label: 'Undo',
                    color: AppColors.amber,
                    onPressed: session.canUndo ? onUndo : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'Rotate',
                    color: AppColors.emerald,
                    onPressed: onRotate,
                  ),
                ),
              ],
            ),
          ),

          // Player Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Player Stats',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        RallyCaptureScreen._showPlayerStatsDialog(
                          context,
                          ref,
                          matchId,
                        );
                      },
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          color: AppColors.indigo,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (topPlayers.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No player stats yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...topPlayers.map((stats) => _PlayerStatCard(
                        stats: stats,
                        onAction: onQuickPlayerAction,
                      )),
              ],
            ),
          ),

          // Recent Rallies
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Rallies',
                      style: TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'Filter',
                        style: TextStyle(
                          color: AppColors.indigo,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (recentRallies.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No rallies yet',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  ...recentRallies.map((rally) => _RallyItem(rally: rally)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassLightContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      onTap: onPressed,
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayerStatCard extends StatelessWidget {
  const _PlayerStatCard({
    required this.stats,
    required this.onAction,
  });

  final PlayerStats stats;
  final Future<void> Function(MatchPlayer, RallyActionTypes) onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassLightContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.indigoDark.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${stats.player.jerseyNumber}',
                          style: const TextStyle(
                            color: AppColors.indigoLight,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          stats.player.name,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          stats.player.position,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    _StatBadge('K', stats.attackKills, AppColors.indigoLight),
                    const SizedBox(width: 4),
                    Container(width: 1, height: 12, color: AppColors.textDivider),
                    const SizedBox(width: 4),
                    _StatBadge('A', stats.assists, AppColors.emeraldLight),
                    const SizedBox(width: 4),
                    Container(width: 1, height: 12, color: AppColors.textDivider),
                    const SizedBox(width: 4),
                    _StatBadge('B', stats.blocks, AppColors.amberLight),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.flash_on_rounded,
                    label: 'Kill',
                    color: AppColors.indigo,
                    onPressed: () => onAction(stats.player, RallyActionTypes.attackKill),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.gps_fixed_rounded,
                    label: 'Ace',
                    color: AppColors.emerald,
                    onPressed: () => onAction(stats.player, RallyActionTypes.serveAce),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.shield_rounded,
                    label: 'Block',
                    color: AppColors.amber,
                    onPressed: () => onAction(stats.player, RallyActionTypes.block),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.cancel_rounded,
                    label: 'Error',
                    color: AppColors.rose,
                    onPressed: () => onAction(stats.player, RallyActionTypes.attackError),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  const _StatBadge(this.label, this.value, this.color);

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textDisabled,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 8),
      borderRadius: BorderRadius.circular(8),
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      blurAmount: 0,
      onTap: onPressed,
      child: Column(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _RallyItem extends StatelessWidget {
  const _RallyItem({required this.rally});

  final RallyRecord rally;

  IconData _getActionIcon(RallyActionTypes type) {
    switch (type) {
      case RallyActionTypes.attackKill:
      case RallyActionTypes.firstBallKill:
        return Icons.flash_on_rounded;
      case RallyActionTypes.serveAce:
        return Icons.gps_fixed_rounded;
      case RallyActionTypes.block:
        return Icons.shield_rounded;
      case RallyActionTypes.attackError:
      case RallyActionTypes.serveError:
        return Icons.cancel_rounded;
      default:
        return Icons.circle_outlined;
    }
  }

  Color _getActionColor(RallyActionTypes type) {
    switch (type) {
      case RallyActionTypes.attackKill:
      case RallyActionTypes.firstBallKill:
        return AppColors.indigo;
      case RallyActionTypes.serveAce:
        return AppColors.emerald;
      case RallyActionTypes.block:
        return AppColors.amber;
      case RallyActionTypes.attackError:
      case RallyActionTypes.serveError:
        return AppColors.rose;
      default:
        return AppColors.textMuted;
    }
  }

  String _getRallyDescription() {
    final pointEvent = rally.events.firstWhere(
      (e) => e.type.isPointScoring || e.type.isError,
      orElse: () => rally.events.first,
    );
    
    if (pointEvent.player != null) {
      return '${pointEvent.type.label} by ${pointEvent.player!.name}';
    }
    return pointEvent.type.label;
  }

  String _getRallySubtext() {
    final pointEvent = rally.events.firstWhere(
      (e) => e.type.isPointScoring || e.type.isError,
      orElse: () => rally.events.first,
    );
    
    final parts = <String>[];
    if (pointEvent.type == RallyActionTypes.attackKill) {
      parts.add('Outside attack');
    } else if (pointEvent.type == RallyActionTypes.serveAce) {
      parts.add('Service ace');
    } else if (pointEvent.type == RallyActionTypes.block) {
      parts.add('Solo block');
    } else if (pointEvent.type.isError) {
      parts.add('Out of bounds');
    }
    
    // Calculate score at time of rally (simplified - would need proper tracking)
    parts.add('${rally.rallyNumber}-${rally.rallyNumber}');
    
    return parts.join(' • ');
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final diff = now.difference(rally.completedAt);
    
    if (diff.inMinutes < 1) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return '${diff.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pointEvent = rally.events.firstWhere(
      (e) => e.type.isPointScoring || e.type.isError,
      orElse: () => rally.events.first,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassLightContainer(
        padding: const EdgeInsets.all(12),
        borderRadius: BorderRadius.circular(16),
        onTap: () {},
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: _getActionColor(pointEvent.type).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getActionIcon(pointEvent.type),
                color: _getActionColor(pointEvent.type),
                size: 14,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _getRallyDescription(),
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getRallySubtext(),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Text(
              _getTimeAgo(),
              style: const TextStyle(
                color: AppColors.textDisabled,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      margin: EdgeInsets.zero,
      borderRadius: BorderRadius.zero,
      borderColor: AppColors.borderLight,
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(
              icon: Icons.home_rounded,
              label: 'Match',
              isActive: true,
            ),
            _NavItem(
              icon: Icons.bar_chart_rounded,
              label: 'Stats',
              isActive: false,
            ),
            _NavItem(
              icon: Icons.list_rounded,
              label: 'Roster',
              isActive: false,
            ),
            _NavItem(
              icon: Icons.settings_rounded,
              label: 'Settings',
              isActive: false,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.isActive,
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: isActive ? AppColors.indigo : AppColors.textMuted,
          size: 20,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: isActive ? AppColors.indigo : AppColors.textMuted,
            fontSize: isActive ? 12 : 12,
            fontWeight: isActive ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: AppColors.glass,
    ),
  );
}

Future<MatchPlayer?> _showPlayerPicker(
  BuildContext context, {
  required List<MatchPlayer> players,
  required String title,
}) async {
  if (players.isEmpty) {
    _showSnackBar(context, 'No players available for this action.');
    return null;
  }

  return showModalBottomSheet<MatchPlayer>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) => GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(title),
              subtitle: const Text('Select the player involved'),
            ),
            ...players.map(
              (player) => ListTile(
                title: Text('#${player.jerseyNumber} ${player.name}'),
                subtitle: Text(player.position),
                onTap: () => Navigator.of(context).pop(player),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Future<String?> _showTimeoutDialog(BuildContext context) {
  return showDialog<String>(
    context: context,
    builder: (context) => SimpleDialog(
      title: const Text('Record Timeout'),
      children: [
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop('Our Timeout'),
          child: const Text('Our Timeout'),
        ),
        SimpleDialogOption(
          onPressed: () => Navigator.of(context).pop('Opponent Timeout'),
          child: const Text('Opponent Timeout'),
        ),
      ],
    ),
  );
}

class _SubstitutionSelection {
  const _SubstitutionSelection({
    required this.outgoing,
    required this.incoming,
  });

  final MatchPlayer outgoing;
  final MatchPlayer incoming;
}

Future<_SubstitutionSelection?> _showSubstitutionDialog(
  BuildContext context, {
  required List<MatchPlayer> activePlayers,
  required List<MatchPlayer> benchPlayers,
  int? substitutionsRemaining,
}) {
  return showDialog<_SubstitutionSelection>(
    context: context,
    builder: (context) {
      MatchPlayer? outgoing;
      MatchPlayer? incoming;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Record Substitution'),
                if (substitutionsRemaining != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    '$substitutionsRemaining substitutions remaining',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<MatchPlayer>(
                  value: outgoing,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Player Out'),
                  items: activePlayers
                      .map(
                        (player) => DropdownMenuItem<MatchPlayer>(
                          value: player,
                          child: Text('#${player.jerseyNumber} ${player.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => outgoing = value),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<MatchPlayer>(
                  value: incoming,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Player In'),
                  items: benchPlayers
                      .map(
                        (player) => DropdownMenuItem<MatchPlayer>(
                          value: player,
                          child: Text('#${player.jerseyNumber} ${player.name}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => incoming = value),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: outgoing != null && incoming != null
                    ? () => Navigator.of(context).pop(
                          _SubstitutionSelection(
                              outgoing: outgoing!, incoming: incoming!),
                        )
                    : null,
                child: const Text('Record'),
              ),
            ],
          );
        },
      );
    },
  );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Failed to load rally capture state:\n$error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
