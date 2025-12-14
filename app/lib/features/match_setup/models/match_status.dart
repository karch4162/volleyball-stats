/// Match completion status
enum MatchStatus {
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case MatchStatus.inProgress:
        return 'In Progress';
      case MatchStatus.completed:
        return 'Completed';
      case MatchStatus.cancelled:
        return 'Cancelled';
    }
  }

  String get value {
    switch (this) {
      case MatchStatus.inProgress:
        return 'in_progress';
      case MatchStatus.completed:
        return 'completed';
      case MatchStatus.cancelled:
        return 'cancelled';
    }
  }

  static MatchStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return MatchStatus.inProgress;
      case 'completed':
        return MatchStatus.completed;
      case 'cancelled':
        return MatchStatus.cancelled;
      default:
        return MatchStatus.inProgress;
    }
  }

  bool get isActive => this == MatchStatus.inProgress;
  bool get isComplete => this == MatchStatus.completed;
  bool get isCancelled => this == MatchStatus.cancelled;
}

/// Match completion data
class MatchCompletion {
  const MatchCompletion({
    required this.status,
    required this.completedAt,
    required this.finalScoreTeam,
    required this.finalScoreOpponent,
  });

  final MatchStatus status;
  final DateTime completedAt;
  final int finalScoreTeam;
  final int finalScoreOpponent;

  factory MatchCompletion.fromMap(Map<String, dynamic> map) {
    return MatchCompletion(
      status: MatchStatus.fromString((map['status'] as String?) ?? 'in_progress'),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : DateTime.now(),
      finalScoreTeam: (map['final_score_team'] as int?) ?? 0,
      finalScoreOpponent: (map['final_score_opponent'] as int?) ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.value,
      'completed_at': completedAt.toIso8601String(),
      'final_score_team': finalScoreTeam,
      'final_score_opponent': finalScoreOpponent,
    };
  }

  MatchCompletion copyWith({
    MatchStatus? status,
    DateTime? completedAt,
    int? finalScoreTeam,
    int? finalScoreOpponent,
  }) {
    return MatchCompletion(
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      finalScoreTeam: finalScoreTeam ?? this.finalScoreTeam,
      finalScoreOpponent: finalScoreOpponent ?? this.finalScoreOpponent,
    );
  }

  String get scoreDisplay => '$finalScoreTeam - $finalScoreOpponent';

  bool get teamWon => finalScoreTeam > finalScoreOpponent;
  bool get teamLost => finalScoreTeam < finalScoreOpponent;
  bool get isDraw => finalScoreTeam == finalScoreOpponent;
}
