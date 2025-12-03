import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/cache_status_indicator.dart';
import '../../core/widgets/glass_container.dart';
import '../history/match_history_screen.dart';
import '../history/season_dashboard_screen.dart';
import '../players/player_list_screen.dart';
import '../teams/team_providers.dart';
import '../teams/team_list_screen.dart';
import '../teams/models/team.dart';
import 'match_setup_flow.dart';
import 'models/match_draft.dart';
import 'models/roster_template.dart';
import 'providers.dart';
import 'template_list_screen.dart';
import 'constants.dart';

class MatchSetupLandingScreen extends ConsumerStatefulWidget {
  const MatchSetupLandingScreen({super.key});

  @override
  ConsumerState<MatchSetupLandingScreen> createState() => _MatchSetupLandingScreenState();
}

class _MatchSetupLandingScreenState extends ConsumerState<MatchSetupLandingScreen> {
  bool _hasForcedRebuild = false;

  @override
  void initState() {
    super.initState();
    // Force a rebuild after first frame to ensure rendering
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasForcedRebuild && mounted) {
        _hasForcedRebuild = true;
        if (kDebugMode) {
          debugPrint('[MatchSetupLandingScreen] Forcing rebuild after first frame');
        }
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    try {
      final selectedTeamId = ref.watch(selectedTeamIdProvider);
      final selectedTeam = ref.watch(selectedTeamProvider);
      final teamsAsync = ref.watch(coachTeamsProvider);
      final templatesAsync = ref.watch(rosterTemplatesDefaultProvider);
      final lastDraftAsync = ref.watch(lastMatchDraftProvider);

      // Debug logging
      if (kDebugMode) {
        debugPrint('[MatchSetupLandingScreen] Building...');
        debugPrint('[MatchSetupLandingScreen] Selected team ID: ${selectedTeamId ?? "null"}');
        debugPrint('[MatchSetupLandingScreen] Selected team: ${selectedTeam?.name ?? "null"}');
        debugPrint('[MatchSetupLandingScreen] Teams async state: loading=${teamsAsync.isLoading}, hasValue=${teamsAsync.hasValue}, hasError=${teamsAsync.hasError}');
      }

      // Wait for team to be selected before showing content
      // This prevents blank screen when auto-selection is in progress
      if (selectedTeamId == null) {
        if (kDebugMode) {
          debugPrint('[MatchSetupLandingScreen] No team selected yet, showing loading...');
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Start New Match'),
            backgroundColor: Colors.transparent,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Debug logging
      if (kDebugMode) {
        debugPrint('[MatchSetupLandingScreen] Teams loaded, rendering content...');
        debugPrint('[MatchSetupLandingScreen] Templates async state: loading=${templatesAsync.isLoading}, hasValue=${templatesAsync.hasValue}, hasError=${templatesAsync.hasError}');
        if (templatesAsync.hasError) {
          debugPrint('[MatchSetupLandingScreen] Templates error: ${templatesAsync.error}');
          debugPrint('[MatchSetupLandingScreen] Templates stack: ${templatesAsync.stackTrace}');
        }
        if (lastDraftAsync.hasError) {
          debugPrint('[MatchSetupLandingScreen] Last draft error: ${lastDraftAsync.error}');
        }
        debugPrint('[MatchSetupLandingScreen] About to return Scaffold...');
      }

      // Always build the Scaffold structure - don't wait for teams
      // This ensures the screen renders immediately
      if (kDebugMode) {
        debugPrint('[MatchSetupLandingScreen] Building Scaffold (teams hasValue: ${teamsAsync.hasValue})');
      }

      if (!teamsAsync.hasValue) {
        if (kDebugMode) {
          debugPrint('[MatchSetupLandingScreen] Teams not loaded yet, showing loading');
        }
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Start New Match'),
            backgroundColor: Colors.transparent,
          ),
          body: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      if (teamsAsync.hasError) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Start New Match'),
            backgroundColor: Colors.transparent,
          ),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Error Loading Teams',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    teamsAsync.error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 14,
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
        );
      }

      // Teams are loaded, build the full Scaffold
      // Use a key to ensure proper rendering
      final scaffold = Scaffold(
        key: ValueKey('match_setup_landing_${selectedTeamId}_${teamsAsync.hasValue}'),
        backgroundColor: AppColors.background,
            appBar: AppBar(
              title: const Text('Start New Match'),
              backgroundColor: Colors.transparent,
              actions: [
                PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              switch (value) {
                case 'teams':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TeamListScreen(),
                    ),
                  );
                  break;
                case 'players':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PlayerListScreen(),
                    ),
                  );
                  break;
                case 'templates':
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TemplateListScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'teams',
                child: Row(
                  children: [
                    Icon(Icons.group, size: 20),
                    SizedBox(width: 8),
                    Text('Manage Teams'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'players',
                child: Row(
                  children: [
                    Icon(Icons.people, size: 20),
                    SizedBox(width: 8),
                    Text('Manage Players'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'templates',
                child: Row(
                  children: [
                    Icon(Icons.star_rounded, size: 20),
                    SizedBox(width: 8),
                    Text('Manage Templates'),
                  ],
                ),
              ),
                ],
              ),
            ],
          ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            // Cache status indicator
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CacheStatusIndicator(),
            ),
            // Team selector header (teamsAsync is already loaded at this point)
            if (teamsAsync.hasValue && teamsAsync.value!.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TeamSelectorHeader(
                  selectedTeam: selectedTeam,
                  teams: teamsAsync.value!,
                  onTeamSelected: (teamId) {
                    ref.read(selectedTeamIdProvider.notifier).state = teamId;
                    // Refresh templates for the new team
                    ref.invalidate(rosterTemplatesDefaultProvider);
                  },
                ),
              ),
            const Text(
              'Quick Start',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Use Last Match Option
            lastDraftAsync.when(
              data: (draft) {
                if (draft == null) {
                  return const SizedBox.shrink();
                }
                final matchDraft = draft as MatchDraft;
                return _QuickStartCard(
                  icon: Icons.history_rounded,
                  title: 'Use Last Match Setup',
                  subtitle: _getLastMatchSubtitle(context, matchDraft),
                  onTap: () => _navigateToSetup(context, ref, lastDraft: matchDraft),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (error, stackTrace) {
                if (kDebugMode) {
                  debugPrint('[MatchSetupLandingScreen] Error loading last draft: $error');
                  debugPrint('[MatchSetupLandingScreen] Stack: $stackTrace');
                }
                return const SizedBox.shrink(); // Don't show error in UI, just log it
              },
            ),

            // Use Template Option
            templatesAsync.when(
              data: (templates) {
                if (templates.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: _QuickStartCard(
                    icon: Icons.star_rounded,
                    title: 'Use Template',
                    subtitle: '${templates.length} template${templates.length == 1 ? '' : 's'} available',
                    onTap: () => _showTemplatePicker(context, ref, templates),
                  ),
                );
              },
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 12),
                child: _QuickStartCard(
                  icon: Icons.star_rounded,
                  title: 'Use Template',
                  subtitle: 'Loading...',
                  onTap: null,
                ),
              ),
              error: (error, stackTrace) {
                if (kDebugMode) {
                  debugPrint('[MatchSetupLandingScreen] Error loading templates: $error');
                  debugPrint('[MatchSetupLandingScreen] Stack: $stackTrace');
                }
                // Show error message to user instead of hiding it
                return Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Error loading templates: ${error.toString()}',
                            style: const TextStyle(color: Colors.red, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Start Fresh Option
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _QuickStartCard(
                icon: Icons.edit_rounded,
                title: 'Start Fresh',
                subtitle: 'Build from scratch',
                onTap: () => _navigateToSetup(context, ref),
              ),
            ),

            const SizedBox(height: 32),
            const Text(
              'History & Analytics',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),

            // Match History Option
            _QuickStartCard(
              icon: Icons.history_rounded,
              title: 'Match History',
              subtitle: 'View past matches and statistics',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MatchHistoryScreen(),
                ),
              ),
            ),

            // Season Dashboard Option
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: _QuickStartCard(
                icon: Icons.analytics_rounded,
                title: 'Season Dashboard',
                subtitle: 'View season statistics and trends',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const SeasonDashboardScreen(),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
            ],
          ),
        ),
      );
          
      if (kDebugMode) {
        debugPrint('[MatchSetupLandingScreen] Scaffold built successfully');
      }
          
      return scaffold;
    } catch (e, stackTrace) {
      if (kDebugMode) {
        debugPrint('[MatchSetupLandingScreen] ERROR in build: $e');
        debugPrint('[MatchSetupLandingScreen] Stack trace: $stackTrace');
      }
      // Always show error screen, never return blank
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Start New Match'),
          backgroundColor: Colors.transparent,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Error Loading Screen',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  e.toString(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Text(
                    stackTrace.toString(),
                    style: const TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
  }

  String _getLastMatchSubtitle(BuildContext context, MatchDraft draft) {
    final parts = <String>[];
    if (draft.opponent.isNotEmpty) {
      parts.add('vs ${draft.opponent}');
    }
    if (draft.matchDate != null) {
      // Format date using MaterialLocalizations
      final dateStr = MaterialLocalizations.of(context).formatShortMonthDay(draft.matchDate!);
      parts.add(dateStr);
    }
    if (draft.selectedPlayerIds.isNotEmpty) {
      parts.add('${draft.selectedPlayerIds.length} players');
    }
    if (draft.hasRotation) {
      parts.add('Rotation set');
    }
    return parts.isEmpty ? 'Previous match' : parts.join(' • ');
  }

  void _navigateToSetup(
    BuildContext context,
    WidgetRef ref, {
    MatchDraft? lastDraft,
    RosterTemplate? template,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MatchSetupFlow(
          lastDraft: lastDraft,
          template: template,
        ),
      ),
    );
  }

  Future<void> _showTemplatePicker(
    BuildContext context,
    WidgetRef ref,
    List<RosterTemplate> templates,
  ) async {
    final selected = await showModalBottomSheet<RosterTemplate>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
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
                          trailing: template.lastUsedAt != null
                          ? Text(
                              'Used ${_formatLastUsed(context, template.lastUsedAt!)}',
                              style: const TextStyle(
                                color: AppColors.textDisabled,
                                fontSize: 12,
                              ),
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop(template);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null && context.mounted) {
      // Mark template as used
      final selectedTeamId = ref.read(selectedTeamIdProvider);
      final effectiveTeamId = selectedTeamId ?? defaultTeamId;
      
      final actions = ref.read(templateActionsProvider);
      await actions.useTemplate(
        teamId: effectiveTeamId,
        templateId: selected.id,
      );

      _navigateToSetup(context, ref, template: selected);
    }
  }

  String _formatLastUsed(BuildContext context, DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'today';
    } else if (diff.inDays == 1) {
      return 'yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}d ago';
    } else if (diff.inDays < 30) {
      return '${(diff.inDays / 7).floor()}w ago';
    } else {
      return MaterialLocalizations.of(context).formatShortMonthDay(date);
    }
  }
}

class _QuickStartCard extends StatelessWidget {
  const _QuickStartCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GlassLightContainer(
      padding: const EdgeInsets.all(16),
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.indigoDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.indigo,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }
}

class _TeamSelectorHeader extends StatelessWidget {
  const _TeamSelectorHeader({
    required this.selectedTeam,
    required this.teams,
    required this.onTeamSelected,
  });

  final Team? selectedTeam;
  final List<Team> teams;
  final ValueChanged<String> onTeamSelected;

  @override
  Widget build(BuildContext context) {
    return GlassLightContainer(
      padding: const EdgeInsets.all(12),
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showTeamPicker(context),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.indigoDark.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.sports_volleyball,
              color: AppColors.indigo,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Team',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  selectedTeam?.name ?? 'No team selected',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (selectedTeam != null &&
                    (selectedTeam!.level != null ||
                        selectedTeam!.seasonLabel != null)) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (selectedTeam!.level != null) selectedTeam!.level,
                      if (selectedTeam!.seasonLabel != null)
                        selectedTeam!.seasonLabel,
                    ].join(' • '),
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.arrow_drop_down_rounded,
            color: AppColors.textMuted,
          ),
        ],
      ),
    );
  }

  Future<void> _showTeamPicker(BuildContext context) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
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
                      'Select Team',
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
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: teams.length,
                  itemBuilder: (context, index) {
                    final team = teams[index];
                    final isSelected = team.id == selectedTeam?.id;

                    return ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.indigoDark.withOpacity(0.2)
                              : AppColors.glassLight,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.sports_volleyball,
                          color: isSelected
                              ? AppColors.indigo
                              : AppColors.textMuted,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        team.name,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      subtitle: (team.level != null ||
                              team.seasonLabel != null)
                          ? Text(
                              [
                                if (team.level != null) team.level,
                                if (team.seasonLabel != null) team.seasonLabel,
                              ].join(' • '),
                              style: const TextStyle(color: AppColors.textMuted),
                            )
                          : null,
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: AppColors.indigo,
                            )
                          : null,
                      onTap: () {
                        Navigator.of(context).pop(team.id);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (selected != null) {
      onTeamSelected(selected);
    }
  }
}


