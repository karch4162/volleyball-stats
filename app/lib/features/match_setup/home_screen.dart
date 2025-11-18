import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../auth/auth_provider.dart';
import '../auth/auth_service.dart';
import '../teams/team_create_screen.dart';
import '../teams/team_providers.dart';
import '../teams/team_selection_screen.dart';
import 'match_setup_landing_screen.dart';
import 'providers.dart';

/// Home screen that shows team selection or match setup landing
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auto-select provider to ensure single team is auto-selected
    ref.watch(autoSelectTeamProvider);
    
    // Trigger cache sync when authenticated (runs in background)
    ref.watch(cacheSyncProvider);
    
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    final teamsAsync = ref.watch(coachTeamsProvider);
    final currentUser = ref.watch(currentUserProvider);

    // Debug logging
    if (teamsAsync.hasValue) {
      print('HomeScreen: Teams loaded: ${teamsAsync.value?.length ?? 0}');
    }
    if (teamsAsync.hasError) {
      print('HomeScreen: Error loading teams: ${teamsAsync.error}');
      print('HomeScreen: Stack trace: ${teamsAsync.stackTrace}');
    }

    // If no team is selected, show team selection
    if (selectedTeamId == null) {
      return teamsAsync.when(
        data: (teams) {
          print('HomeScreen: Teams data received: ${teams.length} teams');
          if (teams.isEmpty) {
            // No teams - show empty state with create option
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
                        PopupMenuItem(
                          value: 'logout',
                          child: Row(
                            children: [
                              const Icon(Icons.logout, size: 20),
                              const SizedBox(width: 8),
                              const Text('Sign Out'),
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
                          Icon(
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
            // Only one team - auto-select it
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(selectedTeamIdProvider.notifier).state = teams.first.id;
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            // Multiple teams - show selection screen
            return const TeamSelectionScreen();
          }
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) {
          print('HomeScreen: Error state - $error');
          print('HomeScreen: Stack trace - $stack');
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

    // Team selected - show match setup landing
    return const MatchSetupLandingScreen();
  }
}

