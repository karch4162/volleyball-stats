import 'package:supabase_flutter/supabase_flutter.dart';
import '../utils/logger.dart';

final _logger = createLogger('ConflictResolver');

/// Handles conflict resolution for offline sync using last-write-wins strategy
class ConflictResolver {
  /// Check if a rally has conflicts with server data
  Future<Map<String, dynamic>?> checkRallyConflict({
    required SupabaseClient client,
    required Map<String, dynamic> localData,
  }) async {
    try {
      final rallyId = localData['id'] ?? localData['rally_id'];
      if (rallyId == null) return null;

      final response = await client
          .from('rally_events')
          .select('*')
          .eq('id', rallyId)
          .maybeSingle();

      if (response == null) {
        // No conflict - item doesn't exist on server
        return null;
      }

      // Check if server version is newer
      final localUpdated = _parseDateTime(localData['updated_at']);
      final serverUpdated = _parseDateTime(response['updated_at']);

      if (localUpdated != null && serverUpdated != null) {
        if (serverUpdated.isAfter(localUpdated)) {
          _logger.w('Conflict detected for rally $rallyId: server is newer');
          return response as Map<String, dynamic>;
        }
      }

      return null;
    } catch (e) {
      _logger.e('Failed to check rally conflict', error: e);
      return null;
    }
  }

  /// Resolve rally conflict using last-write-wins strategy
  Map<String, dynamic> resolveRally({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) {
    final localUpdated = _parseDateTime(localData['updated_at']);
    final serverUpdated = _parseDateTime(serverData['updated_at']);

    // Last-write-wins: keep the newer version
    if (localUpdated != null && serverUpdated != null) {
      if (localUpdated.isAfter(serverUpdated)) {
        _logger.i('Resolved: keeping local version (newer)');
        return localData;
      } else {
        _logger.i('Resolved: keeping server version (newer)');
        return serverData;
      }
    }

    // Default to local if timestamps are missing
    _logger.w('Missing timestamps, defaulting to local version');
    return localData;
  }

  /// Resolve match draft conflict
  Map<String, dynamic> resolveMatchDraft({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) {
    // For drafts, always prefer local version (user's current work)
    _logger.i('Resolved match draft: keeping local version');
    return localData;
  }

  /// Resolve player conflict
  Map<String, dynamic> resolvePlayer({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) {
    final localUpdated = _parseDateTime(localData['updated_at']);
    final serverUpdated = _parseDateTime(serverData['updated_at']);

    // Last-write-wins
    if (localUpdated != null && serverUpdated != null) {
      return localUpdated.isAfter(serverUpdated) ? localData : serverData;
    }

    return localData;
  }

  /// Resolve roster template conflict
  Map<String, dynamic> resolveRosterTemplate({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> serverData,
  }) {
    final localUpdated = _parseDateTime(localData['updated_at']);
    final serverUpdated = _parseDateTime(serverData['updated_at']);

    // Last-write-wins
    if (localUpdated != null && serverUpdated != null) {
      return localUpdated.isAfter(serverUpdated) ? localData : serverData;
    }

    return localData;
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) {
      try {
        return DateTime.parse(value);
      } catch (e) {
        return null;
      }
    }
    return null;
  }
}
