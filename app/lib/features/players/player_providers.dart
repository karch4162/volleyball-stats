import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_client_provider.dart';
import '../auth/auth_provider.dart';
import '../match_setup/models/match_player.dart';
import '../teams/team_providers.dart';

/// Provider that fetches all players for the selected team
final teamPlayersProvider = FutureProvider.family<List<MatchPlayer>, String>((ref, teamId) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (client == null || userId == null || teamId.isEmpty) {
    return [];
  }

  try {
    final response = await client
        .from('players')
        .select()
        .eq('team_id', teamId)
        .eq('active', true)
        .order('jersey_number', ascending: true);

    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    return rows.map((row) => MatchPlayer.fromMap(row)).toList();
  } catch (e, stackTrace) {
    print('Error fetching players: $e');
    print('Stack trace: $stackTrace');
    rethrow;
  }
});

/// Provider for players of the currently selected team
final selectedTeamPlayersProvider = FutureProvider<List<MatchPlayer>>((ref) {
  final selectedTeamId = ref.watch(selectedTeamIdProvider);
  if (selectedTeamId == null) {
    return Future.value([]);
  }
  return ref.watch(teamPlayersProvider(selectedTeamId).future);
});

/// Service for player operations
class PlayerService {
  PlayerService(this._client);

  final SupabaseClient? _client;

  /// Create a new player
  Future<MatchPlayer> createPlayer({
    required String teamId,
    required String firstName,
    required String lastName,
    required int jerseyNumber,
    String? position,
  }) async {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }

    // Check if jersey number is already taken for this team
    final existing = await _client!
        .from('players')
        .select('id')
        .eq('team_id', teamId)
        .eq('jersey_number', jerseyNumber)
        .maybeSingle();

    if (existing != null) {
      throw Exception('Jersey number $jerseyNumber is already taken for this team');
    }

    final response = await _client!.from('players').insert({
      'team_id': teamId,
      'first_name': firstName,
      'last_name': lastName,
      'jersey_number': jerseyNumber,
      'position': position,
      'active': true,
    }).select().single();

    return MatchPlayer.fromMap(response as Map<String, dynamic>);
  }

  /// Update an existing player
  Future<MatchPlayer> updatePlayer({
    required String playerId,
    required String teamId,
    String? firstName,
    String? lastName,
    int? jerseyNumber,
    String? position,
  }) async {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }

    // If jersey number is being changed, check if new number is available
    if (jerseyNumber != null) {
      final existing = await _client!
          .from('players')
          .select('id')
          .eq('team_id', teamId)
          .eq('jersey_number', jerseyNumber)
          .neq('id', playerId)
          .maybeSingle();

      if (existing != null) {
        throw Exception('Jersey number $jerseyNumber is already taken for this team');
      }
    }

    final updates = <String, dynamic>{};
    if (firstName != null) updates['first_name'] = firstName;
    if (lastName != null) updates['last_name'] = lastName;
    if (jerseyNumber != null) updates['jersey_number'] = jerseyNumber;
    if (position != null) updates['position'] = position;

    final response = await _client!
        .from('players')
        .update(updates)
        .eq('id', playerId)
        .select()
        .single();

    return MatchPlayer.fromMap(response as Map<String, dynamic>);
  }

  /// Delete a player (soft delete by setting active = false)
  Future<void> deletePlayer(String playerId) async {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }

    await _client!
        .from('players')
        .update({'active': false})
        .eq('id', playerId);
  }
}

/// Provider for PlayerService
final playerServiceProvider = Provider<PlayerService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return PlayerService(client);
});

