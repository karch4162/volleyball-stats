import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/match_setup/models/match_player.dart';
import '../../features/match_setup/models/roster_template.dart';
import '../../features/teams/models/team.dart';
import 'offline_cache_service.dart';

/// Service for syncing Supabase data to offline cache
class CacheSyncService {
  CacheSyncService({
    required OfflineCacheService cache,
    required SupabaseClient? client,
  })  : _cache = cache,
        _client = client;

  final OfflineCacheService _cache;
  final SupabaseClient? _client;

  /// Sync all data for the current authenticated user
  /// Fetches teams, players, and templates and updates cache
  Future<void> syncCache({String? userId}) async {
    if (_client == null || userId == null) {
      if (kDebugMode) {
        print('CacheSyncService: Cannot sync - no client or userId');
      }
      return;
    }

    try {
      if (kDebugMode) {
        print('CacheSyncService: Starting cache sync for user: $userId');
      }

      // Fetch teams for the coach
      final teamsResponse = await _client
          .from('teams')
          .select()
          .eq('coach_id', userId)
          .order('name');

      final teams = (teamsResponse as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((row) => Team.fromMap(row))
          .toList();

      if (kDebugMode) {
        print('CacheSyncService: Fetched ${teams.length} teams');
      }

      // Cache teams
      await _cache.cacheTeams(teams);

      // For each team, fetch players and templates
      for (final team in teams) {
        // Fetch players
        try {
          final playersResponse = await _client
              .from('players')
              .select()
              .eq('team_id', team.id)
              .order('jersey_number', ascending: true);

          final players = (playersResponse as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map((row) => MatchPlayer.fromMap(row))
              .toList();

          await _cache.cachePlayers(team.id, players);

          if (kDebugMode) {
            print('CacheSyncService: Cached ${players.length} players for team: ${team.name}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('CacheSyncService: Error caching players for team ${team.id}: $e');
          }
        }

        // Fetch templates
        try {
          final templatesResponse = await _client
              .from('roster_templates')
              .select()
              .eq('team_id', team.id)
              .order('use_count', ascending: false)
              .order('last_used_at', ascending: false)
              .order('name', ascending: true);

          final templates = (templatesResponse as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .map((row) => RosterTemplate.fromMap(row))
              .toList();

          await _cache.cacheTemplates(team.id, templates);

          if (kDebugMode) {
            print('CacheSyncService: Cached ${templates.length} templates for team: ${team.name}');
          }
        } catch (e) {
          if (kDebugMode) {
            print('CacheSyncService: Error caching templates for team ${team.id}: $e');
          }
        }
      }

      if (kDebugMode) {
        print('CacheSyncService: Cache sync completed successfully');
      }
    } catch (error, stackTrace) {
      if (kDebugMode) {
        print('CacheSyncService: Error during cache sync: $error');
        print('Stack trace: $stackTrace');
      }
      rethrow;
    }
  }
}

