import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';

/// Widget to display serve rotation summary
/// This is a placeholder - full implementation would track rotation order and serve efficiency
class RotationSummaryWidget extends StatelessWidget {
  const RotationSummaryWidget({
    super.key,
    required this.rotationNumber,
    this.serveEfficiency,
  });

  final int rotationNumber;
  final double? serveEfficiency;

  @override
  Widget build(BuildContext context) {
    return GlassLightContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rotation $rotationNumber',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (serveEfficiency != null) ...[
            const SizedBox(height: 8),
            Text(
              'Serve Efficiency: ${(serveEfficiency! * 100).toStringAsFixed(1)}%',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

