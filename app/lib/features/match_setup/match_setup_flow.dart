import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/supabase_client_provider.dart';
import 'providers.dart';
import 'models/match_draft.dart';
import 'models/match_player.dart';
import 'widgets/match_metadata_step.dart';
import 'widgets/roster_selection_step.dart';
import 'widgets/rotation_setup_step.dart';
import 'widgets/summary_step.dart';

class MatchSetupFlow extends ConsumerStatefulWidget {
  const MatchSetupFlow({super.key, this.matchId});

  final String? matchId;

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
  late final bool _isSupabaseEnabled;

  @override
  void initState() {
    super.initState();
    _isSupabaseEnabled = ref.read(supabaseClientProvider) != null;
    _matchId = widget.matchId ??
        (_isSupabaseEnabled ? defaultMatchDraftId : const Uuid().v4());
    Future.microtask(_loadDraft);
  }

  @override
  void dispose() {
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
      ),
      body: rosterAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorView(
          message: 'Unable to load roster',
          onRetry: () => ref.refresh(matchSetupRosterProvider),
        ),
        data: (roster) {
          _pruneSelections(roster);
          final steps = _buildSteps(roster);

          return Stepper(
            type: StepperType.horizontal,
            currentStep: _currentStep,
            onStepContinue: _isSaving ? null : () => _handleContinue(),
            onStepCancel: _handleBack,
            controlsBuilder: (context, details) {
              final isLastStep = _currentStep == steps.length - 1;
              return Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Row(
                  children: [
                    FilledButton(
                      onPressed: _isSaving ? null : details.onStepContinue,
                      child: Text(
                        _isSaving
                            ? 'Saving...'
                            : isLastStep
                                ? 'Finish'
                                : 'Continue',
                      ),
                    ),
                    const SizedBox(width: 12),
                    if (_currentStep > 0)
                      TextButton(
                        onPressed: details.onStepCancel,
                        child: const Text('Back'),
                      ),
                  ],
                ),
              );
            },
            steps: steps,
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
    });
  }

  void _updateRotationSelection(int rotation, String? playerId) {
    setState(() {
      _rotationAssignments[rotation] = playerId;
    });
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
        await _handleSubmit();
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

  Future<void> _handleSubmit() async {
    final repository = ref.read(matchSetupRepositoryProvider);
    setState(() {
      _isSaving = true;
    });

    try {
      await repository.saveDraft(
        teamId: defaultTeamId,
        matchId: _matchId,
        draft: _draft,
      );
      if (!mounted) return;
      final draft = _draft;
      final message = [
        'Match vs ${draft.opponent}',
        if (draft.matchDate != null)
          MaterialLocalizations.of(context).formatFullDate(draft.matchDate!),
        '${draft.selectedPlayerIds.length} players, rotation ready',
      ].join(' • ');
      _showSnackBar('Match draft saved: $message');
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

  Future<void> _loadDraft() async {
    final repository = ref.read(matchSetupRepositoryProvider);
    final draft = await repository.loadDraft(matchId: _matchId);
    if (draft == null || !mounted) {
      return;
    }

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

