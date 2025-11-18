import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/providers/supabase_client_provider.dart';
import 'data/data.dart';
import 'models/match_draft.dart';
import 'models/match_player.dart';
import 'models/roster_template.dart';
import 'constants.dart';

final matchDraftCacheProvider = Provider<MatchDraftCache>((ref) {
  return InMemoryMatchDraftCache();
});

final matchSetupRepositoryProvider = Provider<MatchSetupRepository>((ref) {
  final cache = ref.watch(matchDraftCacheProvider);
  final client = ref.watch(supabaseClientProvider);
  final baseRepository = client != null
      ? SupabaseMatchSetupRepository(client, teamId: defaultTeamId)
      : InMemoryMatchSetupRepository();

  return CachedMatchSetupRepository(
    primary: baseRepository,
    cache: cache,
    teamId: defaultTeamId,
  );
});

// Roster Template Providers
final rosterTemplatesProvider = FutureProvider.family<List<RosterTemplate>, String>((ref, teamId) async {
  final repository = ref.watch(matchSetupRepositoryProvider);
  return await repository.loadRosterTemplates(teamId: teamId);
});

final rosterTemplatesDefaultProvider = FutureProvider<List<RosterTemplate>>((ref) {
  final repository = ref.watch(matchSetupRepositoryProvider);
  return repository.loadRosterTemplates(teamId: defaultTeamId);
});

// Template actions provider (for mutations)
final templateActionsProvider = Provider<TemplateActions>((ref) {
  final repository = ref.watch(matchSetupRepositoryProvider);
  return TemplateActions(repository: repository, ref: ref);
});

class TemplateActions {
  TemplateActions({required this.repository, required this.ref});

  final MatchSetupRepository repository;
  final Ref ref;

  Future<void> saveTemplate({
    required String teamId,
    required String name,
    String? description,
    required Set<String> playerIds,
    Map<int, String>? defaultRotation,
  }) async {
    final template = RosterTemplate(
      id: const Uuid().v4(),
      name: name,
      description: description,
      playerIds: playerIds,
      defaultRotation: defaultRotation ?? const {},
      createdAt: DateTime.now(),
    );

    await repository.saveRosterTemplate(teamId: teamId, template: template);
    ref.invalidate(rosterTemplatesDefaultProvider);
  }

  Future<void> deleteTemplate({
    required String teamId,
    required String templateId,
  }) async {
    await repository.deleteRosterTemplate(teamId: teamId, templateId: templateId);
    ref.invalidate(rosterTemplatesDefaultProvider);
  }

  Future<void> useTemplate({
    required String teamId,
    required String templateId,
  }) async {
    await repository.updateTemplateUsage(teamId: teamId, templateId: templateId);
    ref.invalidate(rosterTemplatesDefaultProvider);
  }
}

final matchSetupRosterProvider =
    FutureProvider.autoDispose<List<MatchPlayer>>((ref) async {
  final repository = ref.watch(matchSetupRepositoryProvider);
  return repository.fetchRoster(teamId: defaultTeamId);
});

// Provider for last match draft
final lastMatchDraftProvider = FutureProvider<MatchDraft?>((ref) async {
  final repository = ref.watch(matchSetupRepositoryProvider);
  // For now, try loading the default draft ID
  // In a real implementation, you'd query for the most recent draft
  try {
    return await repository.loadDraft(matchId: defaultMatchDraftId);
  } catch (_) {
    return null;
  }
});

