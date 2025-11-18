import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/connection_guard.dart';
import '../teams/team_providers.dart';
import 'player_providers.dart';

class PlayerCreateScreen extends ConsumerStatefulWidget {
  const PlayerCreateScreen({super.key});

  @override
  ConsumerState<PlayerCreateScreen> createState() => _PlayerCreateScreenState();
}

class _PlayerCreateScreenState extends ConsumerState<PlayerCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _jerseyController = TextEditingController();
  final _positionController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _positionOptions = [
    'Setter',
    'Outside Hitter',
    'Opposite',
    'Middle Blocker',
    'Libero',
    'Defensive Specialist',
  ];

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jerseyController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _handleCreate() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final selectedTeam = ref.read(selectedTeamProvider);
      if (selectedTeam == null) {
        throw Exception('Please select a team first');
      }

      final jerseyNumber = int.tryParse(_jerseyController.text.trim());
      if (jerseyNumber == null) {
        throw Exception('Invalid jersey number');
      }

      final playerService = ref.read(playerServiceProvider);
      await playerService.createPlayer(
        teamId: selectedTeam.id,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        jerseyNumber: jerseyNumber,
        position: _positionController.text.trim().isEmpty
            ? null
            : _positionController.text.trim(),
      );

      // Invalidate players provider to refresh list
      ref.invalidate(teamPlayersProvider(selectedTeam.id));

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Player added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTeam = ref.watch(selectedTeamProvider);

    if (selectedTeam == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Player')),
        body: Container(
          decoration: const BoxDecoration(color: AppColors.background),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 64,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Team Selected',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please select a team before adding players.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return ConnectionGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Add Player'),
              Text(
                selectedTeam.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
              ),
            ],
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            color: AppColors.background,
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(32.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(
                        Icons.person_add,
                        size: 64,
                        color: AppColors.indigo,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Add New Player',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 32),
                      TextFormField(
                        controller: _firstNameController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'First Name *',
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: AppColors.glassLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'First name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _lastNameController,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          labelText: 'Last Name *',
                          prefixIcon: const Icon(Icons.person_outline),
                          filled: true,
                          fillColor: AppColors.glassLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _jerseyController,
                        enabled: !_isLoading,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Jersey Number *',
                          prefixIcon: const Icon(Icons.numbers),
                          filled: true,
                          fillColor: AppColors.glassLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Jersey number is required';
                          }
                          final num = int.tryParse(value.trim());
                          if (num == null || num < 1 || num > 99) {
                            return 'Jersey number must be between 1 and 99';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _positionController.text.isEmpty ? null : _positionController.text,
                        decoration: InputDecoration(
                          labelText: 'Position',
                          prefixIcon: const Icon(Icons.sports_volleyball),
                          filled: true,
                          fillColor: AppColors.glassLight,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: [
                          const DropdownMenuItem<String>(
                            value: null,
                            child: Text('None'),
                          ),
                          ..._positionOptions.map((position) => DropdownMenuItem<String>(
                                value: position,
                                child: Text(position),
                              )),
                        ],
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                _positionController.text = value ?? '';
                              },
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.red),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline, color: Colors.red),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _errorMessage!,
                                  style: const TextStyle(color: Colors.red),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _handleCreate,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Add Player'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

