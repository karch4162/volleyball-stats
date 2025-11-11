import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import '../match_setup/models/match_player.dart';

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
      ),
      body: asyncState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          error: error,
          onRetry: () => ref.refresh(rallyCaptureStateProvider(matchId)),
        ),
        data: (state) => _RallyCaptureBody(state: state),
      ),
    );
  }
}

class _RallyCaptureBody extends StatelessWidget {
  const _RallyCaptureBody({
    required this.state,
  });

  final RallyCaptureState state;

  @override
  Widget build(BuildContext context) {
    final matchInfo = [
      if (state.draft.opponent.isNotEmpty) 'vs ${state.draft.opponent}',
      if (state.draft.matchDate != null)
        MaterialLocalizations.of(context).formatMediumDate(state.draft.matchDate!),
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
                          child: _RallyTimeline(),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Actions',
                          child: _ActionPanel(),
                        ),
                        const SizedBox(height: 16),
                        _SectionCard(
                          title: 'Rally Controls',
                          child: _RallyControls(),
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
                    child: _RallyTimeline(),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Actions',
                    child: _ActionPanel(),
                  ),
                  const SizedBox(height: 16),
                  _SectionCard(
                    title: 'Rally Controls',
                    child: _RallyControls(),
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
  @override
  Widget build(BuildContext context) {
    final actions = [
      'Serve Ace',
      'Serve Error',
      'FBK',
      'Attack Kill',
      'Attack Error',
      'Block',
      'Dig',
      'Assist',
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: actions
          .map(
            (label) => FilledButton.tonal(
              onPressed: () {},
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Text(label),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RallyTimeline extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final placeholderItems = List.generate(
      5,
      (index) => 'Rally ${index + 1} • Result TBD',
    );
    return Column(
      children: placeholderItems
          .map(
            (item) => ListTile(
              leading: const Icon(Icons.sports_volleyball),
              title: Text(item),
              subtitle: const Text('Timeline entry placeholder'),
              trailing: const Icon(Icons.chevron_right),
            ),
          )
          .toList(),
    );
  }
}

class _RallyControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        FilledButton(
          onPressed: () {},
          child: const Text('Undo'),
        ),
        FilledButton(
          onPressed: () {},
          child: const Text('Redo'),
        ),
        FilledButton(
          onPressed: () {},
          child: const Text('Timeout'),
        ),
        FilledButton(
          onPressed: () {},
          child: const Text('Substitution'),
        ),
        FilledButton(
          onPressed: () {},
          child: const Text('Complete Rally'),
        ),
      ],
    );
  }
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

