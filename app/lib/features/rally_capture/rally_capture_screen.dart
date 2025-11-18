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
import '../teams/team_providers.dart';

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
            onEndMatch: () async {
              await _showEndMatchDialog(context, ref, matchId);
            },
            onNewSet: () async {
              await _showNewSetDialog(context, ref, matchId);
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

  static Future<void> _showEndMatchDialog(
    BuildContext context,
    WidgetRef ref,
    String matchId,
  ) async {
    final totals = ref.read(runningTotalsProvider(matchId));
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End Match'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you sure you want to end this match?'),
            const SizedBox(height: 16),
            Text(
              'Final Score: ${totals.wins} - ${totals.losses}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total Rallies: ${totals.totalRallies}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              // TODO: Mark match as completed in database
              // For now, just show a message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Match ended. Final score saved.'),
                  duration: Duration(seconds: 2),
                ),
              );
              // Navigate back to home/match list
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.rose,
            ),
            child: const Text('End Match'),
          ),
        ],
      ),
    );
  }

  static Future<void> _showNewSetDialog(
    BuildContext context,
    WidgetRef ref,
    String matchId,
  ) async {
    final session = ref.read(rallyCaptureSessionProvider(matchId));
    final totals = ref.read(runningTotalsProvider(matchId));
    final newSetNumber = session.currentSetNumber + 1;
    
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Start Set $newSetNumber'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Set ${session.currentSetNumber} Score: ${totals.wins} - ${totals.losses}'),
            const SizedBox(height: 16),
            const Text('Starting a new set will:'),
            const SizedBox(height: 8),
            const Text('• Reset rally counter to 1'),
            const Text('• Reset timeout counter (2 per set)'),
            const Text('• Reset substitution counter (15 per set)'),
            const Text('• Clear current rally events'),
            const SizedBox(height: 8),
            const Text(
              'Match totals will be preserved.',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: AppColors.textTertiary,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ref.read(rallyCaptureSessionProvider(matchId).notifier).startNewSet();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Set $newSetNumber started!'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.emerald,
            ),
            child: Text('Start Set $newSetNumber'),
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

class _CustomAppBar extends ConsumerWidget {
  const _CustomAppBar({
    required this.matchId,
    required this.onEdit,
    required this.onExport,
    required this.onPlayerStats,
    required this.onEndMatch,
    required this.onNewSet,
  });

  final String matchId;
  final VoidCallback onEdit;
  final VoidCallback onExport;
  final VoidCallback onPlayerStats;
  final VoidCallback onEndMatch;
  final VoidCallback onNewSet;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(rallyCaptureSessionProvider(matchId));
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
            PopupMenuButton<String>(
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.more_vert_rounded, size: 20, color: AppColors.textTertiary),
              ),
              color: AppColors.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              tooltip: 'More options',
              onSelected: (value) {
                if (value == 'export') {
                  onExport();
                } else if (value == 'new_set') {
                  onNewSet();
                } else if (value == 'end_match') {
                  onEndMatch();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'export',
                  child: const Row(
                    children: [
                      Icon(Icons.download_rounded, size: 18, color: AppColors.indigo),
                      SizedBox(width: 8),
                      Text('Export'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'new_set',
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline_rounded, size: 18, color: AppColors.emerald),
                      const SizedBox(width: 8),
                      Text('New Set (Set ${session.currentSetNumber + 1})'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'end_match',
                  child: Row(
                    children: [
                      Icon(Icons.flag_rounded, size: 18, color: AppColors.rose),
                      SizedBox(width: 8),
                      Text('End Match'),
                    ],
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

class _RallyCaptureBody extends ConsumerStatefulWidget {
  const _RallyCaptureBody({
    required this.state,
    required this.matchId,
  });

  final RallyCaptureState state;
  final String matchId;

  @override
  ConsumerState<_RallyCaptureBody> createState() => _RallyCaptureBodyState();
}

class _RallyCaptureBodyState extends ConsumerState<_RallyCaptureBody> {
  bool _scoreCardExpanded = true;
  bool _timeoutSubCardExpanded = true;

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(rallyCaptureSessionProvider(widget.matchId));
    final sessionController =
        ref.read(rallyCaptureSessionProvider(widget.matchId).notifier);
    final totals = ref.watch(runningTotalsProvider(widget.matchId));
    final playerStats = ref.watch(playerStatsProvider(widget.matchId));
    final selectedTeam = ref.watch(selectedTeamProvider);

    Future<void> onQuickPlayerAction(MatchPlayer player, RallyActionTypes type) async {
      HapticFeedback.lightImpact();
      sessionController.logAction(type, player: player);
      
      // Auto-complete rally for point-scoring actions
      String actionLabel = type.label;
      if (type == RallyActionTypes.firstBallKill) {
        await sessionController.completeRallyWithWin(player: player, actionType: type);
        _showSnackBar(context, 'FBK by #${player.jerseyNumber}! Point won.');
      } else if (type == RallyActionTypes.attackKill || type == RallyActionTypes.serveAce) {
        await sessionController.completeRallyWithWin(player: player, actionType: type);
        _showSnackBar(context, '$actionLabel by #${player.jerseyNumber}! Point won.');
      } else if (type == RallyActionTypes.attackError || type == RallyActionTypes.serveError) {
        await sessionController.completeRallyWithLoss(player: player, actionType: type);
        _showSnackBar(context, '$actionLabel by #${player.jerseyNumber}. Point lost.');
      } else if (type.isPointScoring) {
        _showSnackBar(context, '$actionLabel by #${player.jerseyNumber}');
      } else {
        _showSnackBar(context, '$actionLabel logged for #${player.jerseyNumber}');
      }
    }

    Future<void> onPoint() async {
      HapticFeedback.mediumImpact();
      // Only complete if there are events, otherwise prompt to add an action
      if (session.currentEvents.isEmpty) {
        _showSnackBar(context, 'Add an action before completing the rally.');
        return;
      }
      final completed = await sessionController.completeRallyWithWin();
      if (completed) {
        _showSnackBar(context, 'Point won!');
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
      
      final currentLineup = ref.read(currentLineupProvider(widget.matchId));
      final lineupNotifier = ref.read(currentLineupProvider(widget.matchId).notifier);
      
      if (currentLineup.activePlayers.isEmpty) {
        _showSnackBar(
            context, 'Assign active players before recording a substitution.');
        return;
      }
      if (currentLineup.benchPlayers.isEmpty) {
        _showSnackBar(context, 'No bench players available for substitution.');
        return;
      }
      final selection = await _showSubstitutionDialog(
        context,
        activePlayers: currentLineup.activePlayers,
        benchPlayers: currentLineup.benchPlayers,
        substitutionsRemaining: totals.substitutionsRemaining,
      );
      if (selection == null) return;
      
      // Update the lineup with animation
      lineupNotifier.substitute(selection.outgoing, selection.incoming);
      
      // Log the substitution action
      sessionController.logAction(
        RallyActionTypes.substitution,
        note:
            'Out: #${selection.outgoing.jerseyNumber} ${selection.outgoing.name} • In: #${selection.incoming.jerseyNumber} ${selection.incoming.name}',
      );
      
      _showSnackBar(
        context,
        '#${selection.outgoing.jerseyNumber} ${selection.outgoing.name} → #${selection.incoming.jerseyNumber} ${selection.incoming.name}',
      );
    }

    final matchInfo = [
      if (widget.state.draft.opponent.isNotEmpty) widget.state.draft.opponent,
      if (widget.state.draft.matchDate != null)
        MaterialLocalizations.of(context)
            .formatMediumDate(widget.state.draft.matchDate!),
    ].join(' • ');

    // Get current lineup (updated by substitutions)
    final currentLineup = ref.watch(currentLineupProvider(widget.matchId));
    
    // Show all active players (6 on court) - use current lineup instead of static state
    final activePlayerStats = playerStats
        .where((stats) => currentLineup.activePlayers.any((p) => p.id == stats.player.id))
        .toList();

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
          // Match Header (Score Card)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassAccentContainer(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _scoreCardExpanded = !_scoreCardExpanded),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.school_rounded,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              matchInfo.isEmpty ? 'Match' : matchInfo,
                              style: const TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Icon(
                            _scoreCardExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_scoreCardExpanded) ...[
                    const Divider(height: 1, color: AppColors.borderMedium),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  selectedTeam?.name ?? 'Our Team',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${totals.wins}',
                                  style: const TextStyle(
                                    color: AppColors.indigoLight,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
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
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${session.currentSetNumber}',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 14,
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
                                  widget.state.draft.opponent.isNotEmpty
                                      ? widget.state.draft.opponent
                                      : 'Opponent',
                                  style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${totals.losses}',
                                  style: const TextStyle(
                                    color: AppColors.roseLight,
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Timeouts and Substitutions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: GlassLightContainer(
              padding: EdgeInsets.zero,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => setState(() => _timeoutSubCardExpanded = !_timeoutSubCardExpanded),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.settings_rounded,
                            size: 14,
                            color: AppColors.textTertiary,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Timeouts & Substitutions',
                              style: TextStyle(
                                color: AppColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Icon(
                            _timeoutSubCardExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            size: 18,
                            color: AppColors.textTertiary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_timeoutSubCardExpanded) ...[
                    const Divider(height: 1, color: AppColors.borderMedium),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Expanded(
                            child: _TimeoutSubButton(
                              icon: Icons.timer_off_rounded,
                              label: 'Timeout',
                              count: totals.timeouts,
                              maxCount: 2,
                              color: AppColors.amber,
                              onPressed: onTimeout,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _TimeoutSubButton(
                              icon: Icons.swap_horiz_rounded,
                              label: 'Substitution',
                              count: totals.substitutions,
                              maxCount: 15,
                              color: AppColors.emerald,
                              onPressed: onSubstitution,
                              disabled: !totals.canSubstitute,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    label: 'Point Won',
                    color: AppColors.indigo,
                    onPressed: onPoint,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionButton(
                    icon: Icons.remove_circle_outline_rounded,
                    label: 'Point Lost',
                    color: AppColors.rose,
                    onPressed: () async {
                      HapticFeedback.mediumImpact();
                      // Only complete if there are events, otherwise add a default error
                      final completed = await sessionController.completeRallyWithLoss();
                      if (completed) {
                        _showSnackBar(context, 'Point lost.');
                      }
                    },
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
                          widget.matchId,
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
                if (activePlayerStats.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'No active players',
                      style: TextStyle(color: AppColors.textMuted),
                    ),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: activePlayerStats.asMap().entries.map((entry) {
                      final index = entry.key;
                      final stats = entry.value;
                      return Padding(
                        padding: EdgeInsets.only(bottom: index < activePlayerStats.length - 1 ? 8 : 0),
                        child: _PlayerStatCard(
                          key: ValueKey('player-${stats.player.id}'),
                          stats: stats,
                          onAction: onQuickPlayerAction,
                          currentEvents: session.currentEvents,
                        ),
                      );
                    }).toList(),
                  ),
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
    super.key,
    required this.stats,
    required this.onAction,
    required this.currentEvents,
  });

  final PlayerStats stats;
  final Future<void> Function(MatchPlayer, RallyActionTypes) onAction;
  final List<RallyEvent> currentEvents;

  List<RallyEvent> get _playerCurrentEvents => currentEvents
      .where((event) => event.player?.id == stats.player.id)
      .toList();

  @override
  Widget build(BuildContext context) {
    final hasCurrentActions = _playerCurrentEvents.isNotEmpty;

    return GlassLightContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          // Header row
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
                    if (hasCurrentActions)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.indigo.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_playerCurrentEvents.length}',
                          style: const TextStyle(
                            color: AppColors.indigo,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (hasCurrentActions) const SizedBox(width: 8),
                  ],
                ),
              ],
            ),

          // Action buttons - Row 1: Attack actions + Block + Dig
          const SizedBox(height: 12),
          Row(
            children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.flash_on_rounded,
                    label: 'Kill',
                    color: AppColors.indigo,
                    count: stats.attackKills,
                    onPressed: () => onAction(stats.player, RallyActionTypes.attackKill),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.cancel_rounded,
                    label: 'Atk Err',
                    color: AppColors.rose,
                    count: stats.attackErrors,
                    onPressed: () => onAction(stats.player, RallyActionTypes.attackError),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.touch_app_rounded,
                    label: 'Attempt',
                    color: AppColors.textMuted,
                    count: stats.attackAttempts,
                    onPressed: () => onAction(stats.player, RallyActionTypes.attackAttempt),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.shield_rounded,
                    label: 'Block',
                    color: AppColors.amber,
                    count: stats.blocks,
                    onPressed: () => onAction(stats.player, RallyActionTypes.block),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.handshake_rounded,
                    label: 'Dig',
                    color: AppColors.teal,
                    count: stats.digs,
                    onPressed: () => onAction(stats.player, RallyActionTypes.dig),
                  ),
                ),
              ],
            ),

          // Action buttons - Row 2: Assist + Serve Ace + Serve Error + FBK (wider)
          const SizedBox(height: 8),
          Row(
            children: [
                Expanded(
                  child: _ActionButton(
                    icon: Icons.assistant_rounded,
                    label: 'Assist',
                    color: AppColors.emerald,
                    count: stats.assists,
                    onPressed: () => onAction(stats.player, RallyActionTypes.assist),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.gps_fixed_rounded,
                    label: 'Ace',
                    color: AppColors.emerald,
                    count: stats.serveAces,
                    onPressed: () => onAction(stats.player, RallyActionTypes.serveAce),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: _ActionButton(
                    icon: Icons.error_outline_rounded,
                    label: 'Srv Err',
                    color: AppColors.rose,
                    count: stats.serveErrors,
                    onPressed: () => onAction(stats.player, RallyActionTypes.serveError),
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: 2,
                  child: _ActionButton(
                    icon: Icons.bolt_rounded,
                    label: 'FBK',
                    color: AppColors.purple,
                    count: stats.fbk,
                    onPressed: () => onAction(stats.player, RallyActionTypes.firstBallKill),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _TimeoutSubButton extends StatelessWidget {
  const _TimeoutSubButton({
    required this.icon,
    required this.label,
    required this.count,
    required this.maxCount,
    required this.color,
    required this.onPressed,
    this.disabled = false,
  });

  final IconData icon;
  final String label;
  final int count;
  final int maxCount;
  final Color color;
  final VoidCallback onPressed;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final remaining = maxCount - count;
    final isMaxed = remaining <= 0;

    return GlassContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      backgroundColor: Colors.transparent,
      borderColor: Colors.transparent,
      blurAmount: 0,
      onTap: disabled || isMaxed ? null : onPressed,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: disabled || isMaxed ? AppColors.textDisabled : color,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '$count / $maxCount',
                style: TextStyle(
                  color: disabled || isMaxed ? AppColors.textDisabled : color,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: disabled || isMaxed ? AppColors.textDisabled : AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (remaining > 0 && !disabled)
            Text(
              '$remaining remaining',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.count,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final Color color;
  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.glassLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderMedium,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
          BoxShadow(
            color: AppColors.background.withOpacity(0.5),
            blurRadius: 4,
            spreadRadius: -2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '$count',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textTertiary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
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
