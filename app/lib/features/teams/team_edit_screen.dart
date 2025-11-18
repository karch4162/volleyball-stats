import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../../core/widgets/connection_guard.dart';
import 'models/team.dart';
import 'team_providers.dart';

class TeamEditScreen extends ConsumerStatefulWidget {
  const TeamEditScreen({super.key, required this.team});

  final Team team;

  @override
  ConsumerState<TeamEditScreen> createState() => _TeamEditScreenState();
}

class _TeamEditScreenState extends ConsumerState<TeamEditScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _levelController;
  late final TextEditingController _seasonController;
  bool _isLoading = false;
  bool _isDeleting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.team.name);
    _levelController = TextEditingController(text: widget.team.level ?? '');
    _seasonController = TextEditingController(text: widget.team.seasonLabel ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _levelController.dispose();
    _seasonController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final teamService = ref.read(teamServiceProvider);
      await teamService.updateTeam(
        teamId: widget.team.id,
        name: _nameController.text.trim(),
        level: _levelController.text.trim().isEmpty ? null : _levelController.text.trim(),
        seasonLabel: _seasonController.text.trim().isEmpty ? null : _seasonController.text.trim(),
      );

      // Invalidate teams provider to refresh list
      ref.invalidate(coachTeamsProvider);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team updated successfully!'),
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
        title: const Text('Delete Team'),
        content: Text('Are you sure you want to delete "${widget.team.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
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
      final teamService = ref.read(teamServiceProvider);
      await teamService.deleteTeam(widget.team.id);

      // Invalidate teams provider to refresh list
      ref.invalidate(coachTeamsProvider);

      if (mounted) {
        Navigator.of(context).pop(); // Pop edit screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team deleted successfully'),
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
    return ConnectionGuard(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Team'),
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
                tooltip: 'Delete Team',
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
                    Icon(
                      Icons.sports_volleyball,
                      size: 64,
                      color: AppColors.indigo,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Edit Team',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 32),
                    TextFormField(
                      controller: _nameController,
                      enabled: !_isLoading && !_isDeleting,
                      decoration: InputDecoration(
                        labelText: 'Team Name *',
                        prefixIcon: const Icon(Icons.group),
                        filled: true,
                        fillColor: AppColors.glassLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Team name is required';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _levelController,
                      enabled: !_isLoading && !_isDeleting,
                      decoration: InputDecoration(
                        labelText: 'Level (e.g., Varsity, JV)',
                        prefixIcon: const Icon(Icons.star),
                        filled: true,
                        fillColor: AppColors.glassLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _seasonController,
                      enabled: !_isLoading && !_isDeleting,
                      decoration: InputDecoration(
                        labelText: 'Season (e.g., 2025)',
                        prefixIcon: const Icon(Icons.calendar_today),
                        filled: true,
                        fillColor: AppColors.glassLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
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

