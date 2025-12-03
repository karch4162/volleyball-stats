import 'dart:async';

import '../models/match_draft.dart';
import '../models/match_player.dart';
import '../models/roster_template.dart';
import 'match_setup_repository.dart';
import '../../../core/supabase.dart';

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
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return; // No Supabase available, skip
      }
      
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
      
    } catch (e) {
      // Save locally if Supabase fails
      print('Failed to save to Supabase: $e');
    }
  }

  @override
  Future<MatchDraft?> loadDraft({required String matchId}) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return null;
      }
      
      final response = await client
          .from('match_drafts')
          .select('*')
          .eq('match_id', matchId)
          .maybeSingle();
      
      if (response != null) {
        return MatchDraft.fromMap(response as Map<String, dynamic>);
      }
    } catch (e) {
      return null;
    }
    return null;
  }

  @override
  Future<List<MatchPlayer>> fetchRoster({required String teamId}) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return [];
      }
      
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
      
      return players;
    } catch (e) {
      return [];
    }
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
      print('Failed to save player to Supabase: $e');
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
      print('Failed to save players to Supabase: $e');
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
      print('Synced ${players.length} players from Supabase');
    } catch (e) {
      print('Failed to sync players from Supabase: $e');
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
      print('Failed to clean old data: $e');
    }
  }

  @override
  Future<List<RosterTemplate>> loadRosterTemplates({required String teamId}) async {
    try {
      final client = getSupabaseClientOrNull();
      if (client == null) {
        return [];
      }

      final response = await client
          .from('roster_templates')
          .select('*')
          .eq('team_id', teamId)
          .order('use_count', ascending: false)
          .order('last_used_at', ascending: false)
          .order('name', ascending: true);

      final rows = (response as List).cast<Map<String, dynamic>>();
      return rows.map((row) => RosterTemplate.fromMap(row)).toList();
    } catch (e) {
      print('Failed to load roster templates: $e');
      return [];
    }
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
      print('Failed to save roster template: $e');
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
      print('Failed to delete roster template: $e');
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
        final currentTemplate = RosterTemplate.fromMap(template as Map<String, dynamic>);
        final updated = currentTemplate.markUsed();
        await saveRosterTemplate(teamId: teamId, template: updated);
      }
    } catch (e) {
      print('Failed to update template usage: $e');
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
}

MatchPlayer _decodePlayer(Map<String, dynamic> map) {
  return MatchPlayer(
    id: map['id'] as String,
    name: '${map['first_name']} ${map['last_name']}',
    jerseyNumber: map['jersey_number'] as int,
    position: map['position'] as String? ?? '',
  );
}
