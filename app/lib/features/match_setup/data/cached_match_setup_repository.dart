import '../models/match_draft.dart';
import '../models/match_player.dart';
import '../models/roster_template.dart';
import 'match_draft_cache.dart';
import 'match_setup_repository.dart';

class CachedMatchSetupRepository implements MatchSetupRepository {
  CachedMatchSetupRepository({
    required MatchSetupRepository primary,
    required MatchDraftCache cache,
    required String teamId,
  })  : _primary = primary,
        _cache = cache,
        _teamId = teamId;

  final MatchSetupRepository _primary;
  final MatchDraftCache _cache;
  final String _teamId;

  @override
  Future<List<MatchPlayer>> fetchRoster({required String teamId}) {
    final id = teamId.isEmpty ? _teamId : teamId;
    return _primary.fetchRoster(teamId: id);
  }

  @override
  Future<MatchDraft?> loadDraft({required String matchId}) async {
    final cached = await _cache.load(matchId);
    if (cached != null) {
      return cached;
    }

    final remote = await _primary.loadDraft(matchId: matchId);
    if (remote != null) {
      await _cache.save(matchId, remote);
    }
    return remote;
  }

  @override
  Future<void> saveDraft({
    required String teamId,
    required String matchId,
    required MatchDraft draft,
  }) async {
    await _cache.save(matchId, draft);
    final id = teamId.isEmpty ? _teamId : teamId;
    await _primary.saveDraft(teamId: id, matchId: matchId, draft: draft);
  }

  @override
  Future<List<RosterTemplate>> loadRosterTemplates({required String teamId}) {
    final id = teamId.isEmpty ? _teamId : teamId;
    return _primary.loadRosterTemplates(teamId: id);
  }

  @override
  Future<void> saveRosterTemplate({
    required String teamId,
    required RosterTemplate template,
  }) {
    final id = teamId.isEmpty ? _teamId : teamId;
    return _primary.saveRosterTemplate(teamId: id, template: template);
  }

  @override
  Future<void> deleteRosterTemplate({
    required String teamId,
    required String templateId,
  }) {
    final id = teamId.isEmpty ? _teamId : teamId;
    return _primary.deleteRosterTemplate(teamId: id, templateId: templateId);
  }

  @override
  Future<void> updateTemplateUsage({
    required String teamId,
    required String templateId,
  }) {
    final id = teamId.isEmpty ? _teamId : teamId;
    return _primary.updateTemplateUsage(teamId: id, templateId: templateId);
  }
}

