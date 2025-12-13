import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/glass_container.dart';
import '../models/match_draft.dart';
import '../models/match_player.dart';
import 'match_metadata_step.dart';
import 'rotation_grid.dart';
import 'roster_selection_step.dart';

class StreamlinedSetupBody extends StatelessWidget {
  const StreamlinedSetupBody({
    super.key,
    required this.draft,
    required this.roster,
    required this.selectedPlayerIds,
    required this.rotationAssignments,
    required this.opponentController,
    required this.locationController,
    required this.seasonLabelController,
    required this.matchDate,
    required this.onTogglePlayer,
    required this.onSelectRotation,
    required this.onPickDate,
    this.onUseTemplate,
    this.onCloneLast,
    this.onSaveDraft,
    this.onStartMatch,
    this.isSaving = false,
  });

  final MatchDraft draft;
  final List<MatchPlayer> roster;
  final Set<String> selectedPlayerIds;
  final Map<int, String?> rotationAssignments;
  final TextEditingController opponentController;
  final TextEditingController locationController;
  final TextEditingController seasonLabelController;
  final DateTime? matchDate;
  final ValueChanged<String> onTogglePlayer;
  final void Function(int rotation, String? playerId) onSelectRotation;
  final VoidCallback onPickDate;
  final VoidCallback? onUseTemplate;
  final VoidCallback? onCloneLast;
  final VoidCallback? onSaveDraft;
  final VoidCallback? onStartMatch;
  final bool isSaving;

  List<MatchPlayer> get selectedPlayers => roster
      .where((player) => selectedPlayerIds.contains(player.id))
      .toList(growable: false);

  bool get hasValidRoster => selectedPlayerIds.length >= 6;
  bool get hasValidRotation => rotationAssignments.values
      .where((id) => id != null)
      .length == 6;
  bool get canStartMatch => draft.opponent.isNotEmpty &&
      matchDate != null &&
      hasValidRoster &&
      hasValidRotation;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Match Info Section
          _SectionHeader(
            title: 'Match Info',
            isComplete: draft.opponent.isNotEmpty && matchDate != null,
          ),
          const SizedBox(height: 12),
          GlassLightContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            child: MatchMetadataStep(
              opponentController: opponentController,
              locationController: locationController,
              seasonLabelController: seasonLabelController,
              matchDate: matchDate,
              onPickDate: onPickDate,
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          if (onUseTemplate != null || onCloneLast != null) ...[
            const _SectionHeader(title: 'Quick Actions'),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onUseTemplate != null)
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.star_rounded,
                      label: 'Use Template',
                      onTap: onUseTemplate!,
                    ),
                  ),
                if (onUseTemplate != null && onCloneLast != null)
                  const SizedBox(width: 12),
                if (onCloneLast != null)
                  Expanded(
                    child: _QuickActionButton(
                      icon: Icons.history_rounded,
                      label: 'Clone Last',
                      onTap: onCloneLast!,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 24),
          ],

          // Roster Selection Section
          _SectionHeader(
            title: 'Roster Selection',
            subtitle: '${selectedPlayerIds.length}/${roster.length} selected',
            isComplete: hasValidRoster,
          ),
          const SizedBox(height: 12),
          GlassLightContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: BorderRadius.circular(16),
            child: RosterSelectionStep(
              roster: roster,
              selectedPlayerIds: selectedPlayerIds,
              onTogglePlayer: onTogglePlayer,
            ),
          ),
          if (!hasValidRoster && selectedPlayerIds.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Select at least 6 players',
                style: TextStyle(
                  color: AppColors.rose,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // Starting Rotation Section
          _SectionHeader(
            title: 'Starting Rotation',
            subtitle: '${rotationAssignments.values.where((id) => id != null).length}/6 assigned',
            isComplete: hasValidRotation,
          ),
          const SizedBox(height: 12),
          if (selectedPlayers.isEmpty)
            GlassLightContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(16),
              child: const Text(
                'Select players first to assign rotation',
                style: TextStyle(color: AppColors.textMuted),
              ),
            )
          else
            GlassLightContainer(
              padding: const EdgeInsets.all(16),
              borderRadius: BorderRadius.circular(16),
              child: RotationGrid(
                availablePlayers: selectedPlayers,
                rotationAssignments: rotationAssignments,
                onSelectPlayer: onSelectRotation,
              ),
            ),
          if (!hasValidRotation && selectedPlayers.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Text(
                'Assign all 6 rotation positions',
                style: TextStyle(
                  color: AppColors.rose,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 32),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isSaving ? null : onSaveDraft,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Draft'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: (canStartMatch && !isSaving) ? onStartMatch : null,
                  icon: isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.play_arrow_rounded),
                  label: Text(isSaving ? 'Saving...' : 'Start Match'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.subtitle,
    this.isComplete = false,
  });

  final String title;
  final String? subtitle;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 8),
          Text(
            subtitle!,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
        const Spacer(),
        if (isComplete)
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: AppColors.emerald.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.emerald,
              size: 14,
            ),
          ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlassLightContainer(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.indigo, size: 20),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

