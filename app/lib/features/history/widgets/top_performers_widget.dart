import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/player_performance.dart';

class TopPerformersWidget extends StatelessWidget {
  const TopPerformersWidget({
    super.key,
    required this.players,
    required this.category,
  });

  final List<PlayerPerformance> players;
  final String category;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return const SizedBox.shrink();
    }

    return GlassLightContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Top Performers: $category',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ...players.take(5).map((player) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _PlayerRow(player: player, category: category),
              )),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.player,
    required this.category,
  });

  final PlayerPerformance player;
  final String category;

  int get _value {
    switch (category.toLowerCase()) {
      case 'kills':
        return player.kills;
      case 'attack efficiency':
        return (player.attackEfficiency * 100).round();
      case 'blocks':
        return player.blocks;
      case 'aces':
        return player.aces;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.indigoDark.withOpacity(0.2),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Center(
            child: Text(
              player.jerseyNumber.toString(),
              style: const TextStyle(
                color: AppColors.indigo,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            player.playerName,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
            ),
          ),
        ),
        Text(
          category.toLowerCase() == 'attack efficiency'
              ? '${_value}%'
              : _value.toString(),
          style: const TextStyle(
            color: AppColors.indigo,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

