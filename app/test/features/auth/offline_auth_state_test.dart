import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:volleyball_stats_app/features/auth/offline_auth_state.dart';

void main() {
  group('OfflineAuthState', () {
    test('creates with all fields', () {
      final state = OfflineAuthState(
        isOfflineMode: true,
        cachedUserId: 'user123',
        cachedUserEmail: 'test@example.com',
        lastSignedInAt: DateTime(2025, 12, 13),
      );

      expect(state.isOfflineMode, true);
      expect(state.cachedUserId, 'user123');
      expect(state.cachedUserEmail, 'test@example.com');
      expect(state.lastSignedInAt?.year, 2025);
    });

    test('anonymous factory creates offline user', () {
      final state = OfflineAuthState.anonymous();

      expect(state.isOfflineMode, true);
      expect(state.cachedUserId, 'offline_user');
      expect(state.cachedUserEmail, 'offline@local');
    });

    test('hasCache returns true when both userId and email present', () {
      const state = OfflineAuthState(
        isOfflineMode: false,
        cachedUserId: 'user123',
        cachedUserEmail: 'user@example.com',
      );

      expect(state.hasCache, true);
    });

    test('hasCache returns false when userId absent', () {
      const state = OfflineAuthState(
        isOfflineMode: false,
      );

      expect(state.hasCache, false);
    });

    test('hasCache returns false when only userId present', () {
      const state = OfflineAuthState(
        isOfflineMode: false,
        cachedUserId: 'user123',
      );

      expect(state.hasCache, false); // Needs both userId AND email
    });

    test('copyWith updates isOfflineMode', () {
      const original = OfflineAuthState(isOfflineMode: false);
      final updated = original.copyWith(isOfflineMode: true);

      expect(updated.isOfflineMode, true);
      expect(original.isOfflineMode, false);
    });

    test('copyWith updates cachedUserId', () {
      const original = OfflineAuthState(isOfflineMode: false, cachedUserId: 'user1');
      final updated = original.copyWith(cachedUserId: 'user2');

      expect(updated.cachedUserId, 'user2');
      expect(original.cachedUserId, 'user1');
    });

    test('toMap serializes correctly', () {
      final state = OfflineAuthState(
        isOfflineMode: true,
        cachedUserId: 'user123',
        cachedUserEmail: 'test@example.com',
        lastSignedInAt: DateTime(2025, 12, 13, 10, 30),
      );

      final map = state.toMap();

      expect(map['is_offline_mode'], true);
      expect(map['cached_user_id'], 'user123');
      expect(map['cached_user_email'], 'test@example.com');
      expect(map['last_signed_in_at'], contains('2025-12-13'));
    });

    test('toMap handles null fields', () {
      const state = OfflineAuthState(isOfflineMode: false);

      final map = state.toMap();

      expect(map['is_offline_mode'], false);
      expect(map.containsKey('cached_user_id'), false);
      expect(map.containsKey('cached_user_email'), false);
      expect(map.containsKey('last_signed_in_at'), false);
    });

    test('fromMap deserializes correctly', () {
      final map = {
        'is_offline_mode': true,
        'cached_user_id': 'user123',
        'cached_user_email': 'test@example.com',
        'last_signed_in_at': '2025-12-13T10:30:00.000',
      };

      final state = OfflineAuthState.fromMap(map);

      expect(state.isOfflineMode, true);
      expect(state.cachedUserId, 'user123');
      expect(state.cachedUserEmail, 'test@example.com');
      expect(state.lastSignedInAt?.year, 2025);
    });

    test('fromMap handles missing optional fields', () {
      final map = {
        'is_offline_mode': false,
      };

      final state = OfflineAuthState.fromMap(map);

      expect(state.isOfflineMode, false);
      expect(state.cachedUserId, isNull);
      expect(state.cachedUserEmail, isNull);
      expect(state.lastSignedInAt, isNull);
    });

    test('round-trip serialization works', () {
      final original = OfflineAuthState(
        isOfflineMode: true,
        cachedUserId: 'user123',
        cachedUserEmail: 'test@example.com',
        lastSignedInAt: DateTime(2025, 12, 13),
      );

      final map = original.toMap();
      final deserialized = OfflineAuthState.fromMap(map);

      expect(deserialized.isOfflineMode, original.isOfflineMode);
      expect(deserialized.cachedUserId, original.cachedUserId);
      expect(deserialized.cachedUserEmail, original.cachedUserEmail);
    });
  });

  group('OfflineAuthService', () {
    // Note: Hive-dependent tests skipped due to platform dependencies
    // These would require proper test setup with path_provider mocking

    test('service methods (integration test)', () {
      // Skip: Requires path_provider plugin - run integration tests instead
      // Tests: loadOfflineState(), saveOfflineState(), cacheUserSession(),
      //        enableOfflineMode(), clearOfflineState()
    }, skip: 'Requires path_provider plugin - run integration tests instead');
  });
}
