import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_draft.dart';
import '../models/match_player.dart';
import 'match_setup_repository.dart';

class SupabaseMatchSetupRepository implements MatchSetupRepository {
  SupabaseMatchSetupRepository(this._client, {required String teamId})
      : _defaultTeamId = teamId;

  final SupabaseClient _client;
  final String _defaultTeamId;

  @override
  Future<List<MatchPlayer>> fetchRoster({required String teamId}) async {
    final effectiveTeamId = teamId.isEmpty ? _defaultTeamId : teamId;
    final result = await _client
        .from('players')
        .select()
        .eq('team_id', effectiveTeamId)
        .order('jersey_number', ascending: true);

    final rows = (result as List<dynamic>)
        .cast<Map<String, dynamic>>();

    return rows.map(MatchPlayer.fromMap).toList();
  }

  @override
  Future<MatchDraft?> loadDraft({required String matchId}) async {
    final response = await _client
        .from('match_drafts')
        .select()
        .eq('match_id', matchId)
        .limit(1)
        .maybeSingle();

    if (response == null) {
      return null;
    }

    return MatchDraft.fromMap(response as Map<String, dynamic>);
  }

  @override
  Future<void> saveDraft({
    required String teamId,
    required String matchId,
    required MatchDraft draft,
  }) async {
    final effectiveTeamId = teamId.isEmpty ? _defaultTeamId : teamId;
    final payload = {
      'team_id': effectiveTeamId,
      'match_id': matchId,
      ...draft.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('match_drafts').upsert(payload, onConflict: 'match_id');
  }
}

