import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/player_performance.dart';

class PlayerPerformanceCard extends StatelessWidget {
  const PlayerPerformanceCard({
    super.key,
    required this.performance,
  });

  final PlayerPerformance performance;

  @override
  Widget build(BuildContext context) {
    return GlassLightContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
                    performance.jerseyNumber.toString(),
                    style: const TextStyle(
                      color: AppColors.indigo,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      performance.playerName,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${performance.totalPoints} total points',
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatColumn(
                  label: 'Attack',
                  kills: performance.kills,
                  errors: performance.errors,
                  attempts: performance.attempts,
                  efficiency: performance.attackEfficiency,
                  killPercentage: performance.killPercentage,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _StatColumn(
                  label: 'Other',
                  blocks: performance.blocks,
                  aces: performance.aces,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.label,
    this.kills,
    this.errors,
    this.attempts,
    this.efficiency,
    this.killPercentage,
    this.blocks,
    this.aces,
  });

  final String label;
  final int? kills;
  final int? errors;
  final int? attempts;
  final double? efficiency;
  final double? killPercentage;
  final int? blocks;
  final int? aces;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (kills != null) ...[
          _StatRow('Kills', kills.toString()),
          _StatRow('Errors', (errors ?? 0).toString()),
          _StatRow('Attempts', (attempts ?? 0).toString()),
          const SizedBox(height: 4),
          _StatRow(
            'Efficiency',
            efficiency != null ? '${(efficiency! * 100).toStringAsFixed(1)}%' : '0%',
            isHighlight: true,
          ),
          _StatRow(
            'Kill %',
            killPercentage != null
                ? '${(killPercentage! * 100).toStringAsFixed(1)}%'
                : '0%',
          ),
        ] else ...[
          if (blocks != null) _StatRow('Blocks', blocks.toString()),
          if (aces != null) _StatRow('Aces', aces.toString()),
        ],
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
    this.label,
    this.value, {
    this.isHighlight = false,
  });

  final String label;
  final String value;
  final bool isHighlight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? AppColors.indigo : AppColors.textPrimary,
              fontSize: 12,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

