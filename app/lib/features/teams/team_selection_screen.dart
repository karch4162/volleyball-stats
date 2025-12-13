import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_service.dart';
import 'team_providers.dart';

class TeamSelectionScreen extends ConsumerStatefulWidget {
  const TeamSelectionScreen({super.key});

  @override
  ConsumerState<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends ConsumerState<TeamSelectionScreen> {
  bool _hasAutoSelected = false;

  @override
  Widget build(BuildContext context) {
    final teamsAsync = ref.watch(coachTeamsProvider);
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    // Auto-select single team - HomeScreen will rebuild and show MatchSetupLandingScreen
    teamsAsync.whenData((teams) {
      if (teams.length == 1 && !_hasAutoSelected && selectedTeamId == null) {
        _hasAutoSelected = true;
        if (kDebugMode) {
          debugPrint('[TeamSelectionScreen] Auto-selecting single team: ${teams.first.id}');
        }
        // Set immediately - this will trigger HomeScreen to rebuild
        // We're in the build method, so we need to schedule it for after this build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Double-check it's still null (race condition protection)
          final currentId = ref.read(selectedTeamIdProvider);
          if (currentId == null) {
            if (kDebugMode) {
              debugPrint('[TeamSelectionScreen] Setting selected team ID to: ${teams.first.id}');
            }
            ref.read(selectedTeamIdProvider.notifier).state = teams.first.id;
            if (kDebugMode) {
              debugPrint('[TeamSelectionScreen] Team ID set to ${teams.first.id}, expecting HomeScreen rebuild');
            }
          } else {
            if (kDebugMode) {
              debugPrint('[TeamSelectionScreen] Team ID already set to $currentId, skipping');
            }
          }
        });
      }
    });

    if (kDebugMode) {
      debugPrint('[TeamSelectionScreen] Building...');
      debugPrint('[TeamSelectionScreen] Selected team ID: ${selectedTeamId ?? "null"}');
      debugPrint('[TeamSelectionScreen] Teams async state: loading=${teamsAsync.isLoading}, hasValue=${teamsAsync.hasValue}, hasError=${teamsAsync.hasError}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Team'),
        actions: [
          if (currentUser != null)
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'logout') {
                  ref.read(authServiceProvider).signOut();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      Icon(Icons.logout, size: 20),
                      SizedBox(width: 8),
                      Text('Sign Out'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          color: AppColors.background,
        ),
        child: teamsAsync.when(
          data: (teams) {
            if (teams.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.group_outlined,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Teams Found',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create your first team to get started.',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppColors.textSecondary,
                              ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            // TODO: Navigate to team creation screen
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Team creation coming in Phase 9'),
                              ),
                            );
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Create Team'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: teams.length,
              itemBuilder: (context, index) {
                final team = teams[index];
                final isSelected = team.id == selectedTeamId;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GlassContainer(
                    padding: const EdgeInsets.all(16),
                    onTap: () {
                      ref.read(selectedTeamIdProvider.notifier).state = team.id;
                      Navigator.of(context).pop();
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.indigo.withOpacity(0.2)
                                : AppColors.glassLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.sports_volleyball,
                            color: isSelected ? AppColors.indigo : AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                team.name,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              if (team.level != null || team.seasonLabel != null) ...[
                                const SizedBox(height: 4),
                                Text(
                                  [
                                    if (team.level != null) team.level,
                                    if (team.seasonLabel != null) team.seasonLabel,
                                  ].join(' • '),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.indigo,
                          ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, stack) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: GlassContainer(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error Loading Teams',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      error.toString(),
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
      ),
    );
  }
}

