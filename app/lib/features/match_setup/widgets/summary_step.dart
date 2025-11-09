import 'package:flutter/material.dart';

import '../models/match_draft.dart';
import '../models/match_player.dart';

class SummaryStep extends StatelessWidget {
  const SummaryStep({
    super.key,
    required this.draft,
    required this.selectedPlayers,
  });

  final MatchDraft draft;
  final List<MatchPlayer> selectedPlayers;

  @override
  Widget build(BuildContext context) {
    final playerById = {
      for (final player in selectedPlayers) player.id: player,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Opponent'),
          subtitle: Text(draft.opponent.isEmpty ? 'TBD' : draft.opponent),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Match date'),
          subtitle: Text(
            draft.matchDate != null
                ? MaterialLocalizations.of(context).formatFullDate(draft.matchDate!)
                : 'Not selected',
          ),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Location'),
          subtitle: Text(draft.location.isEmpty ? 'Not provided' : draft.location),
        ),
        ListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Season label'),
          subtitle: Text(draft.seasonLabel.isEmpty ? 'Not provided' : draft.seasonLabel),
        ),
        const SizedBox(height: 12),
        Text(
          'Active roster (${selectedPlayers.length})',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        ...selectedPlayers.map(
          (player) => ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text('#${player.jerseyNumber} ${player.name}'),
            subtitle: Text(player.position),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Starting rotation',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 4),
        if (draft.startingRotation.isEmpty)
          const Text('Rotation not configured yet.')
        else
          ...draft.startingRotation.entries.map(
            (entry) {
              final player = playerById[entry.value];
              final rotationLabel = 'Rotation ${entry.key}';
              if (player == null) {
                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(rotationLabel),
                  subtitle: const Text('Player removed from roster'),
                );
              }
              return ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(rotationLabel),
                subtitle: Text('#${player.jerseyNumber} ${player.name} (${player.position})'),
              );
            },
          ),
      ],
    );
  }
}

