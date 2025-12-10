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

  @override
  Future<List<dynamic>> fetchMatchSummaries({
    required String teamId,
    DateTime? startDate,
    DateTime? endDate,
    String? opponent,
    String? seasonLabel,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to fetch match summaries');
    }

    final effectiveTeamId = _getEffectiveTeamId(teamId);
    
    var query = _client
        .from('matches')
        .select('''
          id,
          opponent,
          match_date,
          location,
          season_label,
          sets:sets(
            id,
            set_number,
            result,
            rallies:rallies(
              id,
              actions:actions(
                action_type,
                action_subtype,
                outcome
              )
            )
          )
        ''')
        .eq('team_id', effectiveTeamId);

    if (startDate != null) {
      query = query.gte('match_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('match_date', endDate.toIso8601String().split('T')[0]);
    }
    if (opponent != null && opponent.isNotEmpty) {
      query = query.ilike('opponent', '%$opponent%');
    }
    if (seasonLabel != null && seasonLabel.isNotEmpty) {
      query = query.eq('season_label', seasonLabel);
    }

    final result = await query.order('match_date', ascending: false);
    final matches = (result as List<dynamic>).cast<Map<String, dynamic>>();

    // Process matches to calculate summaries
    final summaries = <Map<String, dynamic>>[];
    for (final match in matches) {
      final sets = (match['sets'] as List<dynamic>?) ?? [];
      int setsWon = 0;
      int setsLost = 0;
      int totalRallies = 0;
      int totalFBK = 0;
      int totalTransitionPoints = 0;

      for (final set in sets) {
        final setData = set as Map<String, dynamic>;
        final result = setData['result'] as String?;
        if (result == 'win') {
          setsWon++;
        } else if (result == 'loss') {
          setsLost++;
        }

        final rallies = (setData['rallies'] as List<dynamic>?) ?? [];
        for (final rally in rallies) {
          totalRallies++;
          final rallyData = rally as Map<String, dynamic>;
          final actions = (rallyData['actions'] as List<dynamic>?) ?? [];
          for (final action in actions) {
            final actionData = action as Map<String, dynamic>;
            final actionType = actionData['action_type'] as String?;
            final actionSubtype = actionData['action_subtype'] as String?;
            final outcome = actionData['outcome'] as String?;

            if (outcome == 'first_ball_kill' || actionSubtype == 'first_ball_kill') {
              totalFBK++;
              totalTransitionPoints++;
            } else if (outcome == 'transition' || actionType == 'transition') {
              totalTransitionPoints++;
            }
          }
        }
      }

      summaries.add({
        'id': match['id'],
        'opponent': match['opponent'],
        'match_date': match['match_date'],
        'location': match['location'] ?? '',
        'season_label': match['season_label'],
        'sets_won': setsWon,
        'sets_lost': setsLost,
        'total_rallies': totalRallies,
        'total_fbk': totalFBK, // Would need to aggregate from actions
        'total_transition_points': totalTransitionPoints, // Would need to aggregate from actions
        'is_win': setsWon > setsLost,
      });
    }

    return summaries;
  }

  @override
  Future<Map<String, dynamic>?> fetchMatchDetails({
    required String matchId,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to fetch match details');
    }

    try {
      // Fetch match with sets, rallies, and actions
      final matchResult = await _client
          .from('matches')
          .select('''
            *,
            sets:sets(
              *,
              rallies:rallies(
                *,
                actions:actions(*)
              ),
              substitutions:substitutions(*),
              timeouts:timeouts(*)
            )
          ''')
          .eq('id', matchId)
          .single();

      return matchResult as Map<String, dynamic>?;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching match details: $e');
      }
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
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to fetch season stats');
    }

    final effectiveTeamId = _getEffectiveTeamId(teamId);
    
    var query = _client
        .from('matches')
        .select('''
          id,
          opponent,
          match_date,
          sets:sets(
            id,
            result,
            rallies:rallies(
              id,
              actions:actions(*)
            )
          )
        ''')
        .eq('team_id', effectiveTeamId);

    if (startDate != null) {
      query = query.gte('match_date', startDate.toIso8601String().split('T')[0]);
    }
    if (endDate != null) {
      query = query.lte('match_date', endDate.toIso8601String().split('T')[0]);
    }
    if (opponentIds != null && opponentIds.isNotEmpty) {
      // Note: This would need opponent IDs, but we store opponent as text
      // For now, we'll filter by opponent name if needed
    }
    if (seasonLabel != null && seasonLabel.isNotEmpty) {
      query = query.eq('season_label', seasonLabel);
    }

    final result = await query.order('match_date', ascending: false);
    final matches = (result as List<dynamic>).cast<Map<String, dynamic>>();

    // Aggregate statistics
    int totalMatches = matches.length;
    int matchesWon = 0;
    int totalSetsWon = 0;
    int totalSetsLost = 0;
    int totalRallies = 0;
    int totalFBK = 0;
    int totalTransitionPoints = 0;
    int totalKills = 0;
    int totalErrors = 0;
    int totalAttempts = 0;
    int totalBlocks = 0;
    int totalAces = 0;
    int totalServeErrors = 0;
    int totalServes = 0;

    final playerStats = <String, Map<String, int>>{};

    for (final match in matches) {
      final sets = (match['sets'] as List<dynamic>?) ?? [];
      int matchSetsWon = 0;
      int matchSetsLost = 0;

      for (final set in sets) {
        final setData = set as Map<String, dynamic>;
        final result = setData['result'] as String?;
        if (result == 'win') {
          matchSetsWon++;
          totalSetsWon++;
        } else if (result == 'loss') {
          matchSetsLost++;
          totalSetsLost++;
        }

        final rallies = (setData['rallies'] as List<dynamic>?) ?? [];
        for (final rally in rallies) {
          totalRallies++;
          final rallyData = rally as Map<String, dynamic>;
          final actions = (rallyData['actions'] as List<dynamic>?) ?? [];

          for (final action in actions) {
            final actionData = action as Map<String, dynamic>;
            final actionType = actionData['action_type'] as String?;
            final actionSubtype = actionData['action_subtype'] as String?;
            final playerId = actionData['player_id'] as String?;

            // Initialize player stats if needed
            if (playerId != null && !playerStats.containsKey(playerId)) {
              playerStats[playerId] = {
                'kills': 0,
                'errors': 0,
                'attempts': 0,
                'blocks': 0,
                'aces': 0,
                'serve_errors': 0,
                'digs': 0,
                'assists': 0,
                'fbk': 0,
              };
            }

            // Aggregate stats
            if (actionType == 'attack') {
              totalAttempts++;
              if (playerId != null) {
                playerStats[playerId]!['attempts'] =
                    (playerStats[playerId]!['attempts'] ?? 0) + 1;
              }
              if (actionSubtype == 'kill') {
                totalKills++;
                if (playerId != null) {
                  playerStats[playerId]!['kills'] =
                      (playerStats[playerId]!['kills'] ?? 0) + 1;
                }
              } else if (actionSubtype == 'error') {
                totalErrors++;
                if (playerId != null) {
                  playerStats[playerId]!['errors'] =
                      (playerStats[playerId]!['errors'] ?? 0) + 1;
                }
              }
            } else if (actionType == 'block') {
              totalBlocks++;
              if (playerId != null) {
                playerStats[playerId]!['blocks'] =
                    (playerStats[playerId]!['blocks'] ?? 0) + 1;
              }
            } else if (actionType == 'serve') {
              totalServes++;
              if (actionSubtype == 'ace') {
                totalAces++;
                if (playerId != null) {
                  playerStats[playerId]!['aces'] =
                      (playerStats[playerId]!['aces'] ?? 0) + 1;
                }
              } else if (actionSubtype == 'error') {
                totalServeErrors++;
                if (playerId != null) {
                  playerStats[playerId]!['serve_errors'] =
                      (playerStats[playerId]!['serve_errors'] ?? 0) + 1;
                }
              }
            } else if (actionType == 'dig') {
              if (playerId != null) {
                playerStats[playerId]!['digs'] =
                    (playerStats[playerId]!['digs'] ?? 0) + 1;
              }
            } else if (actionType == 'assist') {
              if (playerId != null) {
                playerStats[playerId]!['assists'] =
                    (playerStats[playerId]!['assists'] ?? 0) + 1;
              }
            }

            // Check for FBK and transition points
            final outcome = actionData['outcome'] as String?;
            if (outcome == 'first_ball_kill' || actionSubtype == 'first_ball_kill') {
              totalFBK++;
              if (playerId != null) {
                playerStats[playerId]!['fbk'] =
                    (playerStats[playerId]!['fbk'] ?? 0) + 1;
              }
              totalTransitionPoints++;
            } else if (outcome == 'transition' || actionType == 'transition') {
              totalTransitionPoints++;
            }
          }
        }
      }

      if (matchSetsWon > matchSetsLost) {
        matchesWon++;
      }
    }

    return {
      'total_matches': totalMatches,
      'matches_won': matchesWon,
      'matches_lost': totalMatches - matchesWon,
      'total_sets_won': totalSetsWon,
      'total_sets_lost': totalSetsLost,
      'total_rallies': totalRallies,
      'total_fbk': totalFBK,
      'total_transition_points': totalTransitionPoints,
      'total_kills': totalKills,
      'total_errors': totalErrors,
      'total_attempts': totalAttempts,
      'total_blocks': totalBlocks,
      'total_aces': totalAces,
      'total_serve_errors': totalServeErrors,
      'total_serves': totalServes,
      'player_stats': playerStats,
    };
  }

  @override
  Future<Map<String, Map<String, int>>> fetchSetPlayerStats({
    required String matchId,
    required int setNumber,
  }) async {
    if (_currentUserId == null) {
      throw Exception('User must be authenticated to fetch set player stats');
    }

    try {
      // Fetch the specific set with all actions
      final setResult = await _client
          .from('sets')
          .select('''
            id,
            rallies:rallies(
              id,
              actions:actions(*)
            )
          ''')
          .eq('match_id', matchId)
          .eq('set_number', setNumber)
          .maybeSingle();

      if (setResult == null) {
        return {};
      }

      final setData = setResult as Map<String, dynamic>;
      final rallies = (setData['rallies'] as List<dynamic>?) ?? [];
      
      final playerStats = <String, Map<String, int>>{};

      for (final rally in rallies) {
        final rallyData = rally as Map<String, dynamic>;
        final actions = (rallyData['actions'] as List<dynamic>?) ?? [];

        for (final action in actions) {
          final actionData = action as Map<String, dynamic>;
          final playerId = actionData['player_id'] as String?;
          final actionType = actionData['action_type'] as String?;
          final actionSubtype = actionData['action_subtype'] as String?;
          final outcome = actionData['outcome'] as String?;

          if (playerId == null) continue;

          // Initialize player stats if needed
          if (!playerStats.containsKey(playerId)) {
            playerStats[playerId] = {
              'kills': 0,
              'errors': 0,
              'attempts': 0,
              'blocks': 0,
              'aces': 0,
              'serve_errors': 0,
              'digs': 0,
              'assists': 0,
              'fbk': 0,
              'total_serves': 0,
            };
          }

          final stats = playerStats[playerId]!;

          // Count stats by action type
          if (actionType == 'attack') {
            stats['attempts'] = (stats['attempts'] ?? 0) + 1;
            if (actionSubtype == 'kill') {
              stats['kills'] = (stats['kills'] ?? 0) + 1;
            } else if (actionSubtype == 'error') {
              stats['errors'] = (stats['errors'] ?? 0) + 1;
            }
          } else if (actionType == 'block') {
            stats['blocks'] = (stats['blocks'] ?? 0) + 1;
          } else if (actionType == 'serve') {
            stats['total_serves'] = (stats['total_serves'] ?? 0) + 1;
            if (actionSubtype == 'ace') {
              stats['aces'] = (stats['aces'] ?? 0) + 1;
            } else if (actionSubtype == 'error') {
              stats['serve_errors'] = (stats['serve_errors'] ?? 0) + 1;
            }
          } else if (actionType == 'dig') {
            stats['digs'] = (stats['digs'] ?? 0) + 1;
          } else if (actionType == 'assist') {
            stats['assists'] = (stats['assists'] ?? 0) + 1;
          }

          // Check for FBK
          if (outcome == 'first_ball_kill' || actionSubtype == 'first_ball_kill') {
            stats['fbk'] = (stats['fbk'] ?? 0) + 1;
          }
        }
      }

      return playerStats;
    } catch (e) {
      if (kDebugMode) {
        print('Error fetching set player stats: $e');
      }
      return {};
    }
  }
}

