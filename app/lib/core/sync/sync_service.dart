import 'dart:async';
import 'package:uuid/uuid.dart';
import '../persistence/hive_service.dart';
import '../utils/logger.dart';
import '../supabase.dart';
import 'sync_queue_item.dart';
import 'conflict_resolver.dart';

final _logger = createLogger('SyncService');
const _uuid = Uuid();

/// Service for managing offline sync queue and syncing to Supabase
class SyncService {
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 5);
  
  Timer? _syncTimer;
  bool _isSyncing = false;
  
  final ConflictResolver _conflictResolver = ConflictResolver();

  /// Start automatic sync (every 30 seconds when online)
  void startAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      syncAll();
    });
    _logger.i('Auto-sync started (30s interval)');
  }

  /// Stop automatic sync
  void stopAutoSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _logger.i('Auto-sync stopped');
  }

  /// Add an item to the sync queue
  Future<void> enqueue({
    required SyncItemType type,
    required SyncOperation operation,
    required Map<String, dynamic> data,
  }) async {
    try {
      final box = HiveService.getBox(HiveService.syncQueueBox);
      final item = SyncQueueItem(
        id: _uuid.v4(),
        type: type,
        operation: operation,
        data: data,
        createdAt: DateTime.now(),
      );
      
      await box.put(item.id, item.toMap());
      _logger.i('Enqueued ${type.name} ${operation.name}: ${item.id}');
      
      // Try immediate sync if online
      if (getSupabaseClientOrNull() != null) {
        unawaited(syncAll());
      }
    } catch (e, st) {
      _logger.e('Failed to enqueue sync item', error: e, stackTrace: st);
    }
  }

  /// Sync all queued items to Supabase
  Future<SyncResult> syncAll() async {
    if (_isSyncing) {
      _logger.i('Sync already in progress, skipping');
      return SyncResult(success: 0, failed: 0, skipped: 0);
    }

    final client = getSupabaseClientOrNull();
    if (client == null) {
      _logger.i('Supabase not available, skipping sync');
      return SyncResult(success: 0, failed: 0, skipped: 0);
    }

    _isSyncing = true;
    int successCount = 0;
    int failedCount = 0;
    int skippedCount = 0;

    try {
      final box = HiveService.getBox(HiveService.syncQueueBox);
      final items = box.values
          .map((v) => SyncQueueItem.fromMap(Map<String, dynamic>.from(v)))
          .toList();

      _logger.i('Syncing ${items.length} queued items');

      for (final item in items) {
        try {
          // Skip if max retries exceeded
          if (!item.shouldRetry(maxAttempts: maxRetries)) {
            _logger.w('Max retries exceeded for item ${item.id}');
            skippedCount++;
            continue;
          }

          // Sync the item
          await _syncItem(item);
          
          // Remove from queue on success
          await box.delete(item.id);
          successCount++;
          _logger.i('Synced ${item.type.name} ${item.operation.name}: ${item.id}');
          
        } catch (e) {
          _logger.e('Failed to sync item ${item.id}', error: e);
          
          // Update retry count
          final updated = item.incrementAttempts(e.toString());
          await box.put(item.id, updated.toMap());
          failedCount++;
        }
      }

      _logger.i('Sync complete: $successCount success, $failedCount failed, $skippedCount skipped');
      return SyncResult(
        success: successCount,
        failed: failedCount,
        skipped: skippedCount,
      );
      
    } catch (e, st) {
      _logger.e('Sync process failed', error: e, stackTrace: st);
      return SyncResult(success: successCount, failed: failedCount, skipped: skippedCount);
    } finally {
      _isSyncing = false;
    }
  }

  /// Sync a single item to Supabase
  Future<void> _syncItem(SyncQueueItem item) async {
    final client = getSupabaseClientOrNull();
    if (client == null) {
      throw Exception('Supabase client not available');
    }

    switch (item.type) {
      case SyncItemType.rally:
        await _syncRally(item);
        break;
      case SyncItemType.matchDraft:
        await _syncMatchDraft(item);
        break;
      case SyncItemType.player:
        await _syncPlayer(item);
        break;
      case SyncItemType.rosterTemplate:
        await _syncRosterTemplate(item);
        break;
    }
  }

  Future<void> _syncRally(SyncQueueItem item) async {
    final client = getSupabaseClientOrNull()!;
    
    switch (item.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        // Check for conflicts
        final conflict = await _conflictResolver.checkRallyConflict(
          client: client,
          localData: item.data,
        );
        
        if (conflict != null) {
          // Resolve using last-write-wins
          final resolved = _conflictResolver.resolveRally(
            localData: item.data,
            serverData: conflict,
          );
          await client.from('rally_events').upsert(resolved);
        } else {
          await client.from('rally_events').upsert(item.data);
        }
        break;
        
      case SyncOperation.delete:
        await client.from('rally_events')
            .delete()
            .eq('id', item.data['id']);
        break;
    }
  }

  Future<void> _syncMatchDraft(SyncQueueItem item) async {
    final client = getSupabaseClientOrNull()!;
    
    switch (item.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        await client.from('match_drafts').upsert(item.data);
        break;
        
      case SyncOperation.delete:
        await client.from('match_drafts')
            .delete()
            .eq('match_id', item.data['match_id']);
        break;
    }
  }

  Future<void> _syncPlayer(SyncQueueItem item) async {
    final client = getSupabaseClientOrNull()!;
    
    switch (item.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        await client.from('players').upsert(item.data);
        break;
        
      case SyncOperation.delete:
        await client.from('players')
            .delete()
            .eq('id', item.data['id']);
        break;
    }
  }

  Future<void> _syncRosterTemplate(SyncQueueItem item) async {
    final client = getSupabaseClientOrNull()!;
    
    switch (item.operation) {
      case SyncOperation.create:
      case SyncOperation.update:
        await client.from('roster_templates').upsert(item.data);
        break;
        
      case SyncOperation.delete:
        await client.from('roster_templates')
            .delete()
            .eq('id', item.data['id']);
        break;
    }
  }

  /// Get sync queue statistics
  Future<SyncStats> getStats() async {
    try {
      final box = HiveService.getBox(HiveService.syncQueueBox);
      final items = box.values
          .map((v) => SyncQueueItem.fromMap(Map<String, dynamic>.from(v)))
          .toList();

      final pending = items.where((i) => i.attempts == 0).length;
      final retrying = items.where((i) => i.attempts > 0 && i.attempts < maxRetries).length;
      final failed = items.where((i) => i.attempts >= maxRetries).length;

      return SyncStats(
        total: items.length,
        pending: pending,
        retrying: retrying,
        failed: failed,
      );
    } catch (e) {
      return SyncStats(total: 0, pending: 0, retrying: 0, failed: 0);
    }
  }

  /// Clear all failed items from the queue
  Future<void> clearFailed() async {
    try {
      final box = HiveService.getBox(HiveService.syncQueueBox);
      final items = box.values
          .map((v) => SyncQueueItem.fromMap(Map<String, dynamic>.from(v)))
          .toList();

      for (final item in items) {
        if (!item.shouldRetry(maxAttempts: maxRetries)) {
          await box.delete(item.id);
        }
      }
      _logger.i('Cleared failed sync items');
    } catch (e, st) {
      _logger.e('Failed to clear failed items', error: e, stackTrace: st);
    }
  }

  /// Clear entire sync queue (for testing/reset)
  Future<void> clearAll() async {
    try {
      final box = HiveService.getBox(HiveService.syncQueueBox);
      await box.clear();
      _logger.w('Cleared all sync queue items');
    } catch (e, st) {
      _logger.e('Failed to clear sync queue', error: e, stackTrace: st);
    }
  }

  void dispose() {
    stopAutoSync();
  }
}

class SyncResult {
  const SyncResult({
    required this.success,
    required this.failed,
    required this.skipped,
  });

  final int success;
  final int failed;
  final int skipped;

  int get total => success + failed + skipped;
  bool get hasFailures => failed > 0;
  bool get isComplete => failed == 0 && skipped == 0;
}

class SyncStats {
  const SyncStats({
    required this.total,
    required this.pending,
    required this.retrying,
    required this.failed,
  });

  final int total;
  final int pending;
  final int retrying;
  final int failed;

  bool get hasItems => total > 0;
  bool get hasFailures => failed > 0;
}
