import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../match_setup/providers.dart';
import '../teams/team_providers.dart';
import 'models/match_summary.dart';
import 'models/set_summary.dart';
import 'models/player_performance.dart';
import 'models/kpi_summary.dart';
import 'utils/analytics_calculator.dart';

/// Provider for match summaries (history list)
final matchSummariesProvider = FutureProvider.family<List<MatchSummary>, MatchSummariesParams>(
  (ref, params) async {
    final repository = ref.watch(matchSetupRepositoryProvider);
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    
    if (selectedTeamId == null) {
      return [];
    }

    final summaries = await repository.fetchMatchSummaries(
      teamId: selectedTeamId,
      startDate: params.startDate,
      endDate: params.endDate,
      opponent: params.opponent,
      seasonLabel: params.seasonLabel,
    );

    return summaries.map((s) => MatchSummary.fromMap(s as Map<String, dynamic>)).toList();
  },
);

class MatchSummariesParams {
  MatchSummariesParams({
    this.startDate,
    this.endDate,
    this.opponent,
    this.seasonLabel,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final String? opponent;
  final String? seasonLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MatchSummariesParams &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        other.opponent == opponent &&
        other.seasonLabel == seasonLabel;
  }

  @override
  int get hashCode => Object.hash(
        startDate?.millisecondsSinceEpoch,
        endDate?.millisecondsSinceEpoch,
        opponent,
        seasonLabel,
      );
}

/// Provider for match details (full match recap)
final matchDetailsProvider = FutureProvider.family<MatchDetails?, String>(
  (ref, matchId) async {
    final repository = ref.watch(matchSetupRepositoryProvider);
    final details = await repository.fetchMatchDetails(matchId: matchId);
    
    if (details == null) {
      return null;
    }

    return MatchDetails.fromMap(details);
  },
);

class MatchDetails {
  MatchDetails({
    required this.matchId,
    required this.opponent,
    required this.matchDate,
    required this.location,
    required this.seasonLabel,
    required this.sets,
    required this.totalRallies,
    required this.totalFBK,
    required this.totalTransitionPoints,
    required this.substitutions,
    required this.timeouts,
    required this.playerPerformances,
  });

  final String matchId;
  final String opponent;
  final DateTime matchDate;
  final String location;
  final String? seasonLabel;
  final List<SetSummary> sets;
  final int totalRallies;
  final int totalFBK;
  final int totalTransitionPoints;
  final int substitutions;
  final int timeouts;
  final List<PlayerPerformance> playerPerformances;

  factory MatchDetails.fromMap(Map<String, dynamic> map) {
    final sets = (map['sets'] as List<dynamic>?) ?? [];
    final setSummaries = sets.map((s) {
      final setData = s as Map<String, dynamic>;
      final rallies = (setData['rallies'] as List<dynamic>?) ?? [];
      
      // Calculate set stats from rallies and actions
      int rallyCount = rallies.length;
      int fbkCount = 0;
      int transitionPoints = 0;
      int ourScore = 0;
      int opponentScore = 0;

      for (final rally in rallies) {
        final rallyData = rally as Map<String, dynamic>;
        final actions = (rallyData['actions'] as List<dynamic>?) ?? [];
        
        for (final action in actions) {
          final actionData = action as Map<String, dynamic>;
          final outcome = actionData['outcome'] as String?;
          final actionType = actionData['action_type'] as String?;
          
          if (outcome == 'first_ball_kill' || actionData['action_subtype'] == 'first_ball_kill') {
            fbkCount++;
            transitionPoints++;
          } else if (outcome == 'transition' || actionType == 'transition') {
            transitionPoints++;
          }
        }

        // Determine score from rally result
        final result = rallyData['result'] as String?;
        if (result == 'win') {
          ourScore++;
        } else if (result == 'loss') {
          opponentScore++;
        }
      }

      return SetSummary(
        setNumber: (setData['set_number'] as num).toInt(),
        ourScore: ourScore,
        opponentScore: opponentScore,
        rallyCount: rallyCount,
        fbkCount: fbkCount,
        transitionPoints: transitionPoints,
        isWin: (setData['result'] as String?) == 'win',
        duration: null, // Would calculate from start_time/end_time if available
      );
    }).toList();

    // Aggregate player performances from all sets
    final playerStatsMap = <String, Map<String, int>>{};
    int totalRallies = 0;
    int totalFBK = 0;
    int totalTransitionPoints = 0;
    int totalSubstitutions = 0;
    int totalTimeouts = 0;

    for (final set in sets) {
      final setData = set as Map<String, dynamic>;
      final rallies = (setData['rallies'] as List<dynamic>?) ?? [];
      totalRallies += rallies.length;

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

          if (!playerStatsMap.containsKey(playerId)) {
            playerStatsMap[playerId] = {
              'kills': 0,
              'errors': 0,
              'attempts': 0,
              'blocks': 0,
              'aces': 0,
              'serve_errors': 0,
            };
          }

          final stats = playerStatsMap[playerId]!;

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
            if (actionSubtype == 'ace') {
              stats['aces'] = (stats['aces'] ?? 0) + 1;
            } else if (actionSubtype == 'error') {
              stats['serve_errors'] = (stats['serve_errors'] ?? 0) + 1;
            }
          }

          if (outcome == 'first_ball_kill' || actionSubtype == 'first_ball_kill') {
            totalFBK++;
            totalTransitionPoints++;
          } else if (outcome == 'transition' || actionType == 'transition') {
            totalTransitionPoints++;
          }
        }
      }

      // Count substitutions and timeouts
      final substitutions = (setData['substitutions'] as List<dynamic>?) ?? [];
      final timeouts = (setData['timeouts'] as List<dynamic>?) ?? [];
      totalSubstitutions += substitutions.length;
      totalTimeouts += timeouts.length;
    }

    // Convert player stats to PlayerPerformance objects
    // Note: We'd need player names from a separate query or include in the response
    final playerPerformances = <PlayerPerformance>[];
    // This would need player data - for now return empty list
    // In a real implementation, you'd fetch player details or include them in the query

    return MatchDetails(
      matchId: map['id'] as String,
      opponent: map['opponent'] as String,
      matchDate: DateTime.parse(map['match_date'] as String),
      location: (map['location'] as String?) ?? '',
      seasonLabel: map['season_label'] as String?,
      sets: setSummaries,
      totalRallies: totalRallies,
      totalFBK: totalFBK,
      totalTransitionPoints: totalTransitionPoints,
      substitutions: totalSubstitutions,
      timeouts: totalTimeouts,
      playerPerformances: playerPerformances,
    );
  }
}

/// Provider for season statistics
final seasonStatsProvider = FutureProvider.family<SeasonStats, SeasonStatsParams>(
  (ref, params) async {
    final repository = ref.watch(matchSetupRepositoryProvider);
    final selectedTeamId = ref.watch(selectedTeamIdProvider);
    
    if (selectedTeamId == null) {
      return SeasonStats.empty();
    }

    final stats = await repository.fetchSeasonStats(
      teamId: selectedTeamId,
      startDate: params.startDate,
      endDate: params.endDate,
      opponentIds: params.opponentIds,
      seasonLabel: params.seasonLabel,
    );

    return SeasonStats.fromMap(stats);
  },
);

class SeasonStatsParams {
  SeasonStatsParams({
    this.startDate,
    this.endDate,
    this.opponentIds,
    this.seasonLabel,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final List<String>? opponentIds;
  final String? seasonLabel;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SeasonStatsParams &&
        other.startDate == startDate &&
        other.endDate == endDate &&
        listEquals(other.opponentIds, opponentIds) &&
        other.seasonLabel == seasonLabel;
  }

  @override
  int get hashCode => Object.hash(
        startDate?.millisecondsSinceEpoch,
        endDate?.millisecondsSinceEpoch,
        Object.hashAll(opponentIds ?? const []),
        seasonLabel,
      );
}

class SeasonStats {
  SeasonStats({
    required this.totalMatches,
    required this.matchesWon,
    required this.matchesLost,
    required this.totalSetsWon,
    required this.totalSetsLost,
    required this.totalRallies,
    required this.totalFBK,
    required this.totalTransitionPoints,
    required this.totalKills,
    required this.totalErrors,
    required this.totalAttempts,
    required this.totalBlocks,
    required this.totalAces,
    required this.totalServeErrors,
    required this.totalServes,
    required this.kpis,
    required this.playerStats,
  });

  final int totalMatches;
  final int matchesWon;
  final int matchesLost;
  final int totalSetsWon;
  final int totalSetsLost;
  final int totalRallies;
  final int totalFBK;
  final int totalTransitionPoints;
  final int totalKills;
  final int totalErrors;
  final int totalAttempts;
  final int totalBlocks;
  final int totalAces;
  final int totalServeErrors;
  final int totalServes;
  final KPISummary kpis;
  final Map<String, Map<String, int>> playerStats;

  factory SeasonStats.empty() {
    return SeasonStats(
      totalMatches: 0,
      matchesWon: 0,
      matchesLost: 0,
      totalSetsWon: 0,
      totalSetsLost: 0,
      totalRallies: 0,
      totalFBK: 0,
      totalTransitionPoints: 0,
      totalKills: 0,
      totalErrors: 0,
      totalAttempts: 0,
      totalBlocks: 0,
      totalAces: 0,
      totalServeErrors: 0,
      totalServes: 0,
      kpis: KPISummary.empty(),
      playerStats: {},
    );
  }

  factory SeasonStats.fromMap(Map<String, dynamic> map) {
    final kpis = AnalyticsCalculator.calculateKPIs(
      totalRallies: (map['total_rallies'] as num?)?.toInt() ?? 0,
      totalFBK: (map['total_fbk'] as num?)?.toInt() ?? 0,
      totalTransitionPoints: (map['total_transition_points'] as num?)?.toInt() ?? 0,
      totalKills: (map['total_kills'] as num?)?.toInt() ?? 0,
      totalErrors: (map['total_errors'] as num?)?.toInt() ?? 0,
      totalAttempts: (map['total_attempts'] as num?)?.toInt() ?? 0,
      totalBlocks: (map['total_blocks'] as num?)?.toInt() ?? 0,
      totalAces: (map['total_aces'] as num?)?.toInt() ?? 0,
      totalServeErrors: (map['total_serve_errors'] as num?)?.toInt() ?? 0,
      totalServes: (map['total_serves'] as num?)?.toInt() ?? 0,
      matchesWon: (map['matches_won'] as num?)?.toInt() ?? 0,
      totalMatches: (map['total_matches'] as num?)?.toInt() ?? 0,
    );

    final playerStats = (map['player_stats'] as Map<String, dynamic>?) ?? {};
    final playerStatsMap = <String, Map<String, int>>{};
    for (final entry in playerStats.entries) {
      playerStatsMap[entry.key] = Map<String, int>.from(
        (entry.value as Map).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
      );
    }

    return SeasonStats(
      totalMatches: (map['total_matches'] as num?)?.toInt() ?? 0,
      matchesWon: (map['matches_won'] as num?)?.toInt() ?? 0,
      matchesLost: (map['matches_lost'] as num?)?.toInt() ?? 0,
      totalSetsWon: (map['total_sets_won'] as num?)?.toInt() ?? 0,
      totalSetsLost: (map['total_sets_lost'] as num?)?.toInt() ?? 0,
      totalRallies: (map['total_rallies'] as num?)?.toInt() ?? 0,
      totalFBK: (map['total_fbk'] as num?)?.toInt() ?? 0,
      totalTransitionPoints: (map['total_transition_points'] as num?)?.toInt() ?? 0,
      totalKills: (map['total_kills'] as num?)?.toInt() ?? 0,
      totalErrors: (map['total_errors'] as num?)?.toInt() ?? 0,
      totalAttempts: (map['total_attempts'] as num?)?.toInt() ?? 0,
      totalBlocks: (map['total_blocks'] as num?)?.toInt() ?? 0,
      totalAces: (map['total_aces'] as num?)?.toInt() ?? 0,
      totalServeErrors: (map['total_serve_errors'] as num?)?.toInt() ?? 0,
      totalServes: (map['total_serves'] as num?)?.toInt() ?? 0,
      kpis: kpis,
      playerStats: playerStatsMap,
    );
  }
}

