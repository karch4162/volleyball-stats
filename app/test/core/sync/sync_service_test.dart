import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/core/sync/sync_queue_item.dart';

void main() {
  group('SyncQueueItem', () {
    test('creates with all required fields', () {
      final item = SyncQueueItem(
        id: 'item1',
        type: SyncItemType.matchDraft,
        operation: SyncOperation.create,
        data: {'key': 'value'},
        createdAt: DateTime(2025, 12, 13),
      );

      expect(item.id, 'item1');
      expect(item.type, SyncItemType.matchDraft);
      expect(item.operation, SyncOperation.create);
      expect(item.data['key'], 'value');
      expect(item.attempts, 0);
      expect(item.lastAttempt, isNull);
    });

    test('creates with attempt information', () {
      final lastAttempt = DateTime(2025, 12, 13, 10, 0);
      final item = SyncQueueItem(
        id: 'item1',
        type: SyncItemType.rally,
        operation: SyncOperation.update,
        data: {},
        createdAt: DateTime(2025, 12, 13, 9, 0),
        attempts: 3,
        lastAttempt: lastAttempt,
      );

      expect(item.attempts, 3);
      expect(item.lastAttempt, lastAttempt);
    });

    test('copyWith updates attempts', () {
      final original = SyncQueueItem(
        id: 'item1',
        type: SyncItemType.matchDraft,
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.now(),
      );

      final updated = original.copyWith(attempts: 2);

      expect(updated.attempts, 2);
      expect(original.attempts, 0);
    });

    test('copyWith updates lastAttempt', () {
      final now = DateTime.now();
      final later = now.add(const Duration(minutes: 5));
      
      final original = SyncQueueItem(
        id: 'item1',
        type: SyncItemType.rally,
        operation: SyncOperation.create,
        data: {},
        createdAt: now,
      );

      final updated = original.copyWith(lastAttempt: later);

      expect(updated.lastAttempt, later);
      expect(original.lastAttempt, isNull);
    });

    test('toMap serializes correctly', () {
      final item = SyncQueueItem(
        id: 'item1',
        type: SyncItemType.matchDraft,
        operation: SyncOperation.create,
        data: {'field': 'value'},
        createdAt: DateTime(2025, 12, 13, 10, 30),
        attempts: 2,
        lastAttempt: DateTime(2025, 12, 13, 10, 35),
      );

      final map = item.toMap();

      expect(map['id'], 'item1');
      expect(map['type'], 'matchDraft');
      expect(map['operation'], 'create');
      expect(map['data']['field'], 'value');
      expect(map['attempts'], 2);
      expect(map['createdAt'], contains('2025-12-13'));
      expect(map['lastAttempt'], contains('2025-12-13'));
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'id': 'item1',
        'type': 'rally',
        'operation': 'update',
        'data': {'field': 'value'},
        'createdAt': '2025-12-13T10:30:00.000',
        'attempts': 3,
        'lastAttempt': '2025-12-13T10:35:00.000',
      };

      final item = SyncQueueItem.fromMap(map);

      expect(item.id, 'item1');
      expect(item.type, SyncItemType.rally);
      expect(item.operation, SyncOperation.update);
      expect(item.data['field'], 'value');
      expect(item.attempts, 3);
      expect(item.lastAttempt, isNotNull);
    });

    test('round-trip serialization works', () {
      final original = SyncQueueItem(
        id: 'item1',
        type: SyncItemType.matchDraft,
        operation: SyncOperation.create,
        data: {'key': 'value'},
        createdAt: DateTime(2025, 12, 13),
        attempts: 2,
      );

      final map = original.toMap();
      final deserialized = SyncQueueItem.fromMap(map);

      expect(deserialized.id, original.id);
      expect(deserialized.type, original.type);
      expect(deserialized.operation, original.operation);
      expect(deserialized.attempts, original.attempts);
    });

    test('incrementAttempts increases counter', () {
      final item = SyncQueueItem(
        id: 'item1',
        type: SyncItemType.rally,
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.now(),
      );

      final updated = item.incrementAttempts('Network error');

      expect(updated.attempts, 1);
      expect(updated.lastAttempt, isNotNull);
      expect(updated.error, 'Network error');
    });

    test('shouldRetry returns true when below max attempts', () {
      final item = SyncQueueItem(
        id: 'item1',
        type: SyncItemType.rally,
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.now(),
        attempts: 2,
      );

      expect(item.shouldRetry(maxAttempts: 3), true);
    });

    test('shouldRetry returns false when at max attempts', () {
      final item = SyncQueueItem(
        id: 'item1',
        type: SyncItemType.rally,
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.now(),
        attempts: 3,
      );

      expect(item.shouldRetry(maxAttempts: 3), false);
    });
  });

  group('SyncItemType', () {
    test('all types have unique string values', () {
      final types = SyncItemType.values;
      final strings = types.map((t) => t.name).toSet();
      expect(strings.length, equals(types.length));
    });

    test('matchDraft type exists', () {
      expect(SyncItemType.values, contains(SyncItemType.matchDraft));
    });

    test('rally type exists', () {
      expect(SyncItemType.values, contains(SyncItemType.rally));
    });

    test('player type exists', () {
      expect(SyncItemType.values, contains(SyncItemType.player));
    });

    test('rosterTemplate type exists', () {
      expect(SyncItemType.values, contains(SyncItemType.rosterTemplate));
    });
  });

  group('SyncOperation', () {
    test('all operations have unique string values', () {
      final operations = SyncOperation.values;
      final strings = operations.map((o) => o.name).toSet();
      expect(strings.length, equals(operations.length));
    });

    test('create operation exists', () {
      expect(SyncOperation.values, contains(SyncOperation.create));
    });

    test('update operation exists', () {
      expect(SyncOperation.values, contains(SyncOperation.update));
    });

    test('delete operation exists', () {
      expect(SyncOperation.values, contains(SyncOperation.delete));
    });
  });

  group('Retry logic scenarios', () {
    test('incrementAttempts workflow', () {
      var item = SyncQueueItem(
        id: 'item1',
        type: SyncItemType.matchDraft,
        operation: SyncOperation.create,
        data: {},
        createdAt: DateTime.now(),
      );

      expect(item.attempts, 0);
      expect(item.shouldRetry(), true);

      // First attempt fails
      item = item.incrementAttempts('Network timeout');
      expect(item.attempts, 1);
      expect(item.shouldRetry(), true);

      // Second attempt fails
      item = item.incrementAttempts('Server error');
      expect(item.attempts, 2);
      expect(item.shouldRetry(), true);

      // Third attempt fails
      item = item.incrementAttempts('Connection refused');
      expect(item.attempts, 3);
      expect(item.shouldRetry(), false); // Max retries reached
    });

    test('creates queue item for new match draft', () {
      final item = SyncQueueItem(
        id: 'draft_123',
        type: SyncItemType.matchDraft,
        operation: SyncOperation.create,
        data: {
          'opponent': 'Test Team',
          'match_date': '2025-12-13',
        },
        createdAt: DateTime.now(),
      );

      expect(item.type, SyncItemType.matchDraft);
      expect(item.operation, SyncOperation.create);
      expect(item.data['opponent'], 'Test Team');
    });

    test('creates queue item for rally update', () {
      final item = SyncQueueItem(
        id: 'rally_456',
        type: SyncItemType.rally,
        operation: SyncOperation.update,
        data: {
          'rallyId': 'rally_456',
          'rotationNumber': 3,
        },
        createdAt: DateTime.now(),
      );

      expect(item.type, SyncItemType.rally);
      expect(item.operation, SyncOperation.update);
      expect(item.data['rotationNumber'], 3);
    });

    test('creates queue item for player deletion', () {
      final item = SyncQueueItem(
        id: 'player_789',
        type: SyncItemType.player,
        operation: SyncOperation.delete,
        data: {'id': 'player_789'},
        createdAt: DateTime.now(),
      );

      expect(item.type, SyncItemType.player);
      expect(item.operation, SyncOperation.delete);
    });
  });
}
