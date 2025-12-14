/// Represents an item in the sync queue waiting to be uploaded to Supabase
class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.type,
    required this.operation,
    required this.data,
    required this.createdAt,
    this.attempts = 0,
    this.lastAttempt,
    this.error,
  });

  final String id;
  final SyncItemType type;
  final SyncOperation operation;
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final int attempts;
  final DateTime? lastAttempt;
  final String? error;

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String,
      type: SyncItemType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SyncItemType.rally,
      ),
      operation: SyncOperation.values.firstWhere(
        (e) => e.name == map['operation'],
        orElse: () => SyncOperation.create,
      ),
      data: Map<String, dynamic>.from(map['data'] as Map),
      createdAt: DateTime.parse(map['createdAt'] as String),
      attempts: (map['attempts'] as num?)?.toInt() ?? 0,
      lastAttempt: map['lastAttempt'] != null
          ? DateTime.parse(map['lastAttempt'] as String)
          : null,
      error: map['error'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.name,
      'operation': operation.name,
      'data': data,
      'createdAt': createdAt.toIso8601String(),
      'attempts': attempts,
      if (lastAttempt != null) 'lastAttempt': lastAttempt!.toIso8601String(),
      if (error != null) 'error': error,
    };
  }

  SyncQueueItem copyWith({
    String? id,
    SyncItemType? type,
    SyncOperation? operation,
    Map<String, dynamic>? data,
    DateTime? createdAt,
    int? attempts,
    DateTime? lastAttempt,
    String? error,
  }) {
    return SyncQueueItem(
      id: id ?? this.id,
      type: type ?? this.type,
      operation: operation ?? this.operation,
      data: data ?? this.data,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
      lastAttempt: lastAttempt ?? this.lastAttempt,
      error: error ?? this.error,
    );
  }

  /// Increment attempt counter
  SyncQueueItem incrementAttempts(String? errorMessage) {
    return copyWith(
      attempts: attempts + 1,
      lastAttempt: DateTime.now(),
      error: errorMessage,
    );
  }

  /// Check if item should be retried
  bool shouldRetry({int maxAttempts = 3}) {
    return attempts < maxAttempts;
  }
}

enum SyncItemType {
  rally,
  matchDraft,
  player,
  rosterTemplate,
}

enum SyncOperation {
  create,
  update,
  delete,
}
