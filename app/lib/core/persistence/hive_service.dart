import 'package:hive_flutter/hive_flutter.dart';
import '../utils/logger.dart';
import 'type_adapters.dart';

final _logger = createLogger('HiveService');

/// Central service for initializing and managing Hive boxes
class HiveService {
  static const String matchDraftsBox = 'match_drafts';
  static const String matchPlayersBox = 'match_players';
  static const String rosterTemplatesBox = 'roster_templates';
  static const String rallyRecordsBox = 'rally_records';
  static const String rallyEventsBox = 'rally_events';
  static const String syncQueueBox = 'sync_queue';

  static bool _initialized = false;

  /// Initialize Hive and register all type adapters
  static Future<void> initialize() async {
    if (_initialized) {
      _logger.i('Hive already initialized');
      return;
    }

    try {
      _logger.i('Initializing Hive...');
      
      // Initialize Hive for Flutter
      await Hive.initFlutter();

      // Register type adapters
      Hive.registerAdapter(MatchDraftAdapter());
      Hive.registerAdapter(MatchPlayerAdapter());
      Hive.registerAdapter(RosterTemplateAdapter());
      Hive.registerAdapter(RallyEventAdapter());
      Hive.registerAdapter(RallyRecordAdapter());
      Hive.registerAdapter(RallyCaptureSessionAdapter());
      Hive.registerAdapter(SyncQueueItemAdapter());
      
      _logger.i('Type adapters registered');

      // Open boxes
      await Future.wait([
        Hive.openBox<Map>(matchDraftsBox),
        Hive.openBox<Map>(matchPlayersBox),
        Hive.openBox<Map>(rosterTemplatesBox),
        Hive.openBox<Map>(rallyRecordsBox),
        Hive.openBox<Map>(rallyEventsBox),
        Hive.openBox<Map>(syncQueueBox),
      ]);

      _initialized = true;
      _logger.i('Hive initialization complete - all boxes opened');
    } catch (e, st) {
      _logger.e('Failed to initialize Hive', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Get a box by name
  static Box<Map> getBox(String boxName) {
    if (!_initialized) {
      throw StateError('HiveService not initialized. Call initialize() first.');
    }
    return Hive.box<Map>(boxName);
  }

  /// Close all boxes (useful for testing or cleanup)
  static Future<void> closeAll() async {
    await Hive.close();
    _initialized = false;
    _logger.i('All Hive boxes closed');
  }

  /// Delete all data (useful for testing or reset)
  static Future<void> deleteAll() async {
    try {
      await Hive.deleteFromDisk();
      _initialized = false;
      _logger.w('All Hive data deleted');
    } catch (e, st) {
      _logger.e('Failed to delete Hive data', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Get statistics about storage usage
  static Map<String, int> getStorageStats() {
    if (!_initialized) {
      return {};
    }

    return {
      matchDraftsBox: Hive.box<Map>(matchDraftsBox).length,
      matchPlayersBox: Hive.box<Map>(matchPlayersBox).length,
      rosterTemplatesBox: Hive.box<Map>(rosterTemplatesBox).length,
      rallyRecordsBox: Hive.box<Map>(rallyRecordsBox).length,
      rallyEventsBox: Hive.box<Map>(rallyEventsBox).length,
      syncQueueBox: Hive.box<Map>(syncQueueBox).length,
    };
  }
}
