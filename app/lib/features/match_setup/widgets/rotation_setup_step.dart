import 'package:flutter/material.dart';

import '../models/match_player.dart';

class RotationSetupStep extends StatelessWidget {
  const RotationSetupStep({
    super.key,
    required this.availablePlayers,
    required this.rotationAssignments,
    required this.onSelectPlayer,
  });

  final List<MatchPlayer> availablePlayers;
  final Map<int, String?> rotationAssignments;
  final void Function(int rotation, String? playerId) onSelectPlayer;

  @override
  Widget build(BuildContext context) {
    if (availablePlayers.isEmpty) {
      return const Text('Select players before assigning a rotation.');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Choose who starts in each rotation position (1–6).'),
        const SizedBox(height: 12),
        ...rotationAssignments.entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: DropdownButtonFormField<String>(
              value: entry.value,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Rotation ${entry.key}',
                border: const OutlineInputBorder(),
              ),
              items: availablePlayers
                  .map(
                    (player) => DropdownMenuItem(
                      value: player.id,
                      child: Text('#${player.jerseyNumber} ${player.name}'),
                    ),
                  )
                  .toList(),
              onChanged: (value) => onSelectPlayer(entry.key, value),
            ),
          ),
        ),
      ],
    );
  }
}

