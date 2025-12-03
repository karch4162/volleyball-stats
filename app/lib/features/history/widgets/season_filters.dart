import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';

class SeasonFilters extends StatefulWidget {
  const SeasonFilters({
    super.key,
    this.startDate,
    this.endDate,
    this.selectedSeason,
    this.onStartDateChanged,
    this.onEndDateChanged,
    this.onSeasonChanged,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? selectedSeason;
  final ValueChanged<DateTime?>? onStartDateChanged;
  final ValueChanged<DateTime?>? onEndDateChanged;
  final ValueChanged<String?>? onSeasonChanged;

  @override
  State<SeasonFilters> createState() => _SeasonFiltersState();
}

class _SeasonFiltersState extends State<SeasonFilters> {
  @override
  Widget build(BuildContext context) {
    return GlassLightContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Filters',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            title: const Text('Start Date'),
            subtitle: Text(
              widget.startDate != null
                  ? DateFormat('MMM d, y').format(widget.startDate!)
                  : 'No date selected',
            ),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: widget.startDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null && mounted) {
                widget.onStartDateChanged?.call(date);
              }
            },
          ),
          ListTile(
            title: const Text('End Date'),
            subtitle: Text(
              widget.endDate != null
                  ? DateFormat('MMM d, y').format(widget.endDate!)
                  : 'No date selected',
            ),
            trailing: const Icon(Icons.calendar_today_rounded),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: widget.endDate ?? DateTime.now(),
                firstDate: widget.startDate ?? DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (date != null && mounted) {
                widget.onEndDateChanged?.call(date);
              }
            },
          ),
          ListTile(
            title: const Text('Season'),
            subtitle: Text(widget.selectedSeason ?? 'All seasons'),
            trailing: const Icon(Icons.arrow_drop_down_rounded),
            onTap: () {
              // Would show season picker
              // For now, just allow clearing
              if (widget.selectedSeason != null) {
                widget.onSeasonChanged?.call(null);
              }
            },
          ),
        ],
      ),
    );
  }
}

