import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/player_performance.dart';

/// Compact table view for player statistics
/// Better for comparing multiple players at once, especially on tablets
class PlayerStatsTable extends StatelessWidget {
  const PlayerStatsTable({
    super.key,
    required this.players,
    this.onHeaderTap,
    this.sortColumn,
    this.sortAscending = false,
  });

  final List<PlayerPerformance> players;
  final ValueChanged<String>? onHeaderTap;
  final String? sortColumn;
  final bool sortAscending;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return GlassLightContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(12),
        child: const Center(
          child: Text(
            'No player statistics available',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ),
      );
    }

    return GlassLightContainer(
      padding: EdgeInsets.zero,
      borderRadius: BorderRadius.circular(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(
            AppColors.glassLight.withOpacity(0.5),
          ),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.indigo.withOpacity(0.1);
            }
            return Colors.transparent;
          }),
          dividerThickness: 0.5,
          horizontalMargin: 16,
          columnSpacing: 20,
          headingTextStyle: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          dataTextStyle: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 13,
          ),
          columns: [
            _buildDataColumn('#', 'jersey'),
            _buildDataColumn('Player', 'name'),
            _buildDataColumn('Pts', 'points'),
            _buildDataColumn('K', 'kills'),
            _buildDataColumn('E', 'errors'),
            _buildDataColumn('A', 'attempts'),
            _buildDataColumn('Eff%', 'efficiency'),
            _buildDataColumn('Ace', 'aces'),
            _buildDataColumn('SE', 'serveErrors'),
            _buildDataColumn('SP%', 'servicePressure'),
            _buildDataColumn('B', 'blocks'),
            _buildDataColumn('D', 'digs'),
            _buildDataColumn('Ast', 'assists'),
            _buildDataColumn('FBK', 'fbk'),
          ],
          rows: players.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final isAlternate = index % 2 == 1;
            
            return DataRow(
              color: WidgetStateProperty.all(
                isAlternate 
                    ? AppColors.glassLight.withOpacity(0.3) 
                    : Colors.transparent,
              ),
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.indigoDark.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      player.jerseyNumber.toString(),
                      style: const TextStyle(
                        color: AppColors.indigo,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  SizedBox(
                    width: 120,
                    child: Text(
                      player.playerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(_buildStatCell(player.totalPoints.toString(), AppColors.indigo)),
                DataCell(Text(player.kills.toString())),
                DataCell(Text(player.errors.toString())),
                DataCell(Text(player.attempts.toString())),
                DataCell(
                  _buildPercentageCell(
                    player.attackEfficiency * 100,
                    player.attempts > 0,
                    AppColors.indigo,
                  ),
                ),
                DataCell(Text(player.aces.toString())),
                DataCell(Text(player.serveErrors.toString())),
                DataCell(
                  _buildPercentageCell(
                    player.servicePressure * 100,
                    player.totalServes > 0,
                    AppColors.emerald,
                  ),
                ),
                DataCell(Text(player.blocks.toString())),
                DataCell(Text(player.digs.toString())),
                DataCell(Text(player.assists.toString())),
                DataCell(Text(player.fbk.toString())),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  DataColumn _buildDataColumn(String label, String columnKey) {
    final isSorted = sortColumn == columnKey;
    
    return DataColumn(
      label: onHeaderTap != null
          ? InkWell(
              onTap: () => onHeaderTap?.call(columnKey),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label),
                  if (isSorted) ...[
                    const SizedBox(width: 4),
                    Icon(
                      sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                      size: 14,
                      color: AppColors.indigo,
                    ),
                  ],
                ],
              ),
            )
          : Text(label),
      tooltip: _getTooltip(columnKey),
    );
  }

  Widget _buildStatCell(String value, Color color) {
    return Text(
      value,
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildPercentageCell(double percentage, bool hasAttempts, Color color) {
    if (!hasAttempts) {
      return const Text(
        '-',
        style: TextStyle(
          color: AppColors.textMuted,
        ),
      );
    }
    
    return Text(
      '${percentage.toStringAsFixed(1)}%',
      style: TextStyle(
        color: color,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  String _getTooltip(String columnKey) {
    switch (columnKey) {
      case 'jersey':
        return 'Jersey Number';
      case 'name':
        return 'Player Name';
      case 'points':
        return 'Total Points (Kills + Blocks + Aces)';
      case 'kills':
        return 'Attack Kills';
      case 'errors':
        return 'Attack Errors';
      case 'attempts':
        return 'Total Attack Attempts';
      case 'efficiency':
        return 'Attack Efficiency: (Kills - Errors) / Attempts';
      case 'aces':
        return 'Service Aces';
      case 'serveErrors':
        return 'Service Errors';
      case 'servicePressure':
        return 'Service Pressure: (Aces - Errors) / Total Serves';
      case 'blocks':
        return 'Blocks';
      case 'digs':
        return 'Digs';
      case 'assists':
        return 'Assists';
      case 'fbk':
        return 'First Ball Kills';
      default:
        return '';
    }
  }
}
