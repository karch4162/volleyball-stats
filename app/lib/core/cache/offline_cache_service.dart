import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../../features/match_setup/models/match_player.dart';
import '../../features/match_setup/models/roster_template.dart';
import '../../features/teams/models/team.dart';

/// Service for caching Supabase data offline for read-only access
class OfflineCacheService {
  OfflineCacheService(this._teamsBox, this._playersBox, this._templatesBox);

  final Box<String> _teamsBox;
  final Box<String> _playersBox;
  final Box<String> _templatesBox;

  // Cache expiration: 7 days
  static const Duration cacheExpiration = Duration(days: 7);
  static const String _cacheTimestampKey = '_cache_timestamp';
  static const String _teamsPrefix = 'teams_';
  static const String _playersPrefix = 'players_';
  static const String _templatesPrefix = 'templates_';

  /// Check if cache is valid (not expired)
  bool get isCacheValid {
    final timestampStr = _teamsBox.get(_cacheTimestampKey);
    if (timestampStr == null) return false;

    final timestamp = DateTime.tryParse(timestampStr);
    if (timestamp == null) return false;

    final age = DateTime.now().difference(timestamp);
    return age < cacheExpiration;
  }

  /// Update cache timestamp
  Future<void> _updateCacheTimestamp() async {
    await _teamsBox.put(_cacheTimestampKey, DateTime.now().toIso8601String());
  }

  // Teams caching
  Future<void> cacheTeams(List<Team> teams) async {
    final data = teams.map((team) => jsonEncode(team.toMap())).toList();
    await _teamsBox.put('${_teamsPrefix}list', jsonEncode(data));
    await _updateCacheTimestamp();
  }

  List<Team>? getCachedTeams() {
    final dataStr = _teamsBox.get('${_teamsPrefix}list');
    if (dataStr == null) return null;

    try {
      final data = jsonDecode(dataStr) as List<dynamic>;
      return data
          .map((item) => Team.fromMap(jsonDecode(item as String) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  // Players caching (by team)
  Future<void> cachePlayers(String teamId, List<MatchPlayer> players) async {
    final data = players.map((player) => jsonEncode({
      'id': player.id,
      'first_name': player.name.split(' ').first,
      'last_name': player.name.split(' ').length > 1 
          ? player.name.split(' ').skip(1).join(' ') 
          : '',
      'jersey_number': player.jerseyNumber,
      'position': player.position,
    })).toList();
    await _playersBox.put('${_playersPrefix}$teamId', jsonEncode(data));
  }

  List<MatchPlayer>? getCachedPlayers(String teamId) {
    final dataStr = _playersBox.get('${_playersPrefix}$teamId');
    if (dataStr == null) return null;

    try {
      final data = jsonDecode(dataStr) as List<dynamic>;
      return data
          .map((item) => MatchPlayer.fromMap(jsonDecode(item as String) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  // Templates caching (by team)
  Future<void> cacheTemplates(String teamId, List<RosterTemplate> templates) async {
    final data = templates.map((template) => jsonEncode(template.toMap())).toList();
    await _templatesBox.put('${_templatesPrefix}$teamId', jsonEncode(data));
  }

  List<RosterTemplate>? getCachedTemplates(String teamId) {
    final dataStr = _templatesBox.get('${_templatesPrefix}$teamId');
    if (dataStr == null) return null;

    try {
      final data = jsonDecode(dataStr) as List<dynamic>;
      return data
          .map((item) => RosterTemplate.fromMap(jsonDecode(item as String) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return null;
    }
  }

  /// Clear all cached data
  Future<void> clearCache() async {
    await _teamsBox.clear();
    await _playersBox.clear();
    await _templatesBox.clear();
  }

  /// Clear expired cache
  Future<void> clearExpiredCache() async {
    if (!isCacheValid) {
      await clearCache();
    }
  }
}

// Box names for Hive
const String offlineCacheTeamsBoxName = 'offline_cache_teams';
const String offlineCachePlayersBoxName = 'offline_cache_players';
const String offlineCacheTemplatesBoxName = 'offline_cache_templates';

bool _offlineCacheInitialized = false;

/// Initialize and create the offline cache service
Future<OfflineCacheService> createOfflineCacheService() async {
  if (!_offlineCacheInitialized) {
    await Hive.initFlutter();
    _offlineCacheInitialized = true;
  }

  final teamsBox = Hive.isBoxOpen(offlineCacheTeamsBoxName)
      ? Hive.box<String>(offlineCacheTeamsBoxName)
      : await Hive.openBox<String>(offlineCacheTeamsBoxName);

  final playersBox = Hive.isBoxOpen(offlineCachePlayersBoxName)
      ? Hive.box<String>(offlineCachePlayersBoxName)
      : await Hive.openBox<String>(offlineCachePlayersBoxName);

  final templatesBox = Hive.isBoxOpen(offlineCacheTemplatesBoxName)
      ? Hive.box<String>(offlineCacheTemplatesBoxName)
      : await Hive.openBox<String>(offlineCacheTemplatesBoxName);

  return OfflineCacheService(teamsBox, playersBox, templatesBox);
}

