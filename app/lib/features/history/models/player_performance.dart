import '../../match_setup/models/match_player.dart';

class PlayerPerformance {
  PlayerPerformance({
    required this.playerId,
    required this.playerName,
    required this.jerseyNumber,
    required this.kills,
    required this.errors,
    required this.attempts,
    required this.blocks,
    required this.aces,
    required this.digs,
    required this.assists,
    required this.fbk,
    required this.serveErrors,
    required this.totalServes,
  });

  final String playerId;
  final String playerName;
  final int jerseyNumber;
  final int kills;
  final int errors;
  final int attempts;
  final int blocks;
  final int aces;
  final int digs;
  final int assists;
  final int fbk;
  final int serveErrors;
  final int totalServes;

  // Calculated properties
  double get attackEfficiency => attempts > 0 ? (kills - errors) / attempts : 0.0;
  double get killPercentage => attempts > 0 ? kills / attempts : 0.0;
  double get acePercentage => totalServes > 0 ? aces / totalServes : 0.0;
  double get servicePressure => totalServes > 0 ? (aces - serveErrors) / totalServes : 0.0;
  int get totalPoints => kills + blocks + aces;
  
  // Formatted display strings
  String get attackSummary => '$kills-$errors / $attempts (${(killPercentage * 100).toStringAsFixed(1)}%)';
  String get serveSummary => '$aces-$serveErrors / $totalServes (${(acePercentage * 100).toStringAsFixed(1)}%)';

  factory PlayerPerformance.fromMap(Map<String, dynamic> map) {
    final kills = (map['kills'] as num?)?.toInt() ?? 0;
    final errors = (map['errors'] as num?)?.toInt() ?? 0;
    final attempts = (map['attempts'] as num?)?.toInt() ?? 0;
    final blocks = (map['blocks'] as num?)?.toInt() ?? 0;
    final aces = (map['aces'] as num?)?.toInt() ?? 0;
    final digs = (map['digs'] as num?)?.toInt() ?? 0;
    final assists = (map['assists'] as num?)?.toInt() ?? 0;
    final fbk = (map['fbk'] as num?)?.toInt() ?? 0;
    final serveErrors = (map['serve_errors'] as num?)?.toInt() ?? 0;
    final totalServes = (map['total_serves'] as num?)?.toInt() ?? 
                        (aces + serveErrors); // Calculate if not provided

    return PlayerPerformance(
      playerId: map['player_id'] as String,
      playerName: map['player_name'] as String,
      jerseyNumber: (map['jersey_number'] as num?)?.toInt() ?? 0,
      kills: kills,
      errors: errors,
      attempts: attempts,
      blocks: blocks,
      aces: aces,
      digs: digs,
      assists: assists,
      fbk: fbk,
      serveErrors: serveErrors,
      totalServes: totalServes,
    );
  }

  factory PlayerPerformance.fromPlayerStats({
    required MatchPlayer player,
    required int kills,
    required int errors,
    required int attempts,
    required int blocks,
    required int aces,
    int digs = 0,
    int assists = 0,
    int fbk = 0,
    int serveErrors = 0,
    int? totalServes,
  }) {
    return PlayerPerformance(
      playerId: player.id,
      playerName: player.name,
      jerseyNumber: player.jerseyNumber,
      kills: kills,
      errors: errors,
      attempts: attempts,
      blocks: blocks,
      aces: aces,
      digs: digs,
      assists: assists,
      fbk: fbk,
      serveErrors: serveErrors,
      totalServes: totalServes ?? (aces + serveErrors),
    );
  }
}

