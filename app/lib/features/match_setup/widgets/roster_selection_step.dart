import 'package:flutter/material.dart';
import '../models/match_player.dart';

class RosterSelectionStep extends StatelessWidget {
  const RosterSelectionStep({
    super.key,
    required this.roster,
    required this.selectedPlayerIds,
    required this.onTogglePlayer,
  });

  final List<MatchPlayer> roster;
  final Set<String> selectedPlayerIds;
  final ValueChanged<String> onTogglePlayer;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tap to activate players for this match.'),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: roster
              .map(
                (player) => FilterChip(
                  label: Text('#${player.jerseyNumber} ${player.name}'),
                  selected: selectedPlayerIds.contains(player.id),
                  onSelected: (_) => onTogglePlayer(player.id),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

