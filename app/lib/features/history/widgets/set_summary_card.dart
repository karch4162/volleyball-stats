import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/set_summary.dart';

class SetSummaryCard extends StatelessWidget {
  const SetSummaryCard({
    super.key,
    required this.setSummary,
  });

  final SetSummary setSummary;

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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.indigoDark.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Set ${setSummary.setNumber}',
                  style: const TextStyle(
                    color: AppColors.indigo,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: setSummary.isWin
                      ? AppColors.emerald.withOpacity(0.2)
                      : AppColors.rose.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: setSummary.isWin ? AppColors.emerald : AppColors.rose,
                    width: 1,
                  ),
                ),
                child: Text(
                  setSummary.isWin ? 'WIN' : 'LOSS',
                  style: TextStyle(
                    color: setSummary.isWin ? AppColors.emerald : AppColors.rose,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ScoreDisplay(
                label: 'Our Score',
                score: setSummary.ourScore,
                isWin: setSummary.isWin,
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.borderMedium,
              ),
              _ScoreDisplay(
                label: 'Opponent',
                score: setSummary.opponentScore,
                isWin: !setSummary.isWin,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(
                icon: Icons.timeline_rounded,
                label: 'Rallies',
                value: setSummary.rallyCount.toString(),
              ),
              _StatItem(
                icon: Icons.star_rounded,
                label: 'FBK',
                value: setSummary.fbkCount.toString(),
              ),
              _StatItem(
                icon: Icons.swap_horiz_rounded,
                label: 'Transition',
                value: setSummary.transitionPoints.toString(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ScoreDisplay extends StatelessWidget {
  const _ScoreDisplay({
    required this.label,
    required this.score,
    required this.isWin,
  });

  final String label;
  final int score;
  final bool isWin;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          score.toString(),
          style: TextStyle(
            color: isWin ? AppColors.emerald : AppColors.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppColors.textMuted),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

