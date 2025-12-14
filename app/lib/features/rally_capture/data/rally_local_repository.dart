import '../../../core/persistence/hive_service.dart';
import '../../../core/persistence/type_adapters.dart';
import '../../../core/utils/logger.dart';
import '../models/rally_models.dart';

final _logger = createLogger('RallyLocalRepository');

/// Local-first repository for rally data using Hive
class RallyLocalRepository {
  /// Save a rally capture session to local storage
  Future<void> saveSession(RallyCaptureSession session) async {
    try {
      final box = HiveService.getBox(HiveService.rallyRecordsBox);
      final key = _sessionKey(session.matchId, session.setId);
      final sessionMap = ModelSerializer.rallyCaptureSessionToMap(session);
      
      await box.put(key, sessionMap);
      _logger.i('Saved session: $key');
    } catch (e, st) {
      _logger.e('Failed to save session', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Load a rally capture session from local storage
  Future<RallyCaptureSession?> loadSession({
    required String matchId,
    required String setId,
  }) async {
    try {
      final box = HiveService.getBox(HiveService.rallyRecordsBox);
      final key = _sessionKey(matchId, setId);
      final sessionMap = box.get(key);
      
      if (sessionMap == null) {
        _logger.i('No saved session found for: $key');
        return null;
      }
      
      final session = ModelSerializer.rallyCaptureSessionFromMap(
        Map<String, dynamic>.from(sessionMap),
      );
      _logger.i('Loaded session: $key with ${session.completedRallies.length} rallies');
      return session;
    } catch (e, st) {
      _logger.e('Failed to load session', error: e, stackTrace: st);
      return null;
    }
  }

  /// Delete a session from local storage
  Future<void> deleteSession({
    required String matchId,
    required String setId,
  }) async {
    try {
      final box = HiveService.getBox(HiveService.rallyRecordsBox);
      final key = _sessionKey(matchId, setId);
      await box.delete(key);
      _logger.i('Deleted session: $key');
    } catch (e, st) {
      _logger.e('Failed to delete session', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Save a completed rally record
  Future<void> saveRallyRecord({
    required String matchId,
    required String setId,
    required RallyRecord rally,
  }) async {
    try {
      final box = HiveService.getBox(HiveService.rallyEventsBox);
      final key = _rallyKey(matchId, setId, rally.rallyId);
      final rallyMap = ModelSerializer.rallyRecordToMap(rally);
      
      await box.put(key, rallyMap);
      _logger.i('Saved rally: ${rally.rallyNumber}');
    } catch (e, st) {
      _logger.e('Failed to save rally record', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Load all rally records for a match/set
  Future<List<RallyRecord>> loadRallyRecords({
    required String matchId,
    required String setId,
  }) async {
    try {
      final box = HiveService.getBox(HiveService.rallyEventsBox);
      final prefix = _rallyPrefix(matchId, setId);
      final rallies = <RallyRecord>[];
      
      for (final key in box.keys) {
        if (key.toString().startsWith(prefix)) {
          final rallyMap = box.get(key);
          if (rallyMap != null) {
            final rally = ModelSerializer.rallyRecordFromMap(
              Map<String, dynamic>.from(rallyMap),
            );
            rallies.add(rally);
          }
        }
      }
      
      // Sort by rally number
      rallies.sort((a, b) => a.rallyNumber.compareTo(b.rallyNumber));
      _logger.i('Loaded ${rallies.length} rallies for $matchId/$setId');
      return rallies;
    } catch (e, st) {
      _logger.e('Failed to load rally records', error: e, stackTrace: st);
      return [];
    }
  }

  /// Get all sessions that need syncing
  Future<List<String>> getUnsyncedSessionKeys() async {
    try {
      final box = HiveService.getBox(HiveService.rallyRecordsBox);
      return box.keys.map((k) => k.toString()).toList();
    } catch (e, st) {
      _logger.e('Failed to get unsynced sessions', error: e, stackTrace: st);
      return [];
    }
  }

  /// Clear all rally data (for testing/reset)
  Future<void> clearAll() async {
    try {
      final recordsBox = HiveService.getBox(HiveService.rallyRecordsBox);
      final eventsBox = HiveService.getBox(HiveService.rallyEventsBox);
      
      await recordsBox.clear();
      await eventsBox.clear();
      _logger.w('Cleared all rally data');
    } catch (e, st) {
      _logger.e('Failed to clear rally data', error: e, stackTrace: st);
      rethrow;
    }
  }

  /// Get storage statistics
  Map<String, int> getStats() {
    try {
      return {
        'sessions': HiveService.getBox(HiveService.rallyRecordsBox).length,
        'rallies': HiveService.getBox(HiveService.rallyEventsBox).length,
      };
    } catch (e) {
      return {'sessions': 0, 'rallies': 0};
    }
  }

  // Helper methods for key generation
  String _sessionKey(String matchId, String setId) => 'session_${matchId}_$setId';
  String _rallyKey(String matchId, String setId, String rallyId) => 
      'rally_${matchId}_${setId}_$rallyId';
  String _rallyPrefix(String matchId, String setId) => 'rally_${matchId}_$setId';
}
