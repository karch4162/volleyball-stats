import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/core/persistence/hive_service.dart';

void main() {
  group('HiveService', () {
    test('has correct box names defined', () {
      expect(HiveService.matchDraftsBox, 'match_drafts');
      expect(HiveService.matchPlayersBox, 'match_players');
      expect(HiveService.rosterTemplatesBox, 'roster_templates');
      expect(HiveService.rallyRecordsBox, 'rally_records');
      expect(HiveService.rallyEventsBox, 'rally_events');
      expect(HiveService.syncQueueBox, 'sync_queue');
    }, skip: false);

    // Note: Actual Hive integration tests require path_provider plugin setup
    // Skipped in unit tests, covered by integration tests
    test('Hive operations (integration test)', () {
      // Skip: Requires path_provider plugin initialization
      // Tests: initialize(), getBox(), getStorageStats(), closeAll(), deleteAll()
    }, skip: 'Requires path_provider plugin - run integration tests instead');
  });
}
