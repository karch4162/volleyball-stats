class RosterTemplate {
  const RosterTemplate({
    required this.id,
    required this.name,
    this.description,
    required this.playerIds,
    this.defaultRotation = const {},
    required this.createdAt,
    this.lastUsedAt,
    this.useCount = 0,
  });

  final String id;
  final String name;
  final String? description;
  final Set<String> playerIds; // Selected players
  final Map<int, String> defaultRotation; // Optional: default rotation (position -> playerId)
  final DateTime createdAt;
  final DateTime? lastUsedAt;
  final int useCount; // Track frequency for sorting

  /// Note: Templates include ONLY roster and rotation, NOT match metadata
  /// (opponent, date, location are tracked separately per match)

  factory RosterTemplate.fromMap(Map<String, dynamic> map) {
    final rawPlayerIds = map['player_ids'] ?? map['playerIds'] ?? <dynamic>[];
    final playerIds = <String>{};
    if (rawPlayerIds is List) {
      for (final entry in rawPlayerIds) {
        if (entry is String) {
          playerIds.add(entry);
        }
      }
    }

    final rawRotation = map['default_rotation'] ?? map['defaultRotation'] ?? <String, dynamic>{};
    final rotation = <int, String>{};
    if (rawRotation is Map) {
      rawRotation.forEach((key, value) {
        final parsedKey = int.tryParse('$key');
        if (parsedKey != null && value is String) {
          rotation[parsedKey] = value;
        }
      });
    }

    return RosterTemplate(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      description: map['description'] as String?,
      playerIds: playerIds,
      defaultRotation: rotation,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : map['createdAt'] != null
              ? DateTime.tryParse(map['createdAt'] as String) ?? DateTime.now()
              : DateTime.now(),
      lastUsedAt: map['last_used_at'] != null
          ? DateTime.tryParse(map['last_used_at'] as String)
          : map['lastUsedAt'] != null
              ? DateTime.tryParse(map['lastUsedAt'] as String)
              : null,
      useCount: (map['use_count'] as int?) ?? map['useCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      'player_ids': playerIds.toList(),
      'default_rotation': {
        for (final entry in defaultRotation.entries)
          entry.key.toString(): entry.value,
      },
      'created_at': createdAt.toIso8601String(),
      if (lastUsedAt != null) 'last_used_at': lastUsedAt!.toIso8601String(),
      'use_count': useCount,
    };
  }

  RosterTemplate copyWith({
    String? id,
    String? name,
    String? description,
    Set<String>? playerIds,
    Map<int, String>? defaultRotation,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? useCount,
  }) {
    return RosterTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      playerIds: playerIds != null ? Set<String>.from(playerIds) : this.playerIds,
      defaultRotation: defaultRotation != null
          ? Map<int, String>.from(defaultRotation)
          : this.defaultRotation,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
    );
  }

  /// Increment usage tracking
  RosterTemplate markUsed() {
    return copyWith(
      lastUsedAt: DateTime.now(),
      useCount: useCount + 1,
    );
  }

  @override
  String toString() {
    return 'RosterTemplate(id: $id, name: $name, players: ${playerIds.length}, rotation: ${defaultRotation.length})';
  }
}

