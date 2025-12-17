import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/supabase_client_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../teams/team_providers.dart';
import 'providers.dart';
import 'models/match_draft.dart';
import 'models/match_player.dart';
import 'models/roster_template.dart';
import 'widgets/match_metadata_step.dart';
import 'widgets/roster_selection_step.dart';
import 'widgets/rotation_setup_step.dart';
import 'widgets/summary_step.dart';
import 'widgets/streamlined_setup_body.dart';
import 'constants.dart';

class MatchSetupFlow extends ConsumerStatefulWidget {
  const MatchSetupFlow({
    super.key,
    this.matchId,
    this.lastDraft,
    this.template,
  });

  final String? matchId;
  final MatchDraft? lastDraft;
  final RosterTemplate? template;

  @override
  ConsumerState<MatchSetupFlow> createState() => _MatchSetupFlowState();
}

class _MatchSetupFlowState extends ConsumerState<MatchSetupFlow> {
  final _opponentController = TextEditingController();
  final _locationController = TextEditingController();
  final _seasonLabelController = TextEditingController(text: DateTime.now().year.toString());

  DateTime? _matchDate;
  int _currentStep = 0;
  MatchDraft _draft = MatchDraft.initial();
  final Set<String> _selectedPlayerIds = <String>{};
  final Map<int, String?> _rotationAssignments = {
    for (var rotation = 1; rotation <= 6; rotation++) rotation: null,
  };
  late final String _matchId;
  bool _isSaving = false;
  bool _isAutoSaving = false;
  String? _lastAutoSaveError;
  Timer? _autoSaveTimer;
  late final bool _isSupabaseEnabled;

  @override
  void initState() {
    super.initState();
    _isSupabaseEnabled = ref.read(supabaseClientProvider) != null;
    _matchId = widget.matchId ??
        (_isSupabaseEnabled ? defaultMatchDraftId : const Uuid().v4());
    _setupAutoSaveListeners();
    Future.microtask(_initializeDraft);
  }

  void _setupAutoSaveListeners() {
    // Listen to text field changes
    _opponentController.addListener(_scheduleAutoSave);
    _locationController.addListener(_scheduleAutoSave);
    _seasonLabelController.addListener(_scheduleAutoSave);
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _opponentController.removeListener(_scheduleAutoSave);
    _locationController.removeListener(_scheduleAutoSave);
    _seasonLabelController.removeListener(_scheduleAutoSave);
    _opponentController.dispose();
    _locationController.dispose();
    _seasonLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rosterAsync = ref.watch(matchSetupRosterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Setup'),
        actions: [
          // Auto-save indicator
          if (_isAutoSaving)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else if (_lastAutoSaveError != null)
            IconButton(
              icon: const Icon(Icons.error_outline_rounded),
              tooltip: _lastAutoSaveError,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(_lastAutoSaveError!),
                    action: SnackBarAction(
                      label: 'Retry',
                      onPressed: () => _performAutoSave(),
                    ),
                  ),
                );
              },
            )
          else if (_draft.opponent.isNotEmpty || 
                   _draft.selectedPlayerIds.isNotEmpty ||
                   _draft.startingRotation.isNotEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Icon(Icons.check_circle_outline_rounded, size: 20),
            ),
          if (_draft.hasRotation && _selectedPlayerIds.length >= 6)
            IconButton(
              icon: const Icon(Icons.star_outline_rounded),
              tooltip: 'Save as Template',
              onPressed: () => _saveAsTemplate(context),
            ),
        ],
      ),
      body: rosterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: 'Unable to load roster',
          onRetry: () => ref.refresh(matchSetupRosterProvider),
        ),
        data: (roster) {
          _pruneSelections(roster);
          _updateDraftState();

          return StreamlinedSetupBody(
            draft: _draft,
            roster: roster,
            selectedPlayerIds: _selectedPlayerIds,
            rotationAssignments: _rotationAssignments,
            opponentController: _opponentController,
            locationController: _locationController,
            seasonLabelController: _seasonLabelController,
            matchDate: _matchDate,
            onTogglePlayer: _togglePlayerSelection,
            onSelectRotation: _updateRotationSelection,
            onPickDate: () => _pickMatchDate(context),
            onUseTemplate: widget.template == null && _selectedPlayerIds.isEmpty
                ? () => _showTemplatePicker(context, ref)
                : null,
            onCloneLast: widget.lastDraft == null && _selectedPlayerIds.isEmpty
                ? () => _applyLastDraft(ref)
                : null,
            onSaveDraft: () => _saveDraft(context, ref),
            onStartMatch: () => _handleSubmit(context, ref),
            isSaving: _isSaving,
          );
        },
      ),
    );
  }

  List<Step> _buildSteps(List<MatchPlayer> roster) {
    final selectedPlayers = roster
        .where((player) => _selectedPlayerIds.contains(player.id))
        .toList(growable: false);

    return [
      Step(
        title: const Text('Match'),
        isActive: _currentStep >= 0,
        state: _currentStep > 0 ? StepState.complete : StepState.indexed,
        content: MatchMetadataStep(
          opponentController: _opponentController,
          locationController: _locationController,
          seasonLabelController: _seasonLabelController,
          matchDate: _matchDate,
          onPickDate: () => _pickMatchDate(context),
        ),
      ),
      Step(
        title: const Text('Roster'),
        isActive: _currentStep >= 1,
        state: _currentStep > 1 ? StepState.complete : StepState.indexed,
        content: RosterSelectionStep(
          roster: roster,
          selectedPlayerIds: _selectedPlayerIds,
          onTogglePlayer: _togglePlayerSelection,
        ),
      ),
      Step(
        title: const Text('Rotation'),
        isActive: _currentStep >= 2,
        state: _currentStep > 2
            ? StepState.complete
            : (_currentStep == 2 && _draft.hasRotation ? StepState.complete : StepState.indexed),
        content: RotationSetupStep(
          availablePlayers: selectedPlayers,
          rotationAssignments: _rotationAssignments,
          onSelectPlayer: _updateRotationSelection,
        ),
      ),
      Step(
        title: const Text('Summary'),
        isActive: _currentStep >= 3,
        state: _currentStep == 3 && _draft.hasRotation ? StepState.complete : StepState.indexed,
        content: SummaryStep(
          draft: _draft,
          selectedPlayers: selectedPlayers,
        ),
      ),
    ];
  }

  Future<void> _pickMatchDate(BuildContext context) async {
    final now = DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _matchDate ?? now,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );
    if (selectedDate != null) {
      setState(() {
        _matchDate = selectedDate;
      });
    }
  }

  void _togglePlayerSelection(String playerId) {
    setState(() {
      if (_selectedPlayerIds.contains(playerId)) {
        _selectedPlayerIds.remove(playerId);
        _rotationAssignments.updateAll(
          (key, value) => value == playerId ? null : value,
        );
      } else {
        _selectedPlayerIds.add(playerId);
      }
      _updateDraftState();
    });
    _scheduleAutoSave();
  }

  void _updateRotationSelection(int rotation, String? playerId) {
    setState(() {
      _rotationAssignments[rotation] = playerId;
      _updateDraftState();
    });
    _scheduleAutoSave();
  }

  void _updateDraftState() {
    final rotation = <int, String>{
      for (final entry in _rotationAssignments.entries)
        if (entry.value != null) entry.key: entry.value!,
    };

    _draft = _draft.copyWith(
      opponent: _opponentController.text.trim(),
      matchDate: _matchDate,
      location: _locationController.text.trim(),
      seasonLabel: _seasonLabelController.text.trim(),
      selectedPlayerIds: _selectedPlayerIds,
      startingRotation: rotation,
    );
  }

  void _scheduleAutoSave() {
    // Cancel existing timer
    _autoSaveTimer?.cancel();
    
    // Schedule new auto-save after 2 seconds of inactivity
    _autoSaveTimer = Timer(const Duration(seconds: 2), () {
      _performAutoSave();
    });
  }

  Future<void> _performAutoSave() async {
    if (_isSaving || _isAutoSaving) return;
    
    _updateDraftState();
    
    // Skip auto-save if draft is empty (no meaningful data)
    if (_draft.opponent.isEmpty && 
        _draft.selectedPlayerIds.isEmpty && 
        _draft.startingRotation.isEmpty) {
      return;
    }

    setState(() {
      _isAutoSaving = true;
      _lastAutoSaveError = null;
    });

    try {
      final repository = ref.read(matchSetupRepositoryProvider);
      final selectedTeamId = ref.read(selectedTeamIdProvider);
      final effectiveTeamId = selectedTeamId ?? defaultTeamId;
      await repository.saveDraft(
        teamId: effectiveTeamId,
        matchId: _matchId,
        draft: _draft,
      );
      
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
        });
        if (kDebugMode) {
          print('Auto-save successful for draft: $_matchId');
        }
      }
    } catch (error, stackTrace) {
      debugPrint('Auto-save failed: $error\n$stackTrace');
      if (mounted) {
        setState(() {
          _isAutoSaving = false;
          _lastAutoSaveError = 'Auto-save failed: ${error.toString()}';
        });
      }
    }
  }

  void _handleBack() {
    if (_currentStep == 0) {
      return;
    }
    setState(() {
      _currentStep -= 1;
    });
  }

  Future<void> _handleContinue() async {
    switch (_currentStep) {
      case 0:
        if (_validateMatchMetadata()) {
          setState(() {
            _draft = _draft.copyWith(
              opponent: _opponentController.text.trim(),
              matchDate: _matchDate,
              location: _locationController.text.trim(),
              seasonLabel: _seasonLabelController.text.trim(),
            );
            _currentStep += 1;
          });
        }
        break;
      case 1:
        if (_validateRosterSelection()) {
          setState(() {
            _draft = _draft.copyWith(selectedPlayerIds: _selectedPlayerIds);
            _currentStep += 1;
          });
        }
        break;
      case 2:
        if (_validateRotation()) {
          final rotation = <int, String>{
            for (final entry in _rotationAssignments.entries)
              if (entry.value != null) entry.key: entry.value!,
          };
          setState(() {
            _draft = _draft.copyWith(startingRotation: rotation);
            _currentStep += 1;
          });
        }
        break;
      case 3:
        await _handleSubmit(context, ref);
        break;
    }
  }

  bool _validateMatchMetadata() {
    if (_opponentController.text.trim().isEmpty) {
      _showSnackBar('Add an opponent to continue.');
      return false;
    }
    if (_matchDate == null) {
      _showSnackBar('Pick the match date to continue.');
      return false;
    }
    return true;
  }

  bool _validateRosterSelection() {
    if (_selectedPlayerIds.length < 6) {
      _showSnackBar('Select at least six players for your match roster.');
      return false;
    }
    return true;
  }

  bool _validateRotation() {
    final missing = _rotationAssignments.entries.where((entry) => entry.value == null).length;
    if (missing > 0) {
      _showSnackBar('Assign all six rotation spots before continuing.');
      return false;
    }
    return true;
  }

  Future<void> _saveDraft(BuildContext context, WidgetRef ref) async {
    // Cancel any pending auto-save
    _autoSaveTimer?.cancel();
    
    _updateDraftState();
    final repository = ref.read(matchSetupRepositoryProvider);
    setState(() {
      _isSaving = true;
    });

    try {
      final selectedTeamId = ref.read(selectedTeamIdProvider);
      final effectiveTeamId = selectedTeamId ?? defaultTeamId;
      await repository.saveDraft(
        teamId: effectiveTeamId,
        matchId: _matchId,
        draft: _draft,
      );
      if (!mounted) return;
      _showSnackBar('Draft saved');
      // Clear any auto-save error on successful manual save
      setState(() {
        _lastAutoSaveError = null;
      });
    } catch (error, stackTrace) {
      debugPrint('Failed to save draft: $error\n$stackTrace');
      if (!mounted) return;
      _showSnackBar('Failed to save draft. Please retry.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _handleSubmit(BuildContext context, WidgetRef ref) async {
    // Cancel any pending auto-save
    _autoSaveTimer?.cancel();
    
    // Ensure draft state is up to date
    _updateDraftState();
    
    final repository = ref.read(matchSetupRepositoryProvider);
    setState(() {
      _isSaving = true;
    });

    try {
      final selectedTeamId = ref.read(selectedTeamIdProvider);
      final effectiveTeamId = selectedTeamId ?? defaultTeamId;
      await repository.saveDraft(
        teamId: effectiveTeamId,
        matchId: _matchId,
        draft: _draft,
      );
      if (!mounted) return;
      context.pushReplacement('/match/$_matchId/rally');
    } catch (error, stackTrace) {
      debugPrint('Failed to save match draft: $error\n$stackTrace');
      if (!mounted) return;
      _showSnackBar('Failed to save match draft. Please retry.');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveAsTemplate(BuildContext context) async {
    final rotation = <int, String>{
      for (final entry in _rotationAssignments.entries)
        if (entry.value != null) entry.key: entry.value!,
    };

    final saved = await context.push<bool>(
      '/templates/create',
      extra: {
        'initialPlayerIds': _selectedPlayerIds,
        'initialRotation': rotation,
      },
    );

    if (saved == true && mounted) {
      _showSnackBar('Template saved!');
    }
  }

  Future<void> _showTemplatePicker(BuildContext context, WidgetRef ref) async {
    final templatesAsync = ref.read(rosterTemplatesDefaultProvider);
    final templates = templatesAsync.when(
      data: (templates) => templates,
      loading: () => <RosterTemplate>[],
      error: (_, __) => <RosterTemplate>[],
    );

    if (templates.isEmpty) {
      _showSnackBar('No templates available. Create one first!');
      return;
    }

    final selected = await showModalBottomSheet<RosterTemplate>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _TemplatePickerSheet(templates: templates),
    );

    if (selected != null && mounted) {
      final selectedTeamId = ref.read(selectedTeamIdProvider);
      final effectiveTeamId = selectedTeamId ?? defaultTeamId;
      final actions = ref.read(templateActionsProvider);
      await actions.useTemplate(
        teamId: effectiveTeamId,
        templateId: selected.id,
      );
      _applyTemplate(selected);
    }
  }

  Future<void> _applyLastDraft(WidgetRef ref) async {
    final lastDraftAsync = ref.read(lastMatchDraftProvider);
    MatchDraft? draft;
    lastDraftAsync.when(
      data: (d) {
        draft = d;
      },
      loading: () {},
      error: (_, __) {},
    );
    
    if (draft != null && mounted) {
      _applyDraft(draft!);
    } else if (mounted) {
      _showSnackBar('No previous match found');
    }
  }

  Future<void> _initializeDraft() async {
    // Pre-populate from template or last draft if provided
    if (widget.template != null) {
      _applyTemplate(widget.template!);
      return;
    }

    if (widget.lastDraft != null) {
      _applyDraft(widget.lastDraft!);
      return;
    }

    // Otherwise, try loading from repository
    await _loadDraft();
  }

  void _applyTemplate(RosterTemplate template) {
    setState(() {
      _selectedPlayerIds.clear();
      _selectedPlayerIds.addAll(template.playerIds);
      
      _rotationAssignments.clear();
      for (var rotation = 1; rotation <= 6; rotation++) {
        _rotationAssignments[rotation] = template.defaultRotation[rotation];
      }
      
      // Update draft state immediately so validation works
      _updateDraftState();
    });
  }

  void _applyDraft(MatchDraft draft) {
    setState(() {
      _draft = draft;
      _opponentController.text = draft.opponent;
      _locationController.text = draft.location;
      _seasonLabelController.text = draft.seasonLabel;
      _matchDate = draft.matchDate;
      _selectedPlayerIds
        ..clear()
        ..addAll(draft.selectedPlayerIds);

      for (var rotation = 1; rotation <= 6; rotation++) {
        _rotationAssignments[rotation] = draft.startingRotation[rotation];
      }
    });
  }

  Future<void> _loadDraft() async {
    final repository = ref.read(matchSetupRepositoryProvider);
    final draft = await repository.loadDraft(matchId: _matchId);
    if (draft == null || !mounted) {
      return;
    }

    _applyDraft(draft);
  }

  void _pruneSelections(List<MatchPlayer> roster) {
    final rosterIds = roster.map((player) => player.id).toSet();
    final sanitizedSelection = _selectedPlayerIds.where(rosterIds.contains).toSet();

    bool changed = sanitizedSelection.length != _selectedPlayerIds.length;

    final sanitizedRotation = <int, String?>{};
    for (final entry in _rotationAssignments.entries) {
      final playerId = entry.value;
      if (playerId != null && !rosterIds.contains(playerId)) {
        sanitizedRotation[entry.key] = null;
        changed = true;
      } else {
        sanitizedRotation[entry.key] = playerId;
      }
    }

    if (changed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() {
          _selectedPlayerIds
            ..clear()
            ..addAll(sanitizedSelection);
          _rotationAssignments
            ..clear()
            ..addAll(sanitizedRotation);
        });
      });
    }
  }
}

class _TemplatePickerSheet extends StatelessWidget {
  const _TemplatePickerSheet({required this.templates});

  final List<RosterTemplate> templates;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: EdgeInsets.zero,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'Select Template',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: AppColors.textMuted,
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: templates.length,
                itemBuilder: (context, index) {
                  final template = templates[index];
                  return ListTile(
                    key: ValueKey('flow-template-${template.id}'),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.indigoDark.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.star_rounded,
                        color: AppColors.indigo,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      template.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      '${template.playerIds.length} players${template.defaultRotation.isNotEmpty ? ' • Rotation set' : ''}',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                    onTap: () => Navigator.of(context).pop(template),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

