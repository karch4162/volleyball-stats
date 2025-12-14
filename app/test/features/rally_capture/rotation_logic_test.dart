import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/features/rally_capture/models/rally_models.dart';

void main() {
  group('Rotation Logic', () {
    group('RallyActionTypes.isPointScoring', () {
      test('returns true for point-scoring actions', () {
        expect(RallyActionTypes.serveAce.isPointScoring, true);
        expect(RallyActionTypes.firstBallKill.isPointScoring, true);
        expect(RallyActionTypes.attackKill.isPointScoring, true);
        expect(RallyActionTypes.block.isPointScoring, true);
      });

      test('returns false for non-point-scoring actions', () {
        expect(RallyActionTypes.serveError.isPointScoring, false);
        expect(RallyActionTypes.attackError.isPointScoring, false);
        expect(RallyActionTypes.attackAttempt.isPointScoring, false);
        expect(RallyActionTypes.dig.isPointScoring, false);
        expect(RallyActionTypes.assist.isPointScoring, false);
        expect(RallyActionTypes.timeout.isPointScoring, false);
        expect(RallyActionTypes.substitution.isPointScoring, false);
      });
    });

    group('RallyActionTypes.isError', () {
      test('returns true for error actions', () {
        expect(RallyActionTypes.serveError.isError, true);
        expect(RallyActionTypes.attackError.isError, true);
      });

      test('returns false for non-error actions', () {
        expect(RallyActionTypes.serveAce.isError, false);
        expect(RallyActionTypes.attackKill.isError, false);
        expect(RallyActionTypes.block.isError, false);
        expect(RallyActionTypes.dig.isError, false);
      });
    });

    group('RallyCaptureSession rotation tracking', () {
      test('initial session has rotation 1', () {
        final session = RallyCaptureSession.initial(
          matchId: 'm1',
          setId: 's1',
        );

        expect(session.currentRotation, equals(1));
      });

      test('can initialize with specific rotation', () {
        final session = RallyCaptureSession.initial(
          matchId: 'm1',
          setId: 's1',
          currentRotation: 4,
        );

        expect(session.currentRotation, equals(4));
      });

      test('copyWith updates rotation', () {
        final session = RallyCaptureSession.initial(
          matchId: 'm1',
          setId: 's1',
          currentRotation: 2,
        );

        final updated = session.copyWith(currentRotation: 5);

        expect(updated.currentRotation, equals(5));
        expect(session.currentRotation, equals(2)); // Original unchanged
      });
    });

    group('RallyRecord stores rotation', () {
      test('rally record includes rotation number', () {
        final record = RallyRecord(
          rallyId: 'r1',
          rallyNumber: 5,
          rotationNumber: 3,
          events: [],
          completedAt: DateTime.now(),
        );

        expect(record.rotationNumber, equals(3));
      });

      test('rally record copyWith updates rotation', () {
        final record = RallyRecord(
          rallyId: 'r1',
          rallyNumber: 5,
          rotationNumber: 3,
          events: [],
          completedAt: DateTime.now(),
        );

        final updated = record.copyWith(rotationNumber: 6);

        expect(updated.rotationNumber, equals(6));
        expect(record.rotationNumber, equals(3)); // Original unchanged
      });
    });

    group('Rotation advancement logic simulation', () {
      // These tests simulate the _advanceRotation logic from providers.dart
      int advanceRotation(int current) {
        return (current % 6) + 1;
      }

      test('advances from 1 to 2', () {
        expect(advanceRotation(1), equals(2));
      });

      test('advances from 2 to 3', () {
        expect(advanceRotation(2), equals(3));
      });

      test('advances from 5 to 6', () {
        expect(advanceRotation(5), equals(6));
      });

      test('wraps from 6 to 1', () {
        expect(advanceRotation(6), equals(1));
      });

      test('advances through full cycle', () {
        int rotation = 1;
        rotation = advanceRotation(rotation);
        expect(rotation, equals(2));
        rotation = advanceRotation(rotation);
        expect(rotation, equals(3));
        rotation = advanceRotation(rotation);
        expect(rotation, equals(4));
        rotation = advanceRotation(rotation);
        expect(rotation, equals(5));
        rotation = advanceRotation(rotation);
        expect(rotation, equals(6));
        rotation = advanceRotation(rotation);
        expect(rotation, equals(1)); // Back to start
      });
    });

    group('Win/loss determination logic simulation', () {
      // Simulates the _didWinRally logic from providers.dart
      bool didWinRally(List<RallyEvent> events) {
        if (events.isEmpty) return false;
        
        final hasPointScoring = events.any((e) => e.type.isPointScoring);
        final hasError = events.any((e) => e.type.isError);
        
        return hasPointScoring && !hasError;
      }

      test('returns false for empty events', () {
        expect(didWinRally([]), false);
      });

      test('returns true for attack kill only', () {
        final events = [
          RallyEvent(
            id: 'e1',
            type: RallyActionTypes.attackKill,
            timestamp: DateTime.now(),
          ),
        ];

        expect(didWinRally(events), true);
      });

      test('returns false for attack error only', () {
        final events = [
          RallyEvent(
            id: 'e1',
            type: RallyActionTypes.attackError,
            timestamp: DateTime.now(),
          ),
        ];

        expect(didWinRally(events), false);
      });

      test('returns false for attack kill + error (error overrides)', () {
        final events = [
          RallyEvent(
            id: 'e1',
            type: RallyActionTypes.attackKill,
            timestamp: DateTime.now(),
          ),
          RallyEvent(
            id: 'e2',
            type: RallyActionTypes.attackError,
            timestamp: DateTime.now(),
          ),
        ];

        expect(didWinRally(events), false);
      });

      test('returns true for serve ace', () {
        final events = [
          RallyEvent(
            id: 'e1',
            type: RallyActionTypes.serveAce,
            timestamp: DateTime.now(),
          ),
        ];

        expect(didWinRally(events), true);
      });

      test('returns false for serve error', () {
        final events = [
          RallyEvent(
            id: 'e1',
            type: RallyActionTypes.serveError,
            timestamp: DateTime.now(),
          ),
        ];

        expect(didWinRally(events), false);
      });

      test('returns true for first ball kill', () {
        final events = [
          RallyEvent(
            id: 'e1',
            type: RallyActionTypes.firstBallKill,
            timestamp: DateTime.now(),
          ),
        ];

        expect(didWinRally(events), true);
      });

      test('returns true for block', () {
        final events = [
          RallyEvent(
            id: 'e1',
            type: RallyActionTypes.block,
            timestamp: DateTime.now(),
          ),
        ];

        expect(didWinRally(events), true);
      });

      test('returns false for dig only (no scoring)', () {
        final events = [
          RallyEvent(
            id: 'e1',
            type: RallyActionTypes.dig,
            timestamp: DateTime.now(),
          ),
        ];

        expect(didWinRally(events), false);
      });

      test('returns true for complex winning rally', () {
        final events = [
          RallyEvent(
            id: 'e1',
            type: RallyActionTypes.dig,
            timestamp: DateTime.now(),
          ),
          RallyEvent(
            id: 'e2',
            type: RallyActionTypes.assist,
            timestamp: DateTime.now(),
          ),
          RallyEvent(
            id: 'e3',
            type: RallyActionTypes.attackKill,
            timestamp: DateTime.now(),
          ),
        ];

        expect(didWinRally(events), true);
      });
    });
  });
}

