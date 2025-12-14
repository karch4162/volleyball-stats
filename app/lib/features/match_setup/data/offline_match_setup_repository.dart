import 'dart:async';

import '../../../core/utils/logger.dart';
import '../../../core/persistence/hive_service.dart';
import '../../../core/persistence/type_adapters.dart';
import '../models/match_draft.dart';
import '../models/match_player.dart';
import '../models/roster_template.dart';
import '../models/match_status.dart';
import 'match_setup_repository.dart';
import '../../../core/supabase.dart';

final _logger = createLogger('OfflineMatchSetupRepo');

/// Simple repository that works directly with Supabase when online
class OfflineMatchSetupRepository implements MatchSetupRepository {
  OfflineMatchSetupRepository({required this.teamId});

  final String teamId;

  @override
  bool get supportsEntityCreation => getSupabaseClientOrNull() != null;

  @override
  bool get isConnected => getSupabaseClientOrNull() != null;

  @override
  Future<void> saveDraft({
    required String teamId,
    required String matchId,
    required MatchDraft draft,
  }) async {
    // Always save to local storage first (offline-first)
    try {
      final box = HiveService.getBox(HiveService.matchDraftsBox);
      final key = _draftKey(matchId);
      final draftMap = draft.toMap();
      draftMap['match_id'] = matchId;
      draftMap['team_id'] = teamId;
      
      await box.put(key, draftMap);
      _logger.i('Saved draft locally: $matchId');
    } catch (e, st) {
      _logger.e('Failed to save draft locally', error: e, stackTrace: st);
      rethrow;
    }
    
    // Try to sync to Supabase if available (best effort)
    try {
      final client = getSupabaseClientOrNull();
      if (client != null) {
        final matchData = {
          'match_id': matchId,
          'team_id': teamId,
          'opponent': draft.opponent,
          'match_date': draft.matchDate?.toIso8601String(),
          'location': draft.location,
          'season_label': draft.seasonLabel,
          'selected_player_ids': draft.selectedPlayerIds.toList(),
          'starting_rotation': {
            for (final entry in draft.startingRotation.entries)
              entry.key.toString(): entry.value,
          },
        };
        
        await client.from('match_drafts').upsert(matchData);
        _logger.i('Synced draft to Supabase: $matchId');
      }
    } catch (e) {
      // Don't fail if Supabase sync fails - we have it locally
      _logger.w('Failed to sync draft to Supabase', error: e);
    }
  }

  @override
  Future<MatchDraft?> loadDraft({required String matchId}) async {
    // Try local storage first (offline-first)
    try {
      final box = HiveService.getBox(HiveService.matchDraftsBox);
      final key = _draftKey(matchId);
      final draftMap = box.get(key);
      
      if (draftMap != null) {
        _logger.i('Loaded draft from local storage: $matchId');
        return MatchDraft.fromMap(Map<String, dynamic>.from(draftMap));
      }
    } catch (e) {
      _logger.w('Failed to load draft from local storage', error: e);
    }
    
    // Fallback to Supabase if not found locally
    try {
      final client = getSupabaseClientOrNull();
      if (client != null) {
        final response = await client
            .from('match_drafts')
            .select('*')
            .eq('match_id', matchId)
            .maybeSingle();
        
        if (response != null) {
          final draft = MatchDraft.fromMap(response);
          // Cache it locally for future offline access
          await saveDraft(teamId: teamId, matchId: matchId, draft: draft);
          _logger.i('Loaded draft from Supabase and cached: $matchId');
          return draft;
        }
      }
    } catch (e) {
      _logger.w('Failed to load draft from Supabase', error: e);
    }
    
    return null;
  }

  @override
  Future<List<MatchPlayer>> fetchRoster({required String teamId}) async {
    // Try local storage first (offline-first)
    try {
      final box = HiveService.getBox(HiveService.matchPlayersBox);
      final key = _playersKey(teamId);
      final playersMap = box.get(key);
      
      if (playersMap != null && playersMap['players'] is List) {
        final playersList = (playersMap['players'] as List)
            .map((p) => ModelSerializer.matchPlayerFromMap(
                Map<String, dynamic>.from(p as Map)))
            .toList();
        _logger.i('Loaded ${playersList.length} players from local storage');
        return playersList;
      }
    } catch (e) {
      _logger.w('Failed to load players from local storage', error: e);
    }
    
    // Fallback to Supabase if not found locally
    try {
      final client = getSupabaseClientOrNull();
      if (client != null) {
        final response = await client
            .from('players')
            .select('*')
            .eq('team_id', teamId)
            .order('jersey_number');
        
        final players = (response as List).map((map) => MatchPlayer(
          id: map['id'] as String,
          name: '${map['first_name']} ${map['last_name']}',
          jerseyNumber: map['jersey_number'] as int,
          position: map['position'] as String? ?? '',
        )).toList();
        
        // Cache players locally for offline access
        if (players.isNotEmpty) {
          final box = HiveService.getBox(HiveService.matchPlayersBox);
          final key = _playersKey(teamId);
          await box.put(key, {
            'team_id': teamId,
            'players': players.map(ModelSerializer.matchPlayerToMap).toList(),
            'cached_at': DateTime.now().toIso8601String(),
          });
          _logger.i('Cached ${players.length} players from Supabase');
        }
        
        return players;
      }
    } catch (e) {
      _logger.w('Failed to fetch players from Supabase', error: e);
    }
    
    return [];
  }


  Future<void> savePlayer({required MatchPlayer player}) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return;
      }
      
      final nameParts = player.name.split(' ');
      final playerData = {
        'id': player.id,
        'team_id': teamId,
        'jersey_number': player.jerseyNumber,
        'first_name': nameParts.isNotEmpty ? nameParts.first : '',
        'last_name': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
        'position': player.position,
      };
      
      await client.from('players').upsert(playerData);
    } catch (e) {
      _logger.w('Failed to save player to Supabase', error: e);
    }
  }

  Future<void> saveAllPlayers(List<MatchPlayer> players) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return;
      }
      
      final playerData = players.map((player) {
        final nameParts = player.name.split(' ');
        return {
          'id': player.id,
          'team_id': teamId,
          'jersey_number': player.jerseyNumber,
          'first_name': nameParts.isNotEmpty ? nameParts.first : '',
          'last_name': nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '',
          'position': player.position,
        };
      }).toList();
      
      await client.from('players').upsert(playerData);
    } catch (e) {
      _logger.w('Failed to save players to Supabase', error: e);
    }
  }

  Future<void> syncPlayersFromSupabase() async {
    // For now, this would sync players from Supabase to local storage
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return;
      }
      final response = await client
          .from('players')
          .select('*')
          .eq('team_id', teamId);
      
      final players = (response as List).map((map) => _decodePlayer(map as Map<String, dynamic>)).toList();
      
      // TODO: Save to local storage when implementing offline capability
      _logger.i('Synced ${players.length} players from Supabase');
    } catch (e) {
      _logger.w('Failed to sync players from Supabase', error: e);
    }
  }

  Future<void> cleanExpiredData() async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return;
      }
      // Clean up old match drafts older than 30 days
      final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
      
      await client
          .from('match_drafts')
          .delete()
          .lt('created_at', cutoffDate.toIso8601String());
          
    } catch (e) {
      _logger.w('Failed to clean old draft data', error: e);
    }
  }

  @override
  Future<List<RosterTemplate>> loadRosterTemplates({required String teamId}) async {
    // Try local storage first (offline-first)
    try {
      final box = HiveService.getBox(HiveService.rosterTemplatesBox);
      final key = _templatesKey(teamId);
      final templatesMap = box.get(key);
      
      if (templatesMap != null && templatesMap['templates'] is List) {
        final templatesList = (templatesMap['templates'] as List)
            .map((t) => ModelSerializer.rosterTemplateFromMap(
                Map<String, dynamic>.from(t as Map)))
            .toList();
        _logger.i('Loaded ${templatesList.length} templates from local storage');
        return templatesList;
      }
    } catch (e) {
      _logger.w('Failed to load templates from local storage', error: e);
    }
    
    // Fallback to Supabase if not found locally
    try {
      final client = getSupabaseClientOrNull();
      if (client != null) {
        final response = await client
            .from('roster_templates')
            .select('*')
            .eq('team_id', teamId)
            .order('use_count', ascending: false)
            .order('last_used_at', ascending: false)
            .order('name', ascending: true);

        final rows = (response as List).cast<Map<String, dynamic>>();
        final templates = rows.map((row) => RosterTemplate.fromMap(row)).toList();
        
        // Cache templates locally for offline access
        if (templates.isNotEmpty) {
          final box = HiveService.getBox(HiveService.rosterTemplatesBox);
          final key = _templatesKey(teamId);
          await box.put(key, {
            'team_id': teamId,
            'templates': templates.map(ModelSerializer.rosterTemplateToMap).toList(),
            'cached_at': DateTime.now().toIso8601String(),
          });
          _logger.i('Cached ${templates.length} templates from Supabase');
        }
        
        return templates;
      }
    } catch (e) {
      _logger.e('Failed to load roster templates from Supabase', error: e);
    }
    
    return [];
  }

  @override
  Future<void> saveRosterTemplate({
    required String teamId,
    required RosterTemplate template,
  }) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return; // No Supabase available, skip
      }

      final payload = {
        'team_id': teamId,
        ...template.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await client.from('roster_templates').upsert(payload, onConflict: 'id');
    } catch (e) {
      _logger.e('Failed to save roster template', error: e);
    }
  }

  @override
  Future<void> deleteRosterTemplate({
    required String teamId,
    required String templateId,
  }) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return; // No Supabase available, skip
      }

      await client
          .from('roster_templates')
          .delete()
          .eq('id', templateId)
          .eq('team_id', teamId);
    } catch (e) {
      _logger.e('Failed to delete roster template', error: e);
    }
  }

  @override
  Future<void> updateTemplateUsage({
    required String teamId,
    required String templateId,
  }) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return; // No Supabase available, skip
      }

      final template = await client
          .from('roster_templates')
          .select('*')
          .eq('id', templateId)
          .eq('team_id', teamId)
          .maybeSingle();

      if (template != null) {
        final currentTemplate = RosterTemplate.fromMap(template);
        final updated = currentTemplate.markUsed();
        await saveRosterTemplate(teamId: teamId, template: updated);
      }
    } catch (e) {
      _logger.w('Failed to update template usage', error: e);
    }
  }

  @override
  Future<List<dynamic>> fetchMatchSummaries({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    String? opponent,
    String? seasonLabel,
  }) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return [];
      }
      // Delegate to Supabase implementation logic
      // For now, return empty list if offline
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> fetchMatchDetails({
    required String matchId,
  }) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return null;
      }
      return null; // Would implement full query here
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> fetchSeasonStats({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    List<String>? opponentIds,
    String? seasonLabel,
  }) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return {};
      }
      return {}; // Would implement full aggregation here
    } catch (e) {
      return {};
    }
  }

  @override
  Future<Map<String, Map<String, int>>> fetchSetPlayerStats({
    required String matchId,
    required int setNumber,
  }) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return {};
      }
      return {}; // Would implement full query here
    } catch (e) {
      return {};
    }
  }
  
  @override
  Future<void> completeMatch({
    required String matchId,
    required MatchCompletion completion,
  }) async {
    // Save completion status locally first (offline-first)
    try {
      final box = HiveService.getBox(HiveService.matchDraftsBox);
      final key = _completionKey(matchId);
      final completionMap = completion.toMap();
      completionMap['match_id'] = matchId;
      
      await box.put(key, completionMap);
      _logger.i('Saved match completion locally: $matchId');
    } catch (e, st) {
      _logger.e('Failed to save completion locally', error: e, stackTrace: st);
      rethrow;
    }
    
    // Try to sync to Supabase if available (best effort)
    try {
      final client = getSupabaseClientOrNull();
      if (client != null) {
        await client.from('matches').update({
          'status': completion.status.value,
          'completed_at': completion.completedAt.toIso8601String(),
          'final_score_team': completion.finalScoreTeam,
          'final_score_opponent': completion.finalScoreOpponent,
        }).eq('id', matchId);
        
        _logger.i('Synced match completion to Supabase: $matchId');
      }
    } catch (e) {
      // Don't fail if Supabase sync fails - we have it locally
      _logger.w('Failed to sync completion to Supabase', error: e);
    }
  }

  @override
  Future<MatchCompletion?> getMatchCompletion({
    required String matchId,
  }) async {
    // Try local storage first (offline-first)
    try {
      final box = HiveService.getBox(HiveService.matchDraftsBox);
      final key = _completionKey(matchId);
      final completionMap = box.get(key);
      
      if (completionMap != null) {
        _logger.i('Loaded completion from local storage: $matchId');
        return MatchCompletion.fromMap(Map<String, dynamic>.from(completionMap));
      }
    } catch (e) {
      _logger.w('Failed to load completion from local storage', error: e);
    }
    
    // Fallback to Supabase if not found locally
    try {
      final client = getSupabaseClientOrNull();
      if (client != null) {
        final response = await client
            .from('matches')
            .select('status, completed_at, final_score_team, final_score_opponent')
            .eq('id', matchId)
            .maybeSingle();
        
        if (response != null && response['status'] != null) {
          final completion = MatchCompletion.fromMap(response);
          // Cache it locally for future offline access
          await completeMatch(matchId: matchId, completion: completion);
          _logger.i('Loaded completion from Supabase and cached: $matchId');
          return completion;
        }
      }
    } catch (e) {
      _logger.w('Failed to load completion from Supabase', error: e);
    }
    
    return null;
  }

  // Helper methods for key generation
  String _draftKey(String matchId) => 'draft_$matchId';
  String _playersKey(String teamId) => 'players_$teamId';
  String _templateKey(String templateId) => 'template_$templateId';
  String _templatesKey(String teamId) => 'templates_$teamId';
  String _completionKey(String matchId) => 'completion_$matchId';
}

MatchPlayer _decodePlayer(Map<String, dynamic> map) {
  return MatchPlayer(
    id: map['id'] as String,
    name: '${map['first_name']} ${map['last_name']}',
    jerseyNumber: map['jersey_number'] as int,
    position: map['position'] as String? ?? '',
  );
}
