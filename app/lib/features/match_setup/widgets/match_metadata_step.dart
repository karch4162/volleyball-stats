import 'package:flutter/material.dart';

class MatchMetadataStep extends StatelessWidget {
  const MatchMetadataStep({
    super.key,
    required this.opponentController,
    required this.locationController,
    required this.seasonLabelController,
    required this.matchDate,
    required this.onPickDate,
  });

  final TextEditingController opponentController;
  final TextEditingController locationController;
  final TextEditingController seasonLabelController;
  final DateTime? matchDate;
  final VoidCallback onPickDate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateLabel = matchDate != null
        ? MaterialLocalizations.of(context).formatFullDate(matchDate!)
        : 'Select match date';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: opponentController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Opponent',
            hintText: 'e.g. Ridgeview Hawks',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: locationController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Location',
            hintText: 'Home, Away, or venue name',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: seasonLabelController,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Season label',
            hintText: 'e.g. 2025 Varsity',
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: onPickDate,
          icon: const Icon(Icons.calendar_today),
          label: Text(dateLabel),
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.secondaryContainer,
            foregroundColor: theme.colorScheme.onSecondaryContainer,
          ),
        ),
      ],
    );
  }
}

