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
        data: (state) => _RallyCaptureBody(matchId: matchId, roster: state.roster),
      ),
    );
  }
}

class _RallyCaptureBody extends StatelessWidget {
  const _RallyCaptureBody({
    required this.matchId,
    required this.roster,
  });

  final String matchId;
  final List<MatchPlayer> roster;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Match: $matchId',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              if (isWide)
                Expanded(
                  child: Row(
                    children: [
                      Expanded(child: _RosterPanel(roster: roster)),
                      const SizedBox(width: 16),
                      Expanded(child: _ActionPanel()),
                    ],
                  ),
                )
              else
                Expanded(
                  child: ListView(
                    children: [
                      _RosterPanel(roster: roster),
                      const SizedBox(height: 16),
                      _ActionPanel(),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RosterPanel extends StatelessWidget {
  const _RosterPanel({required this.roster});

  final List<MatchPlayer> roster;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Roster',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (roster.isEmpty)
              const Text('No players selected for this match.')
            else
              ...roster.map(
                (player) => ListTile(
                  dense: true,
                  title: Text('#${player.jerseyNumber} ${player.name}'),
                  subtitle: Text(player.position),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Rally Controls (WIP)',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'This area will contain rally timeline, quick stat buttons, and rotation tracking.',
            ),
          ],
        ),
      ),
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

