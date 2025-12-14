import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_status.dart';

void main() {
  group('MatchStatus', () {
    test('fromString converts correctly', () {
      expect(MatchStatus.fromString('in_progress'), MatchStatus.inProgress);
      expect(MatchStatus.fromString('completed'), MatchStatus.completed);
      expect(MatchStatus.fromString('cancelled'), MatchStatus.cancelled);
    });

    test('fromString returns inProgress for invalid input', () {
      expect(MatchStatus.fromString('invalid'), MatchStatus.inProgress);
      expect(MatchStatus.fromString(''), MatchStatus.inProgress);
    });

    test('value returns correct string', () {
      expect(MatchStatus.inProgress.value, 'in_progress');
      expect(MatchStatus.completed.value, 'completed');
      expect(MatchStatus.cancelled.value, 'cancelled');
    });

    test('label returns display string', () {
      expect(MatchStatus.inProgress.label, 'In Progress');
      expect(MatchStatus.completed.label, 'Completed');
      expect(MatchStatus.cancelled.label, 'Cancelled');
    });

    test('isActive returns true for inProgress', () {
      expect(MatchStatus.inProgress.isActive, true);
      expect(MatchStatus.completed.isActive, false);
      expect(MatchStatus.cancelled.isActive, false);
    });

    test('isComplete returns true for completed', () {
      expect(MatchStatus.inProgress.isComplete, false);
      expect(MatchStatus.completed.isComplete, true);
      expect(MatchStatus.cancelled.isComplete, false);
    });

    test('round-trip conversion works', () {
      for (final status in MatchStatus.values) {
        final value = status.value;
        final parsed = MatchStatus.fromString(value);
        expect(parsed, equals(status));
      }
    });
  });

  group('MatchCompletion', () {
    test('creates with all required fields', () {
      final now = DateTime.now();
      final completion = MatchCompletion(
        status: MatchStatus.completed,
        completedAt: now,
        finalScoreTeam: 25,
        finalScoreOpponent: 20,
      );

      expect(completion.status, MatchStatus.completed);
      expect(completion.completedAt, now);
      expect(completion.finalScoreTeam, 25);
      expect(completion.finalScoreOpponent, 20);
    });

    test('copyWith updates status', () {
      final original = MatchCompletion(
        status: MatchStatus.inProgress,
        completedAt: DateTime.now(),
        finalScoreTeam: 20,
        finalScoreOpponent: 15,
      );

      final updated = original.copyWith(status: MatchStatus.completed);

      expect(updated.status, MatchStatus.completed);
      expect(updated.finalScoreTeam, 20);
    });

    test('copyWith updates timestamp', () {
      final now = DateTime.now();
      final later = now.add(const Duration(hours: 2));
      
      final original = MatchCompletion(
        status: MatchStatus.completed,
        completedAt: now,
        finalScoreTeam: 25,
        finalScoreOpponent: 20,
      );

      final updated = original.copyWith(completedAt: later);

      expect(updated.completedAt, later);
      expect(original.completedAt, now); // Original unchanged
    });

    test('copyWith updates scores', () {
      final original = MatchCompletion(
        status: MatchStatus.completed,
        completedAt: DateTime.now(),
        finalScoreTeam: 20,
        finalScoreOpponent: 15,
      );

      final updated = original.copyWith(
        finalScoreTeam: 25,
        finalScoreOpponent: 23,
      );

      expect(updated.finalScoreTeam, 25);
      expect(updated.finalScoreOpponent, 23);
      expect(original.finalScoreTeam, 20); // Original unchanged
    });

    test('toMap serializes correctly', () {
      final now = DateTime(2025, 12, 13, 10, 30);
      final completion = MatchCompletion(
        status: MatchStatus.completed,
        completedAt: now,
        finalScoreTeam: 25,
        finalScoreOpponent: 20,
      );

      final map = completion.toMap();

      expect(map['status'], 'completed');
      expect(map['completed_at'], contains('2025-12-13'));
      expect(map['final_score_team'], 25);
      expect(map['final_score_opponent'], 20);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'status': 'completed',
        'completed_at': '2025-12-13T10:30:00.000',
        'final_score_team': 25,
        'final_score_opponent': 20,
      };

      final completion = MatchCompletion.fromMap(map);

      expect(completion.status, MatchStatus.completed);
      expect(completion.completedAt.year, 2025);
      expect(completion.finalScoreTeam, 25);
      expect(completion.finalScoreOpponent, 20);
    });

    test('fromMap handles missing fields with defaults', () {
      final map = {
        'status': 'in_progress',
        // Missing other fields
      };

      final completion = MatchCompletion.fromMap(map);

      expect(completion.status, MatchStatus.inProgress);
      expect(completion.completedAt, isNotNull); // Defaults to now
      expect(completion.finalScoreTeam, 0); // Defaults to 0
      expect(completion.finalScoreOpponent, 0); // Defaults to 0
    });

    test('round-trip serialization works', () {
      final original = MatchCompletion(
        status: MatchStatus.completed,
        completedAt: DateTime(2025, 12, 13, 10, 30),
        finalScoreTeam: 25,
        finalScoreOpponent: 20,
      );

      final map = original.toMap();
      final deserialized = MatchCompletion.fromMap(map);

      expect(deserialized.status, original.status);
      expect(deserialized.finalScoreTeam, original.finalScoreTeam);
      expect(deserialized.finalScoreOpponent, original.finalScoreOpponent);
    });

    test('scoreDisplay formats score correctly', () {
      final completion = MatchCompletion(
        status: MatchStatus.completed,
        completedAt: DateTime.now(),
        finalScoreTeam: 25,
        finalScoreOpponent: 20,
      );

      expect(completion.scoreDisplay, '25 - 20');
    });

    test('teamWon returns true when team scores more', () {
      final completion = MatchCompletion(
        status: MatchStatus.completed,
        completedAt: DateTime.now(),
        finalScoreTeam: 25,
        finalScoreOpponent: 20,
      );

      expect(completion.teamWon, true);
      expect(completion.teamLost, false);
      expect(completion.isDraw, false);
    });

    test('teamLost returns true when opponent scores more', () {
      final completion = MatchCompletion(
        status: MatchStatus.completed,
        completedAt: DateTime.now(),
        finalScoreTeam: 20,
        finalScoreOpponent: 25,
      );

      expect(completion.teamWon, false);
      expect(completion.teamLost, true);
      expect(completion.isDraw, false);
    });

    test('isDraw returns true when scores equal', () {
      final completion = MatchCompletion(
        status: MatchStatus.completed,
        completedAt: DateTime.now(),
        finalScoreTeam: 25,
        finalScoreOpponent: 25,
      );

      expect(completion.teamWon, false);
      expect(completion.teamLost, false);
      expect(completion.isDraw, true);
    });
  });

  group('Match lifecycle transitions', () {
    test('in_progress -> completed transition', () {
      var completion = MatchCompletion(
        status: MatchStatus.inProgress,
        completedAt: DateTime.now(),
        finalScoreTeam: 0,
        finalScoreOpponent: 0,
      );

      // Complete the match
      completion = completion.copyWith(
        status: MatchStatus.completed,
        completedAt: DateTime.now(),
        finalScoreTeam: 25,
        finalScoreOpponent: 20,
      );

      expect(completion.status, MatchStatus.completed);
      expect(completion.completedAt, isNotNull);
      expect(completion.finalScoreTeam, 25);
    });

    test('in_progress -> cancelled transition', () {
      var completion = MatchCompletion(
        status: MatchStatus.inProgress,
        completedAt: DateTime.now(),
        finalScoreTeam: 0,
        finalScoreOpponent: 0,
      );

      // Cancel the match
      completion = completion.copyWith(
        status: MatchStatus.cancelled,
        completedAt: DateTime.now(),
      );

      expect(completion.status, MatchStatus.cancelled);
      expect(completion.completedAt, isNotNull);
    });

    test('can store partial score for cancelled match', () {
      final completion = MatchCompletion(
        status: MatchStatus.cancelled,
        completedAt: DateTime.now(),
        finalScoreTeam: 15,
        finalScoreOpponent: 10,
      );

      expect(completion.status, MatchStatus.cancelled);
      expect(completion.finalScoreTeam, 15);
      expect(completion.finalScoreOpponent, 10);
    });
  });
}
