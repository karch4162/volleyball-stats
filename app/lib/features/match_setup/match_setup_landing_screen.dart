import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
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
    final templatesAsync = ref.watch(rosterTemplatesDefaultProvider);
    final lastDraftAsync = ref.watch(lastMatchDraftProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Start New Match'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.star_rounded),
            tooltip: 'Manage Templates',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const TemplateListScreen(),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
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
      final actions = ref.read(templateActionsProvider);
      await actions.useTemplate(
        teamId: defaultTeamId,
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


