import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/repository_errors.dart';
import '../models/match_draft.dart';
import '../models/match_player.dart';
import '../models/roster_template.dart';
import 'match_setup_repository.dart';

class SupabaseMatchSetupRepository implements MatchSetupRepository {
  SupabaseMatchSetupRepository(this._client);

  final SupabaseClient _client;

  @override
  bool get supportsEntityCreation => true; // Can create entities when connected

  @override
  bool get isConnected => true; // Connected to Supabase

  /// Get the current authenticated user's ID
  String? get _currentUserId => _client.auth.currentUser?.id;

  /// Get the effective team ID, ensuring it belongs to the current coach
  String _getEffectiveTeamId(String teamId) {
    if (teamId.isEmpty) {
      throw Exception('Team ID is required');
    }
    
    // RLS policies will enforce that the team belongs to the current coach
    // So we can trust the teamId parameter
    return teamId;
  }

  @override
  Future<List<MatchPlayer>> fetchRoster({required String teamId}) async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to fetch roster');
    }
    
    final effectiveTeamId = _getEffectiveTeamId(teamId);
    
    if (kDebugMode) {
      print('Fetching roster from Supabase for team: $effectiveTeamId (coach: $_currentUserId)');
    }
    
    try {
      // RLS will ensure we can only access teams where coach_id = auth.uid()
      final result = await _client
          .from('players')
          .select()
          .eq('team_id', effectiveTeamId)
          .order('jersey_number', ascending: true);

      final rows = (result as List<dynamic>)
          .cast<Map<String, dynamic>>();

      final players = rows.map(MatchPlayer.fromMap).toList();
      
      if (kDebugMode) {
        print('  Found ${players.length} players in database');
        for (final player in players) {
          print('    - ${player.jerseyNumber}: ${player.name} (ID: ${player.id})');
        }
      }
      
      return players;
    } catch (error, stackTrace) {
      print('Error fetching roster from Supabase: $error');
      print('  Team ID: $effectiveTeamId');
      rethrow;
    }
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
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to save draft');
    }
    
    final effectiveTeamId = _getEffectiveTeamId(teamId);
    final payload = {
      'team_id': effectiveTeamId,
      'match_id': matchId,
      ...draft.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    try {
      // Check if draft already exists
      final existing = await _client
          .from('match_drafts')
          .select('match_id')
          .eq('match_id', matchId)
          .maybeSingle();

      if (existing != null) {
        // Update existing draft
        await _client
            .from('match_drafts')
            .update(payload)
            .eq('match_id', matchId);
      } else {
        // Insert new draft
        await _client.from('match_drafts').insert(payload);
      }
      
      if (kDebugMode) {
        print('Saved draft to Supabase: $matchId');
      }
    } catch (error, stackTrace) {
      print('Error saving draft to Supabase: $error');
      print('Payload: $payload');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  @override
  Future<List<RosterTemplate>> loadRosterTemplates({required String teamId}) async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to load templates');
    }
    
    final effectiveTeamId = _getEffectiveTeamId(teamId);
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
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to save template');
    }
    
    final effectiveTeamId = _getEffectiveTeamId(teamId);
    
    // Convert team_id string to UUID format if needed
    final teamIdUuid = effectiveTeamId;
    
    // Build payload explicitly to ensure correct format
    final payload = <String, dynamic>{
      'id': template.id,
      'team_id': teamIdUuid,
      'name': template.name,
      'player_ids': template.playerIds.toList(),
      'default_rotation': {
        for (final entry in template.defaultRotation.entries)
          entry.key.toString(): entry.value,
      },
      'use_count': template.useCount,
      'created_at': template.createdAt.toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };
    
    // Add optional fields only if they exist
    if (template.description != null && template.description!.isNotEmpty) {
      payload['description'] = template.description;
    }
    if (template.lastUsedAt != null) {
      payload['last_used_at'] = template.lastUsedAt!.toIso8601String();
    }

    try {
      if (kDebugMode) {
        print('=== SAVING TEMPLATE TO SUPABASE ===');
        print('  Template ID: ${template.id}');
        print('  Template Name: ${template.name}');
        print('  Team ID: $teamIdUuid');
        print('  Player IDs (${template.playerIds.length}): ${template.playerIds.toList()}');
        print('  Rotation entries: ${template.defaultRotation.length}');
        
        // Check if player IDs exist in database
        try {
          if (template.playerIds.isNotEmpty) {
            final playerCheck = await _client
                .from('players')
                .select('id')
                .eq('team_id', teamIdUuid)
                .inFilter('id', template.playerIds.toList());
            final foundPlayerIds = (playerCheck as List).map((p) => p['id'] as String).toList();
            final missingPlayerIds = template.playerIds.where((id) => !foundPlayerIds.contains(id)).toList();
            
            if (missingPlayerIds.isNotEmpty) {
              print('  ⚠️  WARNING: ${missingPlayerIds.length} player IDs not found in database:');
              for (final id in missingPlayerIds) {
                print('    - $id');
              }
              print('  Found player IDs: $foundPlayerIds');
            } else {
              print('  ✓ All player IDs exist in database');
            }
          }
        } catch (e) {
          print('  ⚠️  Could not verify player IDs: $e');
        }
        
        print('  Payload keys: ${payload.keys.toList()}');
        print('  Payload: $payload');
        print('  Auth user: ${_client.auth.currentUser?.id ?? "NOT AUTHENTICATED"}');
      }
      
      // Verify table exists by checking if we can query it first
      try {
        await _client.from('roster_templates').select('id').limit(1);
        if (kDebugMode) {
          print('  ✓ Table exists and is accessible');
        }
      } catch (e) {
        print('  ✗ ERROR: Cannot access roster_templates table: $e');
        rethrow;
      }
      
      final response = await _client.from('roster_templates').upsert(payload, onConflict: 'id').select();
      
      if (kDebugMode) {
        print('✓ Successfully saved template to Supabase: ${template.id}');
        print('  Response: $response');
        print('  Response type: ${response.runtimeType}');
        if (response is List) {
          print('  Response count: ${response.length}');
          if (response.isNotEmpty) {
            print('  Response data: ${response.first}');
          }
        }
      }
    } catch (error, stackTrace) {
      print('✗ ERROR saving template to Supabase:');
      print('  Error: $error');
      print('  Error type: ${error.runtimeType}');
      print('  Payload: $payload');
      print('  Stack trace: $stackTrace');
      print('  Auth user: ${_client.auth.currentUser?.id ?? "NOT AUTHENTICATED"}');
      rethrow;
    }
  }

  @override
  Future<void> deleteRosterTemplate({
    required String teamId,
    required String templateId,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to delete template');
    }
    
    final effectiveTeamId = _getEffectiveTeamId(teamId);
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
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to update template usage');
    }
    
    final effectiveTeamId = _getEffectiveTeamId(teamId);
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

