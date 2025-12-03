import '../../match_setup/models/match_player.dart';

class PlayerPerformance {
  PlayerPerformance({
    required this.playerId,
    required this.playerName,
    required this.jerseyNumber,
    required this.kills,
    required this.errors,
    required this.attempts,
    required this.attackEfficiency,
    required this.killPercentage,
    required this.blocks,
    required this.aces,
    required this.totalPoints,
  });

  final String playerId;
  final String playerName;
  final int jerseyNumber;
  final int kills;
  final int errors;
  final int attempts;
  final double attackEfficiency;
  final double killPercentage;
  final int blocks;
  final int aces;
  final int totalPoints;

  factory PlayerPerformance.fromMap(Map<String, dynamic> map) {
    final kills = (map['kills'] as num?)?.toInt() ?? 0;
    final errors = (map['errors'] as num?)?.toInt() ?? 0;
    final attempts = (map['attempts'] as num?)?.toInt() ?? 0;
    final blocks = (map['blocks'] as num?)?.toInt() ?? 0;
    final aces = (map['aces'] as num?)?.toInt() ?? 0;

    final attackEfficiency = attempts > 0 ? (kills - errors) / attempts : 0.0;
    final killPercentage = attempts > 0 ? kills / attempts : 0.0;
    final totalPoints = kills + blocks + aces;

    return PlayerPerformance(
      playerId: map['player_id'] as String,
      playerName: map['player_name'] as String,
      jerseyNumber: (map['jersey_number'] as num?)?.toInt() ?? 0,
      kills: kills,
      errors: errors,
      attempts: attempts,
      attackEfficiency: attackEfficiency,
      killPercentage: killPercentage,
      blocks: blocks,
      aces: aces,
      totalPoints: totalPoints,
    );
  }

  factory PlayerPerformance.fromPlayerStats({
    required MatchPlayer player,
    required int kills,
    required int errors,
    required int attempts,
    required int blocks,
    required int aces,
  }) {
    final attackEfficiency = attempts > 0 ? (kills - errors) / attempts : 0.0;
    final killPercentage = attempts > 0 ? kills / attempts : 0.0;
    final totalPoints = kills + blocks + aces;

    return PlayerPerformance(
      playerId: player.id,
      playerName: player.name,
      jerseyNumber: player.jerseyNumber,
      kills: kills,
      errors: errors,
      attempts: attempts,
      attackEfficiency: attackEfficiency,
      killPercentage: killPercentage,
      blocks: blocks,
      aces: aces,
      totalPoints: totalPoints,
    );
  }
}

