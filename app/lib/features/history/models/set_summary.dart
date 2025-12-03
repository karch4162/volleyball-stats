class SetSummary {
  SetSummary({
    required this.setNumber,
    required this.ourScore,
    required this.opponentScore,
    required this.rallyCount,
    required this.fbkCount,
    required this.transitionPoints,
    required this.isWin,
    this.duration,
  });

  final int setNumber;
  final int ourScore;
  final int opponentScore;
  final int rallyCount;
  final int fbkCount;
  final int transitionPoints;
  final bool isWin;
  final Duration? duration;

  factory SetSummary.fromMap(Map<String, dynamic> map) {
    Duration? duration;
    if (map['start_time'] != null && map['end_time'] != null) {
      final start = DateTime.parse(map['start_time'] as String);
      final end = DateTime.parse(map['end_time'] as String);
      duration = end.difference(start);
    }

    return SetSummary(
      setNumber: (map['set_number'] as num).toInt(),
      ourScore: (map['our_score'] as num?)?.toInt() ?? 0,
      opponentScore: (map['opponent_score'] as num?)?.toInt() ?? 0,
      rallyCount: (map['rally_count'] as num?)?.toInt() ?? 0,
      fbkCount: (map['fbk_count'] as num?)?.toInt() ?? 0,
      transitionPoints: (map['transition_points'] as num?)?.toInt() ?? 0,
      isWin: (map['result'] as String?) == 'win',
      duration: duration,
    );
  }
}

