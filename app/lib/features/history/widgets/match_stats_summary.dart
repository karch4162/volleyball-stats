import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';

class MatchStatsSummary extends StatelessWidget {
  const MatchStatsSummary({
    super.key,
    required this.totalRallies,
    required this.totalFBK,
    required this.totalTransitionPoints,
    required this.substitutions,
    required this.timeouts,
  });

  final int totalRallies;
  final int totalFBK;
  final int totalTransitionPoints;
  final int substitutions;
  final int timeouts;

  @override
  Widget build(BuildContext context) {
    return GlassLightContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Statistics',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.timeline_rounded,
                  label: 'Total Rallies',
                  value: totalRallies.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.star_rounded,
                  label: 'FBK',
                  value: totalFBK.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.swap_horiz_rounded,
                  label: 'Transition Points',
                  value: totalTransitionPoints.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.people_rounded,
                  label: 'Substitutions',
                  value: substitutions.toString(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBox(
                  icon: Icons.pause_circle_outline_rounded,
                  label: 'Timeouts',
                  value: timeouts.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatBox(
                  icon: Icons.percent_rounded,
                  label: 'FBK %',
                  value: totalRallies > 0
                      ? '${((totalFBK / totalRallies) * 100).toStringAsFixed(1)}%'
                      : '0%',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.glass,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.borderMedium,
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 24, color: AppColors.indigo),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

