import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';

/// Control bar for sorting and filtering player statistics
class PlayerStatsControls extends StatelessWidget {
  const PlayerStatsControls({
    super.key,
    required this.currentSortBy,
    required this.onSortChanged,
    this.ascending = false,
    this.onAscendingChanged,
    this.showViewToggle = false,
    this.isTableView = false,
    this.onViewModeChanged,
  });

  final String currentSortBy;
  final ValueChanged<String> onSortChanged;
  final bool ascending;
  final ValueChanged<bool>? onAscendingChanged;
  final bool showViewToggle;
  final bool isTableView;
  final ValueChanged<bool>? onViewModeChanged;

  @override
  Widget build(BuildContext context) {
    return GlassLightContainer(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          // Sort label
          const Text(
            'Sort by:',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 12),
          
          // Sort dropdown
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.glassLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderMedium),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: currentSortBy,
                  isDense: true,
                  isExpanded: true,
                  icon: const Icon(Icons.arrow_drop_down, color: AppColors.textPrimary, size: 20),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  dropdownColor: AppColors.surface,
                  items: const [
                    DropdownMenuItem(value: 'points', child: Text('Total Points')),
                    DropdownMenuItem(value: 'efficiency', child: Text('Attack Efficiency')),
                    DropdownMenuItem(value: 'kills', child: Text('Kills')),
                    DropdownMenuItem(value: 'blocks', child: Text('Blocks')),
                    DropdownMenuItem(value: 'aces', child: Text('Aces')),
                    DropdownMenuItem(value: 'servicePressure', child: Text('Service Pressure')),
                    DropdownMenuItem(value: 'digs', child: Text('Digs')),
                    DropdownMenuItem(value: 'assists', child: Text('Assists')),
                    DropdownMenuItem(value: 'fbk', child: Text('First Ball Kills')),
                    DropdownMenuItem(value: 'jersey', child: Text('Jersey Number')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      onSortChanged(value);
                    }
                  },
                ),
              ),
            ),
          ),
          
          // Sort order toggle
          if (onAscendingChanged != null) ...[
            const SizedBox(width: 8),
            IconButton(
              icon: Icon(
                ascending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 20,
              ),
              color: AppColors.indigo,
              onPressed: () => onAscendingChanged?.call(!ascending),
              tooltip: ascending ? 'Ascending' : 'Descending',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ],
          
          // View mode toggle
          if (showViewToggle && onViewModeChanged != null) ...[
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.glassLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.borderMedium),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ViewModeButton(
                    icon: Icons.view_list,
                    isSelected: !isTableView,
                    onTap: () => onViewModeChanged?.call(false),
                    tooltip: 'Card View',
                  ),
                  Container(
                    width: 1,
                    height: 24,
                    color: AppColors.borderMedium,
                  ),
                  _ViewModeButton(
                    icon: Icons.table_chart,
                    isSelected: isTableView,
                    onTap: () => onViewModeChanged?.call(true),
                    tooltip: 'Table View',
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  const _ViewModeButton({
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          child: Icon(
            icon,
            size: 20,
            color: isSelected ? AppColors.indigo : AppColors.textMuted,
          ),
        ),
      ),
    );
  }
}
