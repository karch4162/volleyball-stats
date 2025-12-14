import 'package:flutter/foundation.dart';

import '../models/match_draft.dart';
import '../models/match_player.dart';
import '../models/roster_template.dart';
import '../models/match_status.dart';
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
  bool get supportsEntityCreation => _primary.supportsEntityCreation;

  @override
  bool get isConnected => _primary.isConnected;

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
    // Always save to cache first (local persistence)
    await _cache.save(matchId, draft);
    
    // Then try to save to primary repository (Supabase or in-memory)
    final id = teamId.isEmpty ? _teamId : teamId;
    try {
      await _primary.saveDraft(teamId: id, matchId: matchId, draft: draft);
    } catch (error, stackTrace) {
      // Log error but don't fail - local cache already saved
      debugPrint('Failed to save draft to primary repository: $error\n$stackTrace');
      rethrow; // Re-throw so caller can handle it
    }
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
  }) async {
    final id = teamId.isEmpty ? _teamId : teamId;
    try {
      await _primary.saveRosterTemplate(teamId: id, template: template);
    } catch (error, stackTrace) {
      debugPrint('Failed to save template to primary repository: $error\n$stackTrace');
      rethrow; // Re-throw so caller can handle it
    }
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

  @override
  Future<List<dynamic>> fetchMatchSummaries({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    String? opponent,
    String? seasonLabel,
  }) {
    final id = teamId.isEmpty ? _teamId : teamId;
    return _primary.fetchMatchSummaries(
      teamId: id,
      startDate: startDate,
      endDate: endDate,
      opponent: opponent,
      seasonLabel: seasonLabel,
    );
  }

  @override
  Future<Map<String, dynamic>?> fetchMatchDetails({
    required String matchId,
  }) {
    return _primary.fetchMatchDetails(matchId: matchId);
  }

  @override
  Future<Map<String, dynamic>> fetchSeasonStats({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? opponentIds,
    String? seasonLabel,
  }) {
    final id = teamId.isEmpty ? _teamId : teamId;
    return _primary.fetchSeasonStats(
      teamId: id,
      startDate: startDate,
      endDate: endDate,
      opponentIds: opponentIds,
      seasonLabel: seasonLabel,
    );
  }

  @override
  Future<Map<String, Map<String, int>>> fetchSetPlayerStats({
    required String matchId,
    required int setNumber,
  }) {
    return _primary.fetchSetPlayerStats(
      matchId: matchId,
      setNumber: setNumber,
    );
  }

  @override
  Future<void> completeMatch({
    required String matchId,
    required MatchCompletion completion,
  }) {
    return _primary.completeMatch(matchId: matchId, completion: completion);
  }

  @override
  Future<MatchCompletion?> getMatchCompletion({
    required String matchId,
  }) {
    return _primary.getMatchCompletion(matchId: matchId);
  }
}

