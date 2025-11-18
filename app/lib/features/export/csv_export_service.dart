import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import '../rally_capture/models/rally_models.dart';
import '../match_setup/models/match_player.dart';

/// Service for exporting data to CSV format
class CsvExportService {
  const CsvExportService();

  /// Export rally data to CSV format
  Future<String> exportRalliesToCsv({
    required List<RallyRecord> rallies,
    required List<MatchPlayer> players,
    String? opponent,
    DateTime? matchDate,
  }) async {
    final lines = <String>[];
    
    // Header row
    lines.add(_buildCsvHeader());
    
    // Data rows
    for (final rally in rallies) {
      for (final event in rally.events) {
        lines.add(_buildCsvRow(
          rallyNumber: rally.rallyNumber,
          opponent: opponent,
          matchDate: matchDate,
          event: event,
          player: _findPlayerById(players, event.player?.id),
        ));
      }
    }
    
    return lines.join('\n');
  }

  /// Export player stats to CSV format
  Future<String> exportPlayerStatsToCsv({
    required List<MatchPlayer> players,
    required List<RallyRecord> rallies,
    Map<String, dynamic>? seasonTotals,
  }) async {
    final lines = <String>[];
    
    // Header row
    lines.add(_buildPlayerStatsHeader());
    
    // Player stats rows
    final playerStats = _calculatePlayerStats(rallies);
    
    for (final entry in playerStats.entries) {
      final player = _findPlayerById(players, entry.key);
      final stats = entry.value;
      
      lines.add(_buildPlayerStatsRow(
        player: player,
        stats: stats,
      ));
    }
    
    // Season totals row
    if (seasonTotals != null) {
      lines.add(_buildSeasonTotalsRow(seasonTotals));
    }
    
    return lines.join('\n');
  }

  /// Export match summary to CSV format
  Future<String> exportMatchSummaryToCsv({
    required List<RallyRecord> rallies,
    required String opponent,
    DateTime? matchDate,
    Map<String, dynamic>? seasonTotals,
  }) async {
    final lines = <String>[];
    
    // Header row
    lines.add(_buildMatchSummaryHeader());
    
    // Match summary rows
    final matchData = _calculateMatchSummary(rallies);
    
    lines.add(_buildMatchSummaryRow(
      opponent: opponent,
      matchDate: matchDate,
      summary: matchData,
    ));
    
    // Season totals row
    if (seasonTotals != null) {
      lines.add(_buildSeasonTotalsRow(seasonTotals));
    }
    
    return lines.join('\n');
  }

  /// Save CSV to device file
  Future<File> saveCsvToFile({
    required String csvContent,
    required String filename,
    String fileExtension = 'csv',
  }) async {
    final directory = Directory.systemTemp;
    final file = File('${directory.path}/${filename}.$fileExtension');
    
    await file.writeAsString(csvContent);
    return file;
  }

  /// Share CSV (platform dependent implementation)
  Future<void> shareCsvFile({
    required String csvContent,
    required String filename,
  }) async {
    // For mobile apps, you'd use share_plus or similar packages
    // For now, just save to temp and let user handle sharing
    final file = await saveCsvToFile(
      csvContent: csvContent,
      filename: '${filename}_export',
    );
    
    print('CSV exported to: ${file.path}');
    print('You can share this file with your preferred method');
  }

  String _buildCsvHeader() {
    return 'Date,Opponent,Set,Rally,Player,Jersey,Action,SubAction,Outcome,Rotation,Notes';
  }

  String _buildCsvRow({
    required int rallyNumber,
    String? opponent,
    DateTime? matchDate,
    required RallyEvent event,
    MatchPlayer? player,
  }) {
    final values = [
      matchDate?.toIso8601String().split('T').first ?? '', // Just date part
      opponent ?? '',
      '', // We'll add set number when implementing sets
      rallyNumber.toString(),
      player?.name ?? '',
      player != null ? player.jerseyNumber.toString() : '',
      event.type.label,
      _getActionSubtype(event.type),
      _determineActionOutcome(event),
      '', // We'll add rotation when tracking
      event.note ?? '',
    ];
    
    return values.map((v) => _escapeCsvValue(v.toString())).join(',');
  }

  String _buildPlayerStatsHeader() {
    return 'Player,Jersey,Serves,Total,Aces,Kills,Errors,Blocks,Digs,Assists,Points';
  }

  String _buildPlayerStatsRow({
    required MatchPlayer? player,
    required Map<String, dynamic> stats,
  }) {
    if (player == null) {
      return '';
    }
    final values = [
      player.name,
      player.jerseyNumber.toString(),
      (stats['serves_total'] ?? 0).toString(),
      (stats['serves_aces'] ?? 0).toString(),
      (stats['attacks_kills'] ?? 0).toString(),
      (stats['attacks_errors'] ?? 0).toString(),
      (stats['blocks_blocks'] ?? 0).toString(),
      (stats['digs_total'] ?? 0).toString(),
      (stats['assists_total'] ?? 0).toString(),
      (stats['points'] ?? 0).toString(),
    ];
    
    return values.map(_escapeCsvValue).join(',');
  }

  String _buildSeasonTotalsRow(Map<String, dynamic> seasonTotals) {
    // This would be formatted based on the actual season_totals table structure
    return 'Season Totals,${seasonTotals['kills']},...'
        '';
  }

  String _buildMatchSummaryHeader() {
    return 'Opponent,MatchDate,TotalRallies,PointsFor,PointsAgainst,Winner';
  }

  String _buildMatchSummaryRow({
    required String opponent,
    DateTime? matchDate,
    required Map<String, dynamic> summary,
  }) {
    final values = [
      opponent,
      matchDate?.toIso8601String().split('T').first ?? '',
      (summary['totalRallies'] ?? 0).toString(),
      (summary['pointsFor'] ?? 0).toString(),
      (summary['pointsAgainst'] ?? 0).toString(),
      (summary['winner'] ?? 'pending'),
    ];
    
    return values.map((v) => _escapeCsvValue(v.toString())).join(',');
  }

  String _getActionSubtype(RallyActionTypes type) {
    switch (type) {
      case RallyActionTypes.serveAce:
        return 'ace';
      case RallyActionTypes.serveError:
        return 'error';
      case RallyActionTypes.firstBallKill:
        return 'fbk';
      case RallyActionTypes.attackKill:
        return 'kill';
      case RallyActionTypes.attackError:
        return 'error';
      case RallyActionTypes.attackAttempt:
        return 'attempt';
      case RallyActionTypes.block:
        return 'block';
      case RallyActionTypes.dig:
        return 'dig';
      case RallyActionTypes.assist:
        return 'assist';
      case RallyActionTypes.timeout:
        return 'timeout';
      case RallyActionTypes.substitution:
        return 'substitution';
    }
  }

  String _determineActionOutcome(RallyEvent event) {
    switch (event.type) {
      case RallyActionTypes.serveAce:
      case RallyActionTypes.firstBallKill:
      case RallyActionTypes.attackKill:
        return 'point';
      case RallyActionTypes.serveError:
      case RallyActionTypes.attackError:
        return 'error';
      case RallyActionTypes.attackAttempt:
        return 'in_play';
      case RallyActionTypes.block:
        return 'block_point';
      default:
        return 'neutral';
    }
  }

  String _escapeCsvValue(String value) {
    // Escape CSV special characters by wrapping in quotes if needed
    if (value.contains(',') || value.contains('"') || value.contains('\n') || value.contains('\r')) {
      return '"$value"';
    }
    return value;
  }

  MatchPlayer? _findPlayerById(List<MatchPlayer> players, String? playerId) {
    if (playerId == null) return null;
    
    try {
      return players.firstWhere((p) => p.id == playerId);
    } catch (_) {
      return null;
    }
  }

  Map<String, Map<String, dynamic>> _calculatePlayerStats(List<RallyRecord> rallies) {
    final playerStats = <String, Map<String, dynamic>>{};
    
    for (final rally in rallies) {
      for (final event in rally.events) {
        if (event.player == null) continue;
        
        final playerId = event.player!.id;
        if (!playerStats.containsKey(playerId)) {
          playerStats[playerId] = {
            'serves_total': 0,
            'serves_aces': 0,
            'serves_errors': 0,
            'attacks_total': 0,
            'attacks_kills': 0,
            'attacks_errors': 0,
            'blocks_blocks': 0,
            'blocks_total': 0,
            'digs_total': 0,
            'assists_total': 0,
            'points': 0,
          };
        }
        
        final stats = playerStats[playerId]!;
        
        switch (event.type) {
          case RallyActionTypes.serveAce:
            stats['serves_total'] = (stats['serves_total'] ?? 0) + 1;
            stats['serves_aces'] = (stats['serves_aces'] ?? 0) + 1;
            stats['points'] = (stats['points'] ?? 0) + 1;
            break;
            
          case RallyActionTypes.serveError:
            stats['serves_total'] = (stats['serves_total'] ?? 0) + 1;
            stats['serves_errors'] = (stats['serves_errors'] ?? 0) + 1;
            break;
            
          case RallyActionTypes.attackKill:
          case RallyActionTypes.firstBallKill:
            stats['attacks_total'] = (stats['attacks_total'] ?? 0) + 1;
            stats['attacks_kills'] = (stats['attacks_kills'] ?? 0) + 1;
            stats['points'] = (stats['points'] ?? 0) + 1;
            break;
            
          case RallyActionTypes.attackError:
            stats['attacks_total'] = (stats['attacks_total'] ?? 0) + 1;
            stats['attacks_errors'] = (stats['attacks_errors'] ?? 0) + 1;
            break;
            
          case RallyActionTypes.attackAttempt:
            stats['attacks_total'] = (stats['attacks_total'] ?? 0) + 1;
            break;
            
          case RallyActionTypes.block:
            stats['blocks_total'] = (stats['blocks_total'] ?? 0) + 1;
            stats['blocks_blocks'] = (stats['blocks_blocks'] ?? 0) + 1;
            stats['points'] = (stats['points'] ?? 0) + 1;
            break;
            
          case RallyActionTypes.dig:
            stats['digs_total'] = (stats['digs_total'] ?? 0) + 1;
            break;
            
          case RallyActionTypes.assist:
            stats['assists_total'] = (stats['assists_total'] ?? 0) + 1;
            break;
            
          case RallyActionTypes.timeout:
          case RallyActionTypes.substitution:
            // These don't affect player stats
            break;
        }
      }
    }
    
    return playerStats;
  }

  Map<String, dynamic> _calculateMatchSummary(List<RallyRecord> rallies) {
    int totalRallies = rallies.length;
    int pointsFor = 0;
    int pointsAgainst = 0;
    String winner = 'pending';
    
    for (final rally in rallies) {
      // Simple logic: point-scoring actions = points for us, errors = points against
      final ourPoints = rally.events.where((e) =>
          _isPointScoringAction(e.type)
      ).length;
      
      int theirPoints = rally.events.where((e) =>
          _isErrorAction(e.type)
      ).length;
      
      if (ourPoints > 0) {
        pointsFor += ourPoints;
        theirPoints = math.min(theirPoints, 1); // Only count 1 error per rally
      } else {
        pointsAgainst += theirPoints;
      }
    }
    
    if (pointsFor >= pointsAgainst && totalRallies > 0) {
      winner = 'us';
    } else if (pointsAgainst > pointsFor && totalRallies > 0) {
      winner = 'opponent';
    }
    
    return {
      'totalRallies': totalRallies,
      'pointsFor': pointsFor,
      'pointsAgainst': pointsAgainst,
      'winner': winner,
    };
  }

  bool _isPointScoringAction(RallyActionTypes type) {
    switch (type) {
      case RallyActionTypes.serveAce:
      case RallyActionTypes.firstBallKill:
      case RallyActionTypes.attackKill:
      case RallyActionTypes.block:
        return true;
      default:
        return false;
    }
  }

  bool _isErrorAction(RallyActionTypes type) {
    switch (type) {
      case RallyActionTypes.serveError:
      case RallyActionTypes.attackError:
        return true;
      default:
        return false;
    }
  }
}
