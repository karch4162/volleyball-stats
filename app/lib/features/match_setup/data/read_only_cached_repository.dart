import '../../../core/cache/offline_cache_service.dart';
import '../../../core/errors/repository_errors.dart';
import '../models/match_draft.dart';
import '../models/match_player.dart';
import '../models/roster_template.dart';
import '../models/match_status.dart';
import 'match_draft_cache.dart';
import 'match_setup_repository.dart';

/// Read-only repository that only reads from cache
/// Used when Supabase is not connected - allows viewing cached data but prevents creation/modification
class ReadOnlyCachedRepository implements MatchSetupRepository {
  ReadOnlyCachedRepository({
    required OfflineCacheService cache,
    required MatchDraftCache draftCache,
    required String teamId,
  })  : _cache = cache,
        _draftCache = draftCache,
        _teamId = teamId;

  final OfflineCacheService _cache;
  final MatchDraftCache _draftCache;
  final String _teamId;

  @override
  bool get supportsEntityCreation => false; // Never allow creation when offline

  @override
  bool get isConnected => false; // Not connected to Supabase

  @override
  Future<List<MatchPlayer>> fetchRoster({required String teamId}) async {
    final effectiveTeamId = teamId.isEmpty ? _teamId : teamId;
    final cached = _cache.getCachedPlayers(effectiveTeamId);
    
    // Return cached players or empty list if cache is empty
    return cached ?? [];
  }

  @override
  Future<MatchDraft?> loadDraft({required String matchId}) async {
    // Load from draft cache (this is separate from offline cache)
    return await _draftCache.load(matchId);
  }

  @override
  Future<void> saveDraft({
    required String teamId,
    required String matchId,
    required MatchDraft draft,
  }) async {
    // Save to local draft cache only (for auto-save functionality)
    // This allows draft editing to work offline, but won't sync until online
    await _draftCache.save(matchId, draft);
    
    // Don't throw exception for draft saves - allow local-only saves
    // The draft will sync when connection is restored
  }

  @override
  Future<List<RosterTemplate>> loadRosterTemplates({required String teamId}) async {
    final effectiveTeamId = teamId.isEmpty ? _teamId : teamId;
    final cached = _cache.getCachedTemplates(effectiveTeamId);
    
    // Return cached templates or empty list if cache is empty
    return cached ?? [];
  }

  @override
  Future<void> saveRosterTemplate({
    required String teamId,
    required RosterTemplate template,
  }) async {
    throw const OfflineEntityCreationException(
      'Cannot create or modify templates while offline. Please connect to Supabase.',
    );
  }

  @override
  Future<void> deleteRosterTemplate({
    required String teamId,
    required String templateId,
  }) async {
    throw const OfflineEntityCreationException(
      'Cannot delete templates while offline. Please connect to Supabase.',
    );
  }

  @override
  Future<void> updateTemplateUsage({
    required String teamId,
    required String templateId,
  }) async {
    // Template usage updates are non-critical, so we can skip them when offline
    // This allows viewing templates offline without errors
  }

  @override
  Future<List<dynamic>> fetchMatchSummaries({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    String? opponent,
    String? seasonLabel,
  }) async {
    // Return empty list when offline - history requires Supabase connection
    return [];
  }

  @override
  Future<Map<String, dynamic>?> fetchMatchDetails({
    required String matchId,
  }) async {
    // Return null when offline - history requires Supabase connection
    return null;
  }

  @override
  Future<Map<String, dynamic>> fetchSeasonStats({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? opponentIds,
    String? seasonLabel,
  }) async {
    // Return empty map when offline - history requires Supabase connection
    return {};
  }

  @override
  Future<Map<String, Map<String, int>>> fetchSetPlayerStats({
    required String matchId,
    required int setNumber,
  }) async {
    // Return empty map when offline - history requires Supabase connection
    return {};
  }

  @override
  Future<void> completeMatch({
    required String matchId,
    required MatchCompletion completion,
  }) async {
    // Read-only repository cannot complete matches
    throw Exception('Cannot complete match while offline');
  }

  @override
  Future<MatchCompletion?> getMatchCompletion({
    required String matchId,
  }) async {
    // Return null - no completion data available offline
    return null;
  }
}

