import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/cache_status_indicator.dart';
import '../../core/widgets/glass_container.dart';
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

class MatchSetupLandingScreen extends ConsumerWidget {
  const MatchSetupLandingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch auto-select provider to ensure single team is auto-selected
    ref.watch(autoSelectTeamProvider);
    
    final templatesAsync = ref.watch(rosterTemplatesDefaultProvider);
    final lastDraftAsync = ref.watch(lastMatchDraftProvider);
    final selectedTeam = ref.watch(selectedTeamProvider);
    final teamsAsync = ref.watch(coachTeamsProvider);

    return Scaffold(
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
            const SizedBox(height: 8),
            // Cache status indicator
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: CacheStatusIndicator(),
            ),
            // Team selector header
            teamsAsync.when(
              data: (teams) {
                if (teams.length <= 1) {
                  // Only one team or no teams - don't show switcher
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _TeamSelectorHeader(
                    selectedTeam: selectedTeam,
                    teams: teams,
                    onTeamSelected: (teamId) {
                      ref.read(selectedTeamIdProvider.notifier).state = teamId;
                      // Refresh templates for the new team
                      ref.invalidate(rosterTemplatesDefaultProvider);
                    },
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
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
              error: (_, __) => const SizedBox.shrink(),
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
              error: (_, __) => const SizedBox.shrink(),
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
          ],
        ),
      ),
    );
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


