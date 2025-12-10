import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/player_performance.dart';

/// Comprehensive player stats card with collapsible sections
/// Shows attacking, serving, and other contributions with detailed metrics
class PlayerPerformanceCardV2 extends StatefulWidget {
  const PlayerPerformanceCardV2({
    super.key,
    required this.performance,
    this.expandedByDefault = false,
    this.showRank = false,
    this.rank,
  });

  final PlayerPerformance performance;
  final bool expandedByDefault;
  final bool showRank;
  final int? rank;

  @override
  State<PlayerPerformanceCardV2> createState() => _PlayerPerformanceCardV2State();
}

class _PlayerPerformanceCardV2State extends State<PlayerPerformanceCardV2> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.expandedByDefault;
  }

  @override
  Widget build(BuildContext context) {
    final performance = widget.performance;
    final hasStats = performance.totalPoints > 0 ||
        performance.attempts > 0 ||
        performance.totalServes > 0 ||
        performance.digs > 0 ||
        performance.assists > 0;

    return GlassLightContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header - always visible
          InkWell(
            onTap: hasStats ? () => setState(() => _isExpanded = !_isExpanded) : null,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Jersey number badge
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
                  
                  // Player name and total points
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (widget.showRank && widget.rank != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: _getRankColor(widget.rank!).withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '#${widget.rank}',
                                  style: TextStyle(
                                    color: _getRankColor(widget.rank!),
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                            ],
                            Expanded(
                              child: Text(
                                performance.playerName,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          hasStats ? '${performance.totalPoints} total points' : 'Did not play',
                          style: TextStyle(
                            color: hasStats ? AppColors.textMuted : AppColors.textMuted.withOpacity(0.6),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Quick stats summary (when collapsed)
                  if (!_isExpanded && hasStats) ...[
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (performance.attempts > 0)
                          Text(
                            '${(performance.attackEfficiency * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(
                              color: AppColors.indigo,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        const SizedBox(height: 2),
                        Text(
                          'Efficiency',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ],
                  
                  // Expand/collapse icon
                  if (hasStats) ...[
                    const SizedBox(width: 8),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: AppColors.textMuted,
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Expanded content
          if (_isExpanded && hasStats) ...[
            const Divider(height: 1, color: AppColors.borderMedium),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Attacking section
                  if (performance.attempts > 0) ...[
                    _SectionHeader(
                      icon: Icons.sports_volleyball,
                      title: 'Attacking',
                      color: AppColors.indigo,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _StatRow('Kills', performance.kills.toString()),
                              _StatRow('Errors', performance.errors.toString()),
                              _StatRow('Attempts', performance.attempts.toString()),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _StatRow(
                                'Kill %',
                                '${(performance.killPercentage * 100).toStringAsFixed(1)}%',
                                isHighlight: false,
                              ),
                              _StatRow(
                                'Efficiency',
                                '${(performance.attackEfficiency * 100).toStringAsFixed(1)}%',
                                isHighlight: true,
                                highlightColor: AppColors.indigo,
                              ),
                              _StatRow('Total Attacks', performance.attempts.toString()),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Serving section
                  if (performance.totalServes > 0) ...[
                    _SectionHeader(
                      icon: Icons.sports_tennis,
                      title: 'Serving',
                      color: AppColors.emerald,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _StatRow('Aces', performance.aces.toString()),
                              _StatRow('Errors', performance.serveErrors.toString()),
                              _StatRow('Total Serves', performance.totalServes.toString()),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            children: [
                              _StatRow(
                                'Ace %',
                                '${(performance.acePercentage * 100).toStringAsFixed(1)}%',
                              ),
                              _StatRow(
                                'Pressure',
                                '${(performance.servicePressure * 100).toStringAsFixed(1)}%',
                                isHighlight: true,
                                highlightColor: AppColors.emerald,
                              ),
                              _StatRow(
                                'Net',
                                '${performance.aces - performance.serveErrors > 0 ? "+" : ""}${performance.aces - performance.serveErrors}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],
                  
                  // Other contributions section
                  if (performance.blocks > 0 ||
                      performance.digs > 0 ||
                      performance.assists > 0 ||
                      performance.fbk > 0) ...[
                    _SectionHeader(
                      icon: Icons.star_rounded,
                      title: 'Other Contributions',
                      color: AppColors.purple,
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      children: [
                        if (performance.blocks > 0)
                          _StatChip(
                            label: 'Blocks',
                            value: performance.blocks.toString(),
                            color: AppColors.rose,
                          ),
                        if (performance.digs > 0)
                          _StatChip(
                            label: 'Digs',
                            value: performance.digs.toString(),
                            color: AppColors.amber,
                          ),
                        if (performance.assists > 0)
                          _StatChip(
                            label: 'Assists',
                            value: performance.assists.toString(),
                            color: AppColors.teal,
                          ),
                        if (performance.fbk > 0)
                          _StatChip(
                            label: 'FBK',
                            value: performance.fbk.toString(),
                            color: AppColors.indigo,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    if (rank == 1) return AppColors.amber;
    if (rank == 2) return AppColors.textMuted;
    if (rank == 3) return AppColors.rose;
    return AppColors.indigo;
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(
    this.label,
    this.value, {
    this.isHighlight = false,
    this.highlightColor = AppColors.indigo,
  });

  final String label;
  final String value;
  final bool isHighlight;
  final Color highlightColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isHighlight ? AppColors.textPrimary : AppColors.textMuted,
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: isHighlight ? highlightColor : AppColors.textPrimary,
              fontSize: 13,
              fontWeight: isHighlight ? FontWeight.bold : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
