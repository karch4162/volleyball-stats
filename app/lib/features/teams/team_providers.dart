import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/providers/supabase_client_provider.dart';
import '../auth/auth_provider.dart';
import 'models/team.dart';

/// Provider that fetches all teams for the current authenticated coach
final coachTeamsProvider = FutureProvider<List<Team>>((ref) async {
  final client = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (client == null || userId == null) {
    return [];
  }

  try {
    print('Fetching teams for coach: $userId');
    final response = await client
        .from('teams')
        .select()
        .eq('coach_id', userId)
        .order('name');

    print('Teams query response: $response');
    final rows = (response as List<dynamic>).cast<Map<String, dynamic>>();
    final teams = rows.map((row) => Team.fromMap(row)).toList();
    print('Parsed ${teams.length} teams');
    return teams;
  } catch (e, stackTrace) {
    print('Error fetching teams: $e');
    print('Stack trace: $stackTrace');
    rethrow; // Re-throw so the FutureProvider can handle the error
  }
});

/// Provider that stores the currently selected team ID
final selectedTeamIdProvider = StateProvider<String?>((ref) => null);

/// Provider that auto-selects a single team when there's only one team
/// This ensures coaches with a single team don't need to manually select it
/// Watch this provider in widgets that need auto-selection to work
final autoSelectTeamProvider = Provider<void>((ref) {
  final teams = ref.watch(coachTeamsProvider);
  final selectedTeamId = ref.watch(selectedTeamIdProvider);
  
  teams.whenData((teamList) {
    // Auto-select if there's exactly one team and no team is currently selected
    if (teamList.length == 1 && selectedTeamId == null) {
      // Use Future.microtask to avoid modifying state during build
      Future.microtask(() {
        if (ref.read(selectedTeamIdProvider) == null) {
          ref.read(selectedTeamIdProvider.notifier).state = teamList.first.id;
        }
      });
    }
  });
});

/// Provider that provides the currently selected team
final selectedTeamProvider = Provider<Team?>((ref) {
  final teams = ref.watch(coachTeamsProvider);
  final selectedId = ref.watch(selectedTeamIdProvider);

  if (teams.valueOrNull == null || selectedId == null) {
    return null;
  }

  return teams.valueOrNull!.firstWhere(
    (team) => team.id == selectedId,
    orElse: () => teams.valueOrNull!.first, // Fallback to first team
  );
});

/// Service for team operations
class TeamService {
  TeamService(this._client);

  final SupabaseClient? _client;

  /// Create a new team
  Future<Team> createTeam({
    required String name,
    String? level,
    String? seasonLabel,
    required String coachId,
  }) async {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }

    final response = await _client!.from('teams').insert({
      'name': name,
      'level': level,
      'season_label': seasonLabel,
      'coach_id': coachId,
    }).select().single();

    return Team.fromMap(response as Map<String, dynamic>);
  }

  /// Update an existing team
  Future<Team> updateTeam({
    required String teamId,
    String? name,
    String? level,
    String? seasonLabel,
  }) async {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }

    final updates = <String, dynamic>{};
    if (name != null) updates['name'] = name;
    if (level != null) updates['level'] = level;
    if (seasonLabel != null) updates['season_label'] = seasonLabel;

    final response = await _client!
        .from('teams')
        .update(updates)
        .eq('id', teamId)
        .select()
        .single();

    return Team.fromMap(response as Map<String, dynamic>);
  }

  /// Delete a team
  Future<void> deleteTeam(String teamId) async {
    if (_client == null) {
      throw Exception('Supabase client not initialized');
    }

    await _client!.from('teams').delete().eq('id', teamId);
  }
}

/// Provider for TeamService
final teamServiceProvider = Provider<TeamService>((ref) {
  final client = ref.watch(supabaseClientProvider);
  return TeamService(client);
});

