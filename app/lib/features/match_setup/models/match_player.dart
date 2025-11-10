class MatchPlayer {
  const MatchPlayer({
    required this.id,
    required this.name,
    required this.jerseyNumber,
    required this.position,
  });

  final String id;
  final String name;
  final int jerseyNumber;
  final String position;

  factory MatchPlayer.fromMap(Map<String, dynamic> map) {
    return MatchPlayer(
      id: map['id'] as String,
      name: '${map['first_name'] ?? ''} ${map['last_name'] ?? ''}'.trim(),
      jerseyNumber: (map['jersey_number'] as num?)?.toInt() ?? 0,
      position: (map['position'] as String?) ?? '',
    );
  }
}

