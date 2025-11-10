import '../models/match_draft.dart';
import '../models/match_player.dart';
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
}

