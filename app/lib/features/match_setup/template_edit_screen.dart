import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../teams/team_providers.dart';
import 'models/roster_template.dart';
import 'providers.dart';
import 'constants.dart';

class TemplateEditScreen extends ConsumerStatefulWidget {
  const TemplateEditScreen({
    super.key,
    this.template,
    this.initialPlayerIds,
    this.initialRotation,
  });

  /// Existing template to edit (if null, creates new)
  final RosterTemplate? template;

  /// Initial player IDs (for creating from match setup)
  final Set<String>? initialPlayerIds;

  /// Initial rotation (for creating from match setup)
  final Map<int, String>? initialRotation;

  @override
  ConsumerState<TemplateEditScreen> createState() => _TemplateEditScreenState();
}

class _TemplateEditScreenState extends ConsumerState<TemplateEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  final Set<String> _selectedPlayerIds = <String>{};
  final Map<int, String?> _rotationAssignments = {
    for (var rotation = 1; rotation <= 6; rotation++) rotation: null,
  };
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.template?.name ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.template?.description ?? '',
    );

    // Initialize from template or provided values
    if (widget.template != null) {
      _selectedPlayerIds.addAll(widget.template!.playerIds);
      for (var rotation = 1; rotation <= 6; rotation++) {
        _rotationAssignments[rotation] = widget.template!.defaultRotation[rotation];
      }
    } else if (widget.initialPlayerIds != null) {
      _selectedPlayerIds.addAll(widget.initialPlayerIds!);
    }

    if (widget.initialRotation != null) {
      for (var rotation = 1; rotation <= 6; rotation++) {
        _rotationAssignments[rotation] = widget.initialRotation![rotation];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(matchSetupRosterProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.template == null ? 'Create Template' : 'Edit Template'),
        backgroundColor: Colors.transparent,
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.indigo,
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.check_rounded),
              onPressed: _canSave() ? _handleSave : null,
              tooltip: 'Save Template',
            ),
        ],
      ),
      body: rosterAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.indigo),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Failed to load roster',
                style: const TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(matchSetupRosterProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (roster) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name field
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Template Name',
                  hintText: 'e.g., Varsity Starters',
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Description field
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                  hintText: 'Add notes about this template',
                ),
                style: const TextStyle(color: AppColors.textPrimary),
                maxLines: 2,
              ),
              const SizedBox(height: 24),

              // Roster Selection
              const Text(
                'Select Players',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: roster.map((player) {
                  final isSelected = _selectedPlayerIds.contains(player.id);
                  return FilterChip(
                    label: Text('#${player.jerseyNumber} ${player.name}'),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedPlayerIds.add(player.id);
                        } else {
                          _selectedPlayerIds.remove(player.id);
                          // Remove from rotation if deselected
                          for (var rotation = 1; rotation <= 6; rotation++) {
                            if (_rotationAssignments[rotation] == player.id) {
                              _rotationAssignments[rotation] = null;
                            }
                          }
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // Rotation Setup
              const Text(
                'Default Rotation (optional)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Set the default starting rotation for this template',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              if (_selectedPlayerIds.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Select players first to assign rotation',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                )
              else
                ...List.generate(6, (index) {
                  final rotation = index + 1;
                  final selectedPlayerId = _rotationAssignments[rotation];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: DropdownButtonFormField<String>(
                      value: selectedPlayerId,
                      decoration: InputDecoration(
                        labelText: 'Rotation $rotation',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Not assigned'),
                        ),
                        ...roster
                            .where((p) => _selectedPlayerIds.contains(p.id))
                            .map(
                              (player) => DropdownMenuItem<String>(
                                value: player.id,
                                child: Text('#${player.jerseyNumber} ${player.name}'),
                              ),
                            ),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _rotationAssignments[rotation] = value;
                        });
                      },
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSave() {
    return _nameController.text.trim().isNotEmpty &&
        _selectedPlayerIds.isNotEmpty &&
        !_isSaving;
  }

  Future<void> _handleSave() async {
    if (!_canSave()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final actions = ref.read(templateActionsProvider);
      final rotation = <int, String>{
        for (final entry in _rotationAssignments.entries)
          if (entry.value != null) entry.key: entry.value!,
      };

      // Get the selected team ID (or fallback to default for backwards compatibility)
      final selectedTeamId = ref.read(selectedTeamIdProvider);
      final effectiveTeamId = selectedTeamId ?? defaultTeamId;

      if (widget.template != null) {
        // Update existing template
        final repository = ref.read(matchSetupRepositoryProvider);
        final updated = widget.template!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          playerIds: _selectedPlayerIds,
          defaultRotation: rotation,
        );
        await repository.saveRosterTemplate(
          teamId: effectiveTeamId,
          template: updated,
        );
        ref.invalidate(rosterTemplatesDefaultProvider);
      } else {
        // Create new template
        await actions.saveTemplate(
          teamId: effectiveTeamId,
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          playerIds: _selectedPlayerIds,
          defaultRotation: rotation,
        );
      }

      if (!mounted) return;

      // Show success message before popping
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.template == null
                ? 'Template created'
                : 'Template updated',
          ),
          backgroundColor: AppColors.glass,
        ),
      );
      
      // Small delay to ensure snackbar is shown
      await Future.delayed(const Duration(milliseconds: 100));
      
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error, stackTrace) {
      debugPrint('Failed to save template: $error\n$stackTrace');
      debugPrint('Stack trace: $stackTrace');
      if (!mounted) return;
      
      // Show error message - don't pop on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save template: ${error.toString()}'),
          backgroundColor: AppColors.rose,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

