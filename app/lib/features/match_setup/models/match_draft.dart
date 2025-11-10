class MatchDraft {
  const MatchDraft({
    required this.opponent,
    required this.matchDate,
    required this.location,
    required this.seasonLabel,
    required this.selectedPlayerIds,
    required this.startingRotation,
  });

  final String opponent;
  final DateTime? matchDate;
  final String location;
  final String seasonLabel;
  final Set<String> selectedPlayerIds;
  final Map<int, String> startingRotation;

  factory MatchDraft.initial() {
    return MatchDraft(
      opponent: '',
      matchDate: null,
      location: '',
      seasonLabel: '',
      selectedPlayerIds: <String>{},
      startingRotation: <int, String>{},
    );
  }

  bool get hasRotation =>
      startingRotation.length == 6 &&
      startingRotation.values.every((value) => value.isNotEmpty);

  factory MatchDraft.fromMap(Map<String, dynamic> map) {
    final rotation = <int, String>{};
    final rawRotation = map['starting_rotation'] ??
        map['startingRotation'] ??
        <String, dynamic>{};
    if (rawRotation is Map) {
      rawRotation.forEach((key, value) {
        final parsedKey = int.tryParse('$key');
        if (parsedKey != null && value is String) {
          rotation[parsedKey] = value;
        }
      });
    }

    final rawSelected = map['selected_player_ids'] ?? map['selectedPlayerIds'];
    final selectedPlayers = <String>{};
    if (rawSelected is List) {
      for (final entry in rawSelected) {
        if (entry is String) {
          selectedPlayers.add(entry);
        }
      }
    }

    return MatchDraft(
      opponent: (map['opponent'] as String?) ?? '',
      matchDate: map['match_date'] != null
          ? DateTime.tryParse(map['match_date'] as String)
          : map['matchDate'] != null
              ? DateTime.tryParse(map['matchDate'] as String)
              : null,
      location: (map['location'] as String?) ?? '',
      seasonLabel: (map['season_label'] as String?) ?? map['seasonLabel'] as String? ?? '',
      selectedPlayerIds: selectedPlayers,
      startingRotation: rotation,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'opponent': opponent,
      'match_date': matchDate?.toIso8601String(),
      'location': location,
      'season_label': seasonLabel,
      'selected_player_ids': selectedPlayerIds.toList(),
      'starting_rotation': {
        for (final entry in startingRotation.entries)
          entry.key.toString(): entry.value,
      },
    };
  }

  MatchDraft copyWith({
    String? opponent,
    DateTime? matchDate,
    String? location,
    String? seasonLabel,
    Set<String>? selectedPlayerIds,
    Map<int, String>? startingRotation,
  }) {
    return MatchDraft(
      opponent: opponent ?? this.opponent,
      matchDate: matchDate ?? this.matchDate,
      location: location ?? this.location,
      seasonLabel: seasonLabel ?? this.seasonLabel,
      selectedPlayerIds:
          selectedPlayerIds != null ? Set<String>.from(selectedPlayerIds) : this.selectedPlayerIds,
      startingRotation: startingRotation != null
          ? Map<int, String>.from(startingRotation)
          : this.startingRotation,
    );
  }

  @override
  String toString() {
    return 'MatchDraft(opponent: $opponent, matchDate: $matchDate, players: ${selectedPlayerIds.length})';
  }
}

