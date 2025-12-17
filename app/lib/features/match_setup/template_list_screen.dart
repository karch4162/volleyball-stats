import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/glass_container.dart';
import '../teams/team_providers.dart';
import 'models/roster_template.dart';
import 'providers.dart';
import 'template_edit_screen.dart';
import 'constants.dart';

class TemplateListScreen extends ConsumerWidget {
  const TemplateListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = ref.watch(rosterTemplatesDefaultProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Roster Templates'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            tooltip: 'Create Template',
            onPressed: () => _navigateToCreate(context),
          ),
        ],
      ),
      body: templatesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.indigo),
        ),
        error: (error, stackTrace) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Failed to load templates',
                style: TextStyle(color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.refresh(rosterTemplatesDefaultProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (templates) {
          if (templates.isEmpty) {
            return _EmptyState(onCreate: () => _navigateToCreate(context));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...templates.map((template) => _TemplateCard(
                    template: template,
                    onTap: () => _navigateToEdit(context, template),
                    onDelete: () => _confirmDelete(context, ref, template),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _navigateToCreate(BuildContext context) {
    context.push('/templates/create');
  }

  void _navigateToEdit(BuildContext context, RosterTemplate template) {
    context.push('/templates/${template.id}/edit', extra: template);
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    RosterTemplate template,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Template'),
        content: Text('Are you sure you want to delete "${template.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.rose,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final selectedTeamId = ref.read(selectedTeamIdProvider);
      final effectiveTeamId = selectedTeamId ?? defaultTeamId;
      
      final actions = ref.read(templateActionsProvider);
      await actions.deleteTemplate(
        teamId: effectiveTeamId,
        templateId: template.id,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Template "${template.name}" deleted'),
            backgroundColor: AppColors.glass,
          ),
        );
      }
    }
  }
}

class _TemplateCard extends StatelessWidget {
  const _TemplateCard({
    required this.template,
    required this.onTap,
    required this.onDelete,
  });

  final RosterTemplate template;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassLightContainer(
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
              child: const Icon(
                Icons.star_rounded,
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
                    template.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (template.description != null && template.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      template.description!,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 4,
                    children: [
                      _InfoChip(
                        icon: Icons.people_rounded,
                        label: '${template.playerIds.length} players',
                      ),
                      if (template.defaultRotation.isNotEmpty)
                        const _InfoChip(
                          icon: Icons.swap_horiz_rounded,
                          label: 'Rotation set',
                        ),
                      if (template.useCount > 0)
                        _InfoChip(
                          icon: Icons.history_rounded,
                          label: 'Used ${template.useCount}x',
                        ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColors.textMuted,
              tooltip: 'Delete template',
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textMuted,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.indigoDark.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(
                Icons.star_outline_rounded,
                color: AppColors.indigo,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Templates Yet',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a template to quickly reuse your roster and rotation',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Template'),
            ),
          ],
        ),
      ),
    );
  }
}

