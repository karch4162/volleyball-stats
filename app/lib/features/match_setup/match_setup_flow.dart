import 'package:flutter/material.dart';

import 'models/match_draft.dart';
import 'models/match_player.dart';
import 'widgets/match_metadata_step.dart';
import 'widgets/roster_selection_step.dart';
import 'widgets/rotation_setup_step.dart';
import 'widgets/summary_step.dart';

class MatchSetupFlow extends StatefulWidget {
  const MatchSetupFlow({super.key});

  @override
  State<MatchSetupFlow> createState() => _MatchSetupFlowState();
}

class _MatchSetupFlowState extends State<MatchSetupFlow> {
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

  final List<MatchPlayer> _demoRoster = const [
    MatchPlayer(
      id: 'player-avery',
      name: 'Avery Harper',
      jerseyNumber: 2,
      position: 'Setter',
    ),
    MatchPlayer(
      id: 'player-bailey',
      name: 'Bailey Jordan',
      jerseyNumber: 5,
      position: 'Opposite',
    ),
    MatchPlayer(
      id: 'player-casey',
      name: 'Casey Lane',
      jerseyNumber: 11,
      position: 'Outside Hitter',
    ),
    MatchPlayer(
      id: 'player-devon',
      name: 'Devon Cruz',
      jerseyNumber: 9,
      position: 'Middle Blocker',
    ),
    MatchPlayer(
      id: 'player-elliot',
      name: 'Elliot Kim',
      jerseyNumber: 4,
      position: 'Libero',
    ),
    MatchPlayer(
      id: 'player-finley',
      name: 'Finley Brooks',
      jerseyNumber: 7,
      position: 'Middle Blocker',
    ),
    MatchPlayer(
      id: 'player-greer',
      name: 'Greer Miles',
      jerseyNumber: 10,
      position: 'Outside Hitter',
    ),
  ];

  @override
  void dispose() {
    _opponentController.dispose();
    _locationController.dispose();
    _seasonLabelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Match Setup'),
      ),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: _handleContinue,
        onStepCancel: _handleBack,
        controlsBuilder: (context, details) {
          final isLastStep = _currentStep == _steps.length - 1;
          return Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Row(
              children: [
                FilledButton(
                  onPressed: details.onStepContinue,
                  child: Text(isLastStep ? 'Finish' : 'Continue'),
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
        steps: _steps,
      ),
    );
  }

  List<Step> get _steps {
    final selectedPlayers = _demoRoster
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
          roster: _demoRoster,
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

  void _handleContinue() {
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
        _handleSubmit();
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

  void _handleSubmit() {
    final draft = _draft;
    final message = [
      'Match vs ${draft.opponent}',
      if (draft.matchDate != null)
        MaterialLocalizations.of(context).formatFullDate(draft.matchDate!),
      '${draft.selectedPlayerIds.length} players, rotation ready',
    ].join(' • ');

    _showSnackBar('Match draft saved: $message');
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

