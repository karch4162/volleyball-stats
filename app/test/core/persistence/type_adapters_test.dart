import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/core/persistence/type_adapters.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_draft.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart';
import 'package:volleyball_stats_app/features/match_setup/models/roster_template.dart';
import 'package:volleyball_stats_app/features/rally_capture/models/rally_models.dart';

void main() {
  group('ModelSerializer', () {
    group('MatchDraft serialization', () {
      test('toMap serializes MatchDraft correctly', () {
        final draft = MatchDraft(
          opponent: 'Test Team',
          matchDate: DateTime(2025, 12, 13),
          location: 'Test Gym',
          seasonLabel: '2025 Season',
          selectedPlayerIds: {'player1', 'player2'},
          startingRotation: {1: 'player1', 2: 'player2'},
        );

        final map = ModelSerializer.matchDraftToMap(draft);

        expect(map['opponent'], equals('Test Team'));
        expect(map['match_date'], contains('2025-12-13'));
        expect(map['location'], equals('Test Gym'));
        expect(map['season_label'], equals('2025 Season'));
        expect(map['selected_player_ids'], equals(['player1', 'player2']));
        expect(map['starting_rotation']['1'], equals('player1'));
      });

      test('fromMap deserializes MatchDraft correctly', () {
        final map = {
          'opponent': 'Test Team',
          'match_date': '2025-12-13T10:00:00.000',
          'location': 'Test Gym',
          'season_label': '2025 Season',
          'selected_player_ids': ['player1', 'player2'],
          'starting_rotation': {'1': 'player1', '2': 'player2'},
        };

        final draft = ModelSerializer.matchDraftFromMap(map);

        expect(draft.opponent, equals('Test Team'));
        expect(draft.matchDate?.year, equals(2025));
        expect(draft.location, equals('Test Gym'));
        expect(draft.seasonLabel, equals('2025 Season'));
        expect(draft.selectedPlayerIds, containsAll(['player1', 'player2']));
        expect(draft.startingRotation[1], equals('player1'));
      });
    });

    group('MatchPlayer serialization', () {
      test('toMap serializes MatchPlayer correctly', () {
        final player = const MatchPlayer(
          id: 'p1',
          name: 'John Doe',
          jerseyNumber: 12,
          position: 'OH',
        );

        final map = ModelSerializer.matchPlayerToMap(player);

        expect(map['id'], equals('p1'));
        expect(map['first_name'], equals('John'));
        expect(map['last_name'], equals('Doe'));
        expect(map['jersey_number'], equals(12));
        expect(map['position'], equals('OH'));
      });

      test('fromMap deserializes MatchPlayer correctly', () {
        final map = {
          'id': 'p1',
          'first_name': 'John',
          'last_name': 'Doe',
          'jersey_number': 12,
          'position': 'OH',
        };

        final player = ModelSerializer.matchPlayerFromMap(map);

        expect(player.id, equals('p1'));
        expect(player.name, equals('John Doe'));
        expect(player.jerseyNumber, equals(12));
        expect(player.position, equals('OH'));
      });
    });

    group('RallyEvent serialization', () {
      test('toMap serializes RallyEvent correctly', () {
        final player = const MatchPlayer(
          id: 'p1',
          name: 'John Doe',
          jerseyNumber: 12,
          position: 'OH',
        );
        
        final event = RallyEvent(
          id: 'e1',
          type: RallyActionTypes.attackKill,
          timestamp: DateTime(2025, 12, 13, 10, 30),
          player: player,
          note: 'Great hit',
        );

        final map = ModelSerializer.rallyEventToMap(event);

        expect(map['id'], equals('e1'));
        expect(map['type'], equals('attackKill'));
        expect(map['timestamp'], contains('2025-12-13'));
        expect(map['player']['id'], equals('p1'));
        expect(map['note'], equals('Great hit'));
      });

      test('fromMap deserializes RallyEvent correctly', () {
        final map = {
          'id': 'e1',
          'type': 'attackKill',
          'timestamp': '2025-12-13T10:30:00.000',
          'player': {
            'id': 'p1',
            'first_name': 'John',
            'last_name': 'Doe',
            'jersey_number': 12,
            'position': 'OH',
          },
          'note': 'Great hit',
        };

        final event = ModelSerializer.rallyEventFromMap(map);

        expect(event.id, equals('e1'));
        expect(event.type, equals(RallyActionTypes.attackKill));
        expect(event.timestamp.year, equals(2025));
        expect(event.player?.id, equals('p1'));
        expect(event.note, equals('Great hit'));
      });
    });

    group('RallyRecord serialization', () {
      test('toMap serializes RallyRecord with rotation', () {
        final event = RallyEvent(
          id: 'e1',
          type: RallyActionTypes.attackKill,
          timestamp: DateTime(2025, 12, 13, 10, 30),
        );
        
        final record = RallyRecord(
          rallyId: 'r1',
          rallyNumber: 5,
          rotationNumber: 3,
          events: [event],
          completedAt: DateTime(2025, 12, 13, 10, 31),
        );

        final map = ModelSerializer.rallyRecordToMap(record);

        expect(map['rallyId'], equals('r1'));
        expect(map['rallyNumber'], equals(5));
        expect(map['rotationNumber'], equals(3));
        expect(map['events'], hasLength(1));
        expect(map['completedAt'], contains('2025-12-13'));
      });

      test('fromMap deserializes RallyRecord with rotation', () {
        final map = {
          'rallyId': 'r1',
          'rallyNumber': 5,
          'rotationNumber': 3,
          'events': [
            {
              'id': 'e1',
              'type': 'attackKill',
              'timestamp': '2025-12-13T10:30:00.000',
            }
          ],
          'completedAt': '2025-12-13T10:31:00.000',
        };

        final record = ModelSerializer.rallyRecordFromMap(map);

        expect(record.rallyId, equals('r1'));
        expect(record.rallyNumber, equals(5));
        expect(record.rotationNumber, equals(3));
        expect(record.events, hasLength(1));
        expect(record.completedAt.year, equals(2025));
      });

      test('fromMap defaults rotation to 1 if missing', () {
        final map = {
          'rallyId': 'r1',
          'rallyNumber': 5,
          // rotationNumber missing
          'events': [],
          'completedAt': '2025-12-13T10:31:00.000',
        };

        final record = ModelSerializer.rallyRecordFromMap(map);

        expect(record.rotationNumber, equals(1));
      });
    });

    group('RallyCaptureSession serialization', () {
      test('toMap serializes session with rotation', () {
        final session = RallyCaptureSession.initial(
          matchId: 'm1',
          setId: 's1',
          currentSetNumber: 2,
          currentRotation: 4,
        );

        final map = ModelSerializer.rallyCaptureSessionToMap(session);

        expect(map['matchId'], equals('m1'));
        expect(map['setId'], equals('s1'));
        expect(map['currentSetNumber'], equals(2));
        expect(map['currentRallyNumber'], equals(1));
        expect(map['currentRotation'], equals(4));
        expect(map['currentEvents'], isEmpty);
        expect(map['completedRallies'], isEmpty);
      });

      test('fromMap deserializes session with rotation', () {
        final map = {
          'matchId': 'm1',
          'setId': 's1',
          'currentSetNumber': 2,
          'currentRallyNumber': 3,
          'currentRotation': 4,
          'currentEvents': [],
          'completedRallies': [],
          'canUndo': false,
          'canRedo': false,
        };

        final session = ModelSerializer.rallyCaptureSessionFromMap(map);

        expect(session.matchId, equals('m1'));
        expect(session.setId, equals('s1'));
        expect(session.currentSetNumber, equals(2));
        expect(session.currentRallyNumber, equals(3));
        expect(session.currentRotation, equals(4));
      });
    });
  });
}
