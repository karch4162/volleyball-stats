import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';

/// Simple match trends chart widget
/// This is a placeholder - full implementation would show a visual chart
class MatchTrendsChart extends StatelessWidget {
  const MatchTrendsChart({
    super.key,
    required this.matches,
  });

  final List<Map<String, dynamic>> matches; // List of {date, result, fbk}

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return const SizedBox.shrink();
    }

    final wins = matches.where((m) => m['result'] == 'win').length;
    final losses = matches.length - wins;
    final avgFBK = matches.isEmpty
        ? 0.0
        : matches.map((m) => (m['fbk'] as num?)?.toInt() ?? 0).reduce((a, b) => a + b) /
            matches.length;

    return GlassLightContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Match Trends',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TrendItem(
                label: 'Wins',
                value: wins.toString(),
                color: AppColors.emerald,
              ),
              _TrendItem(
                label: 'Losses',
                value: losses.toString(),
                color: AppColors.rose,
              ),
              _TrendItem(
                label: 'Avg FBK',
                value: avgFBK.toStringAsFixed(1),
                color: AppColors.indigo,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TrendItem extends StatelessWidget {
  const _TrendItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

