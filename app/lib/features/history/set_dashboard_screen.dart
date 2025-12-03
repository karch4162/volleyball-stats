import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../rally_capture/providers.dart';
import '../rally_capture/models/rally_models.dart';

class SetDashboardScreen extends ConsumerWidget {
  const SetDashboardScreen({
    super.key,
    required this.matchId,
    required this.setNumber,
  });

  final String matchId;
  final int setNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(rallyCaptureSessionProvider(matchId));
    final totals = ref.watch(runningTotalsProvider(matchId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Set $setNumber Dashboard'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Set overview
            GlassLightContainer(
              padding: const EdgeInsets.all(20),
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  Text(
                    'Set $setNumber',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatDisplay(
                        label: 'Rallies',
                        value: session.completedRallies.length.toString(),
                      ),
                      _StatDisplay(
                        label: 'FBK',
                        value: totals.fbk.toString(),
                      ),
                      _StatDisplay(
                        label: 'Wins',
                        value: totals.wins.toString(),
                      ),
                      _StatDisplay(
                        label: 'Losses',
                        value: totals.losses.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Running totals
            const Text(
              'Running Totals',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            GlassLightContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(12),
              child: Column(
                children: [
                  _RunningTotalRow(
                    icon: Icons.star_rounded,
                    label: 'First Ball Kills',
                    value: totals.fbk.toString(),
                    color: AppColors.indigo,
                  ),
                  const Divider(color: AppColors.borderMedium),
                  _RunningTotalRow(
                    icon: Icons.check_circle_rounded,
                    label: 'Wins',
                    value: totals.wins.toString(),
                    color: AppColors.emerald,
                  ),
                  const Divider(color: AppColors.borderMedium),
                  _RunningTotalRow(
                    icon: Icons.cancel_rounded,
                    label: 'Losses',
                    value: totals.losses.toString(),
                    color: AppColors.rose,
                  ),
                  const Divider(color: AppColors.borderMedium),
                  _RunningTotalRow(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Transition Points',
                    value: totals.transitionPoints.toString(),
                    color: AppColors.purple,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Rally breakdown
            const Text(
              'Rally Breakdown',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            ...session.completedRallies.map((rally) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _RallyCard(rally: rally),
                )),
          ],
        ),
      ),
    );
  }
}

class _StatDisplay extends StatelessWidget {
  const _StatDisplay({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 28,
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

class _RunningTotalRow extends StatelessWidget {
  const _RunningTotalRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _RallyCard extends StatelessWidget {
  const _RallyCard({required this.rally});

  final RallyRecord rally;

  @override
  Widget build(BuildContext context) {
    final isWin = rally.events.any((e) => e.type.isPointScoring);
    final hasFBK = rally.events.any((e) => e.type == RallyActionTypes.firstBallKill);

    return GlassLightContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isWin
                  ? AppColors.emerald.withOpacity(0.2)
                  : AppColors.rose.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                rally.rallyNumber.toString(),
                style: TextStyle(
                  color: isWin ? AppColors.emerald : AppColors.rose,
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
                  'Rally ${rally.rallyNumber}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 4,
                  children: [
                    if (hasFBK)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.indigo.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'FBK',
                          style: TextStyle(
                            color: AppColors.indigo,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ...rally.events.take(3).map((e) => Text(
                          e.type.label,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        )),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            isWin ? Icons.check_circle : Icons.cancel,
            color: isWin ? AppColors.emerald : AppColors.rose,
          ),
        ],
      ),
    );
  }
}

