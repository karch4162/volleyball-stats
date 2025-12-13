import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/logger.dart';
import '../../core/widgets/glass_container.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_service.dart';
import '../teams/team_create_screen.dart';
import '../teams/team_providers.dart';
import '../teams/team_selection_screen.dart';
import 'match_setup_landing_screen.dart';
import 'providers.dart';

final _logger = createLogger('HomeScreen');

/// Home screen that shows team selection or match setup landing
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Trigger cache sync when authenticated (runs in background)
    ref.watch(cacheSyncProvider);
    
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    final teamsAsync = ref.watch(coachTeamsProvider);
    final currentUser = ref.watch(currentUserProvider);
    
    // Listen to selectedTeamId changes to ensure we rebuild when it changes
    ref.listen<String?>(selectedTeamIdProvider, (previous, next) {
      if (kDebugMode) {
        debugPrint('[HomeScreen] selectedTeamId changed from ${previous ?? "null"} to ${next ?? "null"}');
      }
    });

    // Debug logging
    if (kDebugMode) {
      debugPrint('[HomeScreen] Building...');
      debugPrint('[HomeScreen] Selected team ID: ${selectedTeamId ?? "null"}');
      debugPrint('[HomeScreen] Teams async state: loading=${teamsAsync.isLoading}, hasValue=${teamsAsync.hasValue}, hasError=${teamsAsync.hasError}');
      if (teamsAsync.hasValue) {
        debugPrint('[HomeScreen] Teams loaded: ${teamsAsync.value?.length ?? 0}');
      }
      if (teamsAsync.hasError) {
        debugPrint('[HomeScreen] Error loading teams: ${teamsAsync.error}');
        debugPrint('[HomeScreen] Stack trace: ${teamsAsync.stackTrace}');
      }
    }

    // Check if team is selected FIRST - this ensures we rebuild properly when team ID changes
    if (selectedTeamId != null) {
      if (kDebugMode) {
        debugPrint('[HomeScreen] Team selected ($selectedTeamId), showing MatchSetupLandingScreen');
      }
      return teamsAsync.when(
        data: (_) {
          if (kDebugMode) {
            debugPrint('[HomeScreen] Teams loaded, rendering MatchSetupLandingScreen');
          }
          return const MatchSetupLandingScreen();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) {
          if (kDebugMode) {
            debugPrint('[HomeScreen] Error loading teams when team is selected: $error');
            debugPrint('[HomeScreen] Stack trace: $stack');
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Error Loading Teams')),
            body: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
              ),
              child: Center(
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
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(coachTeamsProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }

    // If no team is selected, show team selection
    if (kDebugMode) {
      debugPrint('[HomeScreen] No team selected, showing team selection UI');
    }
    if (selectedTeamId == null) {
      if (kDebugMode) {
        debugPrint('[HomeScreen] No team selected, showing team selection UI');
        debugPrint('[HomeScreen] Teams state: loading=${teamsAsync.isLoading}, hasValue=${teamsAsync.hasValue}, hasError=${teamsAsync.hasError}');
        if (teamsAsync.hasValue) {
          debugPrint('[HomeScreen] ⭐ Teams already loaded: ${teamsAsync.value?.length ?? 0} teams');
        }
      }
      return teamsAsync.when(
        data: (teams) {
          if (kDebugMode) {
            debugPrint('[HomeScreen] Teams data received: ${teams.length} teams');
          }
          if (teams.isEmpty) {
            // No teams - show empty state with create option
            if (kDebugMode) {
              debugPrint('[HomeScreen] No teams found, showing empty state');
            }
            return Scaffold(
              appBar: AppBar(
                title: const Text('Volleyball Stats'),
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
                child: Center(
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
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const TeamCreateScreen(),
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
                ),
              ),
            );
          } else if (teams.length == 1) {
            // Single team - auto-select it immediately
            if (kDebugMode) {
              debugPrint('[HomeScreen] Single team found, auto-selecting: ${teams.first.id}');
            }
            // Set the team ID immediately - this will trigger a rebuild
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final currentId = ref.read(selectedTeamIdProvider);
              if (currentId == null) {
                if (kDebugMode) {
                  debugPrint('[HomeScreen] Setting selected team ID to: ${teams.first.id}');
                }
                ref.read(selectedTeamIdProvider.notifier).state = teams.first.id;
              }
            });
            // Show loading while auto-selection happens
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            // Multiple teams - show selection screen
            if (kDebugMode) {
              debugPrint('[HomeScreen] Showing team selection screen (${teams.length} teams)');
            }
            return const TeamSelectionScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) {
          _logger.e('HomeScreen: Error state', error: error, stackTrace: stack);
          return Scaffold(
            appBar: AppBar(title: const Text('Error Loading Teams')),
            body: Container(
              decoration: const BoxDecoration(
                color: AppColors.background,
              ),
              child: Center(
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
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            ref.invalidate(coachTeamsProvider);
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      );
    }
    
    // This should never be reached, but add a fallback just in case
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

