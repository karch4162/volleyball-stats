import 'dart:async';

import 'package:hive/hive.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/utils/logger.dart';
import 'rally_repository.dart';
import '../models/rally_models.dart';
import '../../match_setup/models/match_player.dart';

final _logger = createLogger('RallySyncRepository');

/// Repository that handles offline queue and sync for rally data
class RallySyncRepository {
  RallySyncRepository(
    this._rallyRepository,
    this._supabase,
  );

  final RallyRepository _rallyRepository;
  final SupabaseClient _supabase;

  static const String _pendingRalliesBox = 'pending_rallies';
  static const String _syncStatusBox = 'sync_status';

  late final Box<PendingRallyData> _pendingRallies;
  late final Box<SyncStatus> _syncStatus;

  /// Initialize the repository and open Hive boxes
  Future<void> init() async {
    _pendingRallies = await Hive.openBox<PendingRallyData>(_pendingRalliesBox);
    _syncStatus = await Hive.openBox<SyncStatus>(_syncStatusBox);
  }

  /// Queue special actions (substitutions, timeouts) for offline sync
  Future<void> queueSpecialActionForSync({
    required String setId,
    required String? rallyId,
    required RallyActionTypes actionType,
    required MatchPlayer? playerIn,
    required MatchPlayer? playerOut,
    required String? note,
  }) async {
    // For now, we'll save special actions immediately since they don't need rally context
    // In a full implementation, these could also be queued
    try {
      await _rallyRepository.saveSpecialAction(
        setId: setId,
        rallyId: rallyId,
        actionType: actionType,
        playerIn: playerIn,
        playerOut: playerOut,
        note: note,
      );
    } catch (e) {
      _logger.w('Failed to save special action', error: e);
    }
  }

  /// Queue a rally for offline sync
  Future<void> queueRallyForSync({
    required String matchId,
    required String setId,
    required RallyRecord rallyRecord,
    required int rotation,
  }) async {
    final pendingData = PendingRallyData(
      matchId: matchId,
      setId: setId,
      rallyRecord: rallyRecord,
      rotation: rotation,
      queuedAt: DateTime.now(),
      retryCount: 0,
    );

    await _pendingRallies.put(
      rallyRecord.rallyId,
      pendingData,
    );

    // Update sync status
    final currentStatus = _syncStatus.get('status') ?? const SyncStatus();
    await _syncStatus.put(
      'status',
      currentStatus.copyWith(
        pendingCount: currentStatus.pendingCount + 1,
        lastQueueTime: DateTime.now(),
      ),
    );

    // Try to sync immediately if online
    if (await _isOnline()) {
      await syncPendingRallies();
    }
  }

  /// Sync all queued rallies to Supabase
  Future<SyncResult> syncPendingRallies() async {
    if (!(await _isOnline())) {
      return SyncResult(
        success: false,
        synced: 0,
        failed: 0,
        error: 'No internet connection',
      );
    }

    final pendingEntries = Map<String, PendingRallyData>.from(_pendingRallies.toMap());
    int synced = 0;
    int failed = 0;
    String? lastError;

    try {
      for (final entry in pendingEntries.entries) {
        try {
          await _rallyRepository.saveRally(
            matchId: entry.value.matchId,
            setId: entry.value.setId,
            rallyRecord: entry.value.rallyRecord,
            rotation: entry.value.rotation,
          );

          // Remove from pending queue on success
          await _pendingRallies.delete(entry.key);
          synced++;
        } catch (e) {
          failed++;
          lastError = e.toString();
          
          // Update retry count
          final updatedData = entry.value.copyWith(
            retryCount: entry.value.retryCount + 1,
            lastRetryAt: DateTime.now(),
          );
          await _pendingRallies.put(entry.key, updatedData);
          
          // Remove if too many retries
          if (updatedData.retryCount > 5) {
            await _pendingRallies.delete(entry.key);
          }
        }
      }

      // Update sync status
      final currentStatus = _syncStatus.get('status') ?? const SyncStatus();
      await _syncStatus.put(
        'status',
        currentStatus.copyWith(
          pendingCount: (currentStatus.pendingCount - synced),
          lastSyncTime: DateTime.now(),
          lastSyncSuccess: synced > 0,
        ),
      );

      return SyncResult(
        success: failed == 0,
        synced: synced,
        failed: failed,
        error: lastError,
      );
    } catch (e) {
      return SyncResult(
        success: false,
        synced: synced,
        failed: failed,
        error: e.toString(),
      );
    }
  }

  /// Get current sync status
  SyncStatus getSyncStatus() {
    return _syncStatus.get('status') ?? const SyncStatus();
  }

  /// Get count of pending rallies
  int get pendingRalliesCount => _pendingRallies.length;

  /// Clear all pending rallies (for testing or reset)
  Future<void> clearPendingRallies() async {
    await _pendingRallies.clear();
    
    final currentStatus = _syncStatus.get('status') ?? const SyncStatus();
    await _syncStatus.put(
      'status',
      currentStatus.copyWith(pendingCount: 0),
    );
  }

  /// Check if there's internet connectivity
  Future<bool> _isOnline() async {
    try {
      final response = await _supabase
          .from('teams')
          .select('id')
          .limit(1)
          .timeout(const Duration(seconds: 5));
      return response.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}

@HiveType(typeId: 0)
class PendingRallyData {
  @HiveField(0)
  final String matchId;
  @HiveField(1)
  final String setId;
  @HiveField(2)
  final RallyRecord rallyRecord;
  @HiveField(3)
  final int rotation;
  @HiveField(4)
  final DateTime queuedAt;
  @HiveField(5)
  final int retryCount;
  @HiveField(6)
  final DateTime? lastRetryAt;

  const PendingRallyData({
    required this.matchId,
    required this.setId,
    required this.rallyRecord,
    required this.rotation,
    required this.queuedAt,
    required this.retryCount,
    this.lastRetryAt,
  });

  PendingRallyData copyWith({
    String? matchId,
    String? setId,
    RallyRecord? rallyRecord,
    int? rotation,
    DateTime? queuedAt,
    int? retryCount,
    DateTime? lastRetryAt,
  }) {
    return PendingRallyData(
      matchId: matchId ?? this.matchId,
      setId: setId ?? this.setId,
      rallyRecord: rallyRecord ?? this.rallyRecord,
      rotation: rotation ?? this.rotation,
      queuedAt: queuedAt ?? this.queuedAt,
      retryCount: retryCount ?? this.retryCount,
      lastRetryAt: lastRetryAt ?? this.lastRetryAt,
    );
  }
}

@HiveType(typeId: 1)
class SyncStatus {
  @HiveField(0)
  final int pendingCount;
  @HiveField(1)
  final DateTime? lastSyncTime;
  @HiveField(2)
  final bool lastSyncSuccess;
  @HiveField(3)
  final DateTime? lastQueueTime;

  const SyncStatus({
    this.pendingCount = 0,
    this.lastSyncTime,
    this.lastSyncSuccess = false,
    this.lastQueueTime,
  });

  SyncStatus copyWith({
    int? pendingCount,
    DateTime? lastSyncTime,
    bool? lastSyncSuccess,
    DateTime? lastQueueTime,
  }) {
    return SyncStatus(
      pendingCount: pendingCount ?? this.pendingCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      lastSyncSuccess: lastSyncSuccess ?? this.lastSyncSuccess,
      lastQueueTime: lastQueueTime ?? this.lastQueueTime,
    );
  }
}

class SyncResult {
  SyncResult({
    required this.success,
    required this.synced,
    required this.failed,
    this.error,
  });

  final bool success;
  final int synced;
  final int failed;
  final String? error;
}
