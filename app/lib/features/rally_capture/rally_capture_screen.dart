import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'models/rally_models.dart';
import '../match_setup/match_setup_flow.dart';
import '../match_setup/models/match_player.dart';

const _playerActionTypes = <RallyActionTypes>[
  RallyActionTypes.serveAce,
  RallyActionTypes.serveError,
  RallyActionTypes.firstBallKill,
  RallyActionTypes.attackKill,
  RallyActionTypes.attackError,
  RallyActionTypes.block,
  RallyActionTypes.dig,
  RallyActionTypes.assist,
];

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
      appBar: AppBar(
        title: const Text('Rally Capture'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Match Setup',
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => MatchSetupFlow(matchId: matchId),
                ),
              );
              if (!context.mounted) {
                return;
              }
              ref.invalidate(rallyCaptureStateProvider(matchId));
            },
          ),
        ],
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          error: error,
          onRetry: () => ref.refresh(rallyCaptureStateProvider(matchId)),
        ),
        data: (state) => _RallyCaptureBody(state: state, matchId: matchId),
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

    Future<void> onPlayerActionSelected(RallyActionTypes type) async {
      final player = await _showPlayerPicker(
        context,
        players: state.activePlayers,
        title: type.label,
      );
      if (player == null) {
        return;
      }
      sessionController.logAction(type, player: player);
    }

    Future<void> onTimeout() async {
      final selection = await _showTimeoutDialog(context);
      if (selection == null) {
        return;
      }
      sessionController.logAction(
        RallyActionTypes.timeout,
        note: selection,
      );
    }

    Future<void> onSubstitution() async {
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
      );
      if (selection == null) {
        return;
      }
      sessionController.logAction(
        RallyActionTypes.substitution,
        note:
            'Out: #${selection.outgoing.jerseyNumber} ${selection.outgoing.name} • In: #${selection.incoming.jerseyNumber} ${selection.incoming.name}',
      );
    }

    Future<void> onCompleteRally() async {
      final rallyNumber = session.currentRallyNumber;
      final completed = await sessionController.completeRally();
      if (!completed) {
        _showSnackBar(
            context, 'Add at least one action before completing the rally.');
        return;
      }
      _showSnackBar(context, 'Rally $rallyNumber recorded.');
    }

    void onUndo() {
      final success = sessionController.undo();
      if (!success) {
        _showSnackBar(context, 'Nothing to undo.');
      }
    }

    void onRedo() {
      final success = sessionController.redo();
      if (!success) {
        _showSnackBar(context, 'Nothing to redo.');
      }
    }

    final matchInfo = [
      if (state.draft.opponent.isNotEmpty) 'vs ${state.draft.opponent}',
      if (state.draft.matchDate != null)
        MaterialLocalizations.of(context)
            .formatMediumDate(state.draft.matchDate!),
      if (state.draft.location.isNotEmpty) state.draft.location,
    ].join(' • ');

    final rotationEntries = List.generate(6, (index) {
      final position = index + 1;
      final player = state.rotation[position];
      return _RotationEntry(position: position, player: player);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final content = isWide
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionCard(
                          title: 'Rotation Tracker',
                          child: _RotationGrid(entries: rotationEntries),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Active Roster',
                          child: _RosterList(players: state.activePlayers),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Bench',
                          child: state.benchPlayers.isEmpty
                              ? const Text('No bench players assigned.')
                              : _RosterList(players: state.benchPlayers),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionCard(
                          title: 'Rally Timeline',
                          child: _RallyTimeline(session: session),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Actions',
                          child: _ActionPanel(
                            actionTypes: _playerActionTypes,
                            onAction: onPlayerActionSelected,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Rally Controls',
                          child: _RallyControls(
                            canUndo: session.canUndo,
                            canRedo: session.canRedo,
                            canCompleteRally: session.currentEvents.isNotEmpty,
                            onUndo: onUndo,
                            onRedo: onRedo,
                            onTimeout: onTimeout,
                            onSubstitution: onSubstitution,
                            onCompleteRally: onCompleteRally,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SectionCard(
                    title: 'Rotation Tracker',
                    child: _RotationGrid(entries: rotationEntries),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Active Roster',
                    child: _RosterList(players: state.activePlayers),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Bench',
                    child: state.benchPlayers.isEmpty
                        ? const Text('No bench players assigned.')
                        : _RosterList(players: state.benchPlayers),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Rally Timeline',
                    child: _RallyTimeline(session: session),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Actions',
                    child: _ActionPanel(
                      actionTypes: _playerActionTypes,
                      onAction: onPlayerActionSelected,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Rally Controls',
                    child: _RallyControls(
                      canUndo: session.canUndo,
                      canRedo: session.canRedo,
                      canCompleteRally: session.currentEvents.isNotEmpty,
                      onUndo: onUndo,
                      onRedo: onRedo,
                      onTimeout: onTimeout,
                      onSubstitution: onSubstitution,
                      onCompleteRally: onCompleteRally,
                    ),
                  ),
                ],
              );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                matchInfo.isEmpty ? 'Rally Capture' : matchInfo,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              content,
            ],
          ),
        );
      },
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _RotationGrid extends StatelessWidget {
  const _RotationGrid({required this.entries});

  final List<_RotationEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: entries
          .map(
            (entry) => SizedBox(
              width: 120,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pos ${entry.position}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.orange.withOpacity(0.1),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Text(
                      entry.player != null
                          ? '#${entry.player!.jerseyNumber} ${entry.player!.name}'
                          : 'Unassigned',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RotationEntry {
  _RotationEntry({required this.position, required this.player});

  final int position;
  final MatchPlayer? player;
}

class _RosterList extends StatelessWidget {
  const _RosterList({required this.players});

  final List<MatchPlayer> players;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const Text('No players assigned.');
    }
    return Column(
      children: players
          .map(
            (player) => ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              title: Text('#${player.jerseyNumber} ${player.name}'),
              subtitle: Text(player.position),
            ),
          )
          .toList(),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.actionTypes,
    required this.onAction,
  });

  final List<RallyActionTypes> actionTypes;
  final Future<void> Function(RallyActionTypes type) onAction;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actionTypes
          .map(
            (type) => FilledButton.tonal(
              onPressed: () async => onAction(type),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Text(type.label),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RallyTimeline extends StatelessWidget {
  const _RallyTimeline({required this.session});

  final RallyCaptureSession session;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    final localizations = MaterialLocalizations.of(context);

    if (session.completedRallies.isEmpty && session.currentEvents.isEmpty) {
      return const Text(
          'No rallies recorded yet. Use the action buttons to start logging.');
    }

    for (final record in session.completedRallies) {
      final completedLabel = localizations.formatTimeOfDay(
        TimeOfDay.fromDateTime(record.completedAt),
        alwaysUse24HourFormat: false,
      );
      items.add(
        _RallyTimelineTile(
          rallyNumber: record.rallyNumber,
          events: record.events,
          subtitle: 'Completed $completedLabel',
          isInProgress: false,
        ),
      );
    }

    if (session.currentEvents.isNotEmpty) {
      items.add(
        _RallyTimelineTile(
          rallyNumber: session.currentRallyNumber,
          events: session.currentEvents,
          subtitle: 'In progress',
          isInProgress: true,
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 16),
      itemBuilder: (context, index) => items[index],
    );
  }
}

class _RallyTimelineTile extends StatelessWidget {
  const _RallyTimelineTile({
    required this.rallyNumber,
    required this.events,
    required this.subtitle,
    required this.isInProgress,
  });

  final int rallyNumber;
  final List<RallyEvent> events;
  final String subtitle;
  final bool isInProgress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(
        isInProgress ? Icons.play_arrow : Icons.sports_volleyball,
        color: isInProgress ? theme.colorScheme.primary : null,
      ),
      title: Text(
        'Rally $rallyNumber${isInProgress ? ' (In Progress)' : ''}',
        style: theme.textTheme.titleSmall,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(subtitle),
          const SizedBox(height: 8),
          if (events.isEmpty)
            const Text(
              'No actions yet.',
              style: TextStyle(fontStyle: FontStyle.italic),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: events
                  .map(
                    (event) => Chip(
                      label: Text(event.summary),
                    ),
                  )
                  .toList(),
            ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

class _RallyControls extends StatelessWidget {
  const _RallyControls({
    required this.canUndo,
    required this.canRedo,
    required this.canCompleteRally,
    required this.onUndo,
    required this.onRedo,
    required this.onTimeout,
    required this.onSubstitution,
    required this.onCompleteRally,
  });

  final bool canUndo;
  final bool canRedo;
  final bool canCompleteRally;
  final VoidCallback onUndo;
  final VoidCallback onRedo;
  final Future<void> Function() onTimeout;
  final Future<void> Function() onSubstitution;
  final Future<void> Function() onCompleteRally;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton(
          onPressed: canUndo ? onUndo : null,
          child: const Text('Undo'),
        ),
        FilledButton(
          onPressed: canRedo ? onRedo : null,
          child: const Text('Redo'),
        ),
        FilledButton(
          onPressed: () async => onTimeout(),
          child: const Text('Timeout'),
        ),
        FilledButton(
          onPressed: () async => onSubstitution(),
          child: const Text('Substitution'),
        ),
        FilledButton(
          onPressed: canCompleteRally 
              ? () async => await onCompleteRally() 
              : null,
          child: const Text('Complete Rally'),
        ),
      ],
    );
  }
}

void _showSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
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
    builder: (context) => SafeArea(
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
}) {
  return showDialog<_SubstitutionSelection>(
    context: context,
    builder: (context) {
      MatchPlayer? outgoing;
      MatchPlayer? incoming;
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Record Substitution'),
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
