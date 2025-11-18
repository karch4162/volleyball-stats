import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/match_draft.dart';
import '../models/match_player.dart';
import '../models/roster_template.dart';
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

  @override
  Future<List<RosterTemplate>> loadRosterTemplates({required String teamId}) async {
    final effectiveTeamId = teamId.isEmpty ? _defaultTeamId : teamId;
    final result = await _client
        .from('roster_templates')
        .select()
        .eq('team_id', effectiveTeamId)
        .order('use_count', ascending: false)
        .order('last_used_at', ascending: false)
        .order('name', ascending: true);

    final rows = (result as List<dynamic>).cast<Map<String, dynamic>>();
    return rows.map((row) => RosterTemplate.fromMap(row)).toList();
  }

  @override
  Future<void> saveRosterTemplate({
    required String teamId,
    required RosterTemplate template,
  }) async {
    final effectiveTeamId = teamId.isEmpty ? _defaultTeamId : teamId;
    final payload = {
      'team_id': effectiveTeamId,
      ...template.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    await _client.from('roster_templates').upsert(payload, onConflict: 'id');
  }

  @override
  Future<void> deleteRosterTemplate({
    required String teamId,
    required String templateId,
  }) async {
    final effectiveTeamId = teamId.isEmpty ? _defaultTeamId : teamId;
    await _client
        .from('roster_templates')
        .delete()
        .eq('id', templateId)
        .eq('team_id', effectiveTeamId);
  }

  @override
  Future<void> updateTemplateUsage({
    required String teamId,
    required String templateId,
  }) async {
    final effectiveTeamId = teamId.isEmpty ? _defaultTeamId : teamId;
    final template = await _client
        .from('roster_templates')
        .select()
        .eq('id', templateId)
        .eq('team_id', effectiveTeamId)
        .maybeSingle();

    if (template != null) {
      final currentTemplate = RosterTemplate.fromMap(template as Map<String, dynamic>);
      final updated = currentTemplate.markUsed();
      await saveRosterTemplate(teamId: effectiveTeamId, template: updated);
    }
  }
}

