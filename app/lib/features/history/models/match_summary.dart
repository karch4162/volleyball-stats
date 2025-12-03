class MatchSummary {
  MatchSummary({
    required this.matchId,
    required this.opponent,
    required this.matchDate,
    required this.location,
    required this.setsWon,
    required this.setsLost,
    required this.totalRallies,
    required this.totalFBK,
    required this.totalTransitionPoints,
    required this.isWin,
    this.seasonLabel,
  });

  final String matchId;
  final String opponent;
  final DateTime matchDate;
  final String location;
  final int setsWon;
  final int setsLost;
  final int totalRallies;
  final int totalFBK;
  final int totalTransitionPoints;
  final bool isWin;
  final String? seasonLabel;

  factory MatchSummary.fromMap(Map<String, dynamic> map) {
    return MatchSummary(
      matchId: map['id'] as String,
      opponent: map['opponent'] as String,
      matchDate: DateTime.parse(map['match_date'] as String),
      location: (map['location'] as String?) ?? '',
      setsWon: (map['sets_won'] as num?)?.toInt() ?? 0,
      setsLost: (map['sets_lost'] as num?)?.toInt() ?? 0,
      totalRallies: (map['total_rallies'] as num?)?.toInt() ?? 0,
      totalFBK: (map['total_fbk'] as num?)?.toInt() ?? 0,
      totalTransitionPoints: (map['total_transition_points'] as num?)?.toInt() ?? 0,
      isWin: (map['is_win'] as bool?) ?? false,
      seasonLabel: map['season_label'] as String?,
    );
  }
}

