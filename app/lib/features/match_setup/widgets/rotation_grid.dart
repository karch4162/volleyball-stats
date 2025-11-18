import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/match_player.dart';

class RotationGrid extends StatelessWidget {
  const RotationGrid({
    super.key,
    required this.availablePlayers,
    required this.rotationAssignments,
    required this.onSelectPlayer,
  });

  final List<MatchPlayer> availablePlayers;
  final Map<int, String?> rotationAssignments;
  final void Function(int rotation, String? playerId) onSelectPlayer;

  MatchPlayer? _getPlayerForRotation(int rotation) {
    final playerId = rotationAssignments[rotation];
    if (playerId == null) return null;
    return availablePlayers.firstWhere(
      (p) => p.id == playerId,
      orElse: () => availablePlayers.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Starting Rotation',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Tap a position to assign player',
          style: TextStyle(
            color: AppColors.textMuted,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 16),
        // Grid layout: 3x2
        Row(
          children: [
            Expanded(
              child: _RotationPosition(
                position: 1,
                player: _getPlayerForRotation(1),
                availablePlayers: availablePlayers,
                onSelect: (playerId) => onSelectPlayer(1, playerId),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RotationPosition(
                position: 2,
                player: _getPlayerForRotation(2),
                availablePlayers: availablePlayers,
                onSelect: (playerId) => onSelectPlayer(2, playerId),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RotationPosition(
                position: 3,
                player: _getPlayerForRotation(3),
                availablePlayers: availablePlayers,
                onSelect: (playerId) => onSelectPlayer(3, playerId),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _RotationPosition(
                position: 4,
                player: _getPlayerForRotation(4),
                availablePlayers: availablePlayers,
                onSelect: (playerId) => onSelectPlayer(4, playerId),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RotationPosition(
                position: 5,
                player: _getPlayerForRotation(5),
                availablePlayers: availablePlayers,
                onSelect: (playerId) => onSelectPlayer(5, playerId),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _RotationPosition(
                position: 6,
                player: _getPlayerForRotation(6),
                availablePlayers: availablePlayers,
                onSelect: (playerId) => onSelectPlayer(6, playerId),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _RotationPosition extends StatelessWidget {
  const _RotationPosition({
    required this.position,
    required this.player,
    required this.availablePlayers,
    required this.onSelect,
  });

  final int position;
  final MatchPlayer? player;
  final List<MatchPlayer> availablePlayers;
  final void Function(String? playerId) onSelect;

  Future<void> _showPlayerPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<MatchPlayer>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Text(
                      'Rotation $position',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      color: AppColors.textMuted,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: availablePlayers.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ListTile(
                        leading: const Icon(Icons.clear_rounded),
                        title: const Text('Clear'),
                        onTap: () => Navigator.of(context).pop(null),
                      );
                    }
                    final player = availablePlayers[index - 1];
                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.indigoDark.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            '${player.jerseyNumber}',
                            style: const TextStyle(
                              color: AppColors.indigoLight,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        player.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(
                        player.position,
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                      onTap: () => Navigator.of(context).pop(player),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      onSelect(selected.id);
    } else if (selected == null && context.mounted) {
      // User selected "Clear"
      onSelect(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEmpty = player == null;

    return GlassLightContainer(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showPlayerPicker(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$position',
            style: TextStyle(
              color: isEmpty ? AppColors.textMuted : AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (isEmpty)
            Icon(
              Icons.add_rounded,
              color: AppColors.textMuted,
              size: 24,
            )
          else
            Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.indigoDark.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '#${player!.jerseyNumber}',
                      style: const TextStyle(
                        color: AppColors.indigoLight,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  player!.name.split(' ').first, // First name only for compact display
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

