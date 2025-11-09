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
    return const MatchDraft(
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

