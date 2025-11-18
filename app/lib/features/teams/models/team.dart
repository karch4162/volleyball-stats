/// Team model representing a volleyball team
class Team {
  const Team({
    required this.id,
    required this.name,
    this.level,
    this.seasonLabel,
    required this.coachId,
  });

  final String id;
  final String name;
  final String? level;
  final String? seasonLabel;
  final String coachId;

  factory Team.fromMap(Map<String, dynamic> map) {
    return Team(
      id: map['id'] as String,
      name: map['name'] as String,
      level: map['level'] as String?,
      seasonLabel: map['season_label'] as String?,
      coachId: map['coach_id'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'level': level,
      'season_label': seasonLabel,
      'coach_id': coachId,
    };
  }

  Team copyWith({
    String? id,
    String? name,
    String? level,
    String? seasonLabel,
    String? coachId,
  }) {
    return Team(
      id: id ?? this.id,
      name: name ?? this.name,
      level: level ?? this.level,
      seasonLabel: seasonLabel ?? this.seasonLabel,
      coachId: coachId ?? this.coachId,
    );
  }
}

