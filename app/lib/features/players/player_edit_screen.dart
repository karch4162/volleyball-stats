import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/connection_guard.dart';
import '../match_setup/models/match_player.dart';
import '../teams/team_providers.dart';
import 'player_providers.dart';

class PlayerEditScreen extends ConsumerStatefulWidget {
  const PlayerEditScreen({super.key, required this.player});

  final MatchPlayer player;

  @override
  ConsumerState<PlayerEditScreen> createState() => _PlayerEditScreenState();
}

class _PlayerEditScreenState extends ConsumerState<PlayerEditScreen> {
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _jerseyController;
  late final TextEditingController _positionController;
  bool _isLoading = false;
  bool _isDeleting = false;
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
  void initState() {
    super.initState();
    // Split name into first and last
    final nameParts = widget.player.name.split(' ');
    _firstNameController = TextEditingController(
      text: nameParts.isNotEmpty ? nameParts.first : '',
    );
    _lastNameController = TextEditingController(
      text: nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
    );
    _jerseyController = TextEditingController(
      text: widget.player.jerseyNumber.toString(),
    );
    _positionController = TextEditingController(
      text: widget.player.position,
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _jerseyController.dispose();
    _positionController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final selectedTeam = ref.read(selectedTeamProvider);
      if (selectedTeam == null) {
        throw Exception('Team not selected');
      }

      final jerseyNumber = int.tryParse(_jerseyController.text.trim());
      if (jerseyNumber == null) {
        throw Exception('Invalid jersey number');
      }

      final playerService = ref.read(playerServiceProvider);
      await playerService.updatePlayer(
        playerId: widget.player.id,
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
            content: Text('Player updated successfully!'),
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

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Player'),
        content: Text('Are you sure you want to remove "${widget.player.name}" from the roster?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _isDeleting = true;
      _errorMessage = null;
    });

    try {
      final playerService = ref.read(playerServiceProvider);
      await playerService.deletePlayer(widget.player.id);

      final selectedTeam = ref.read(selectedTeamProvider);
      if (selectedTeam != null) {
        ref.invalidate(teamPlayersProvider(selectedTeam.id));
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Player removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isDeleting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTeam = ref.watch(selectedTeamProvider);

    return ConnectionGuard(
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Player'),
              if (selectedTeam != null)
                Text(
                  selectedTeam.name,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                ),
            ],
          ),
          actions: [
            if (_isLoading || _isDeleting)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                tooltip: 'Remove Player',
                onPressed: _handleDelete,
              ),
          ],
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.indigo.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.player.jerseyNumber}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColors.indigo,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Edit Player',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _firstNameController,
                      enabled: !_isLoading && !_isDeleting,
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
                      enabled: !_isLoading && !_isDeleting,
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
                      enabled: !_isLoading && !_isDeleting,
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
                      onChanged: (_isLoading || _isDeleting)
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
                      onPressed: (_isLoading || _isDeleting) ? null : _handleSave,
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
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

