import 'package:flutter_test/flutter_test.dart';

import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart';
import 'package:volleyball_stats_app/features/rally_capture/providers.dart';
import 'package:volleyball_stats_app/features/rally_capture/models/rally_models.dart';
import 'package:volleyball_stats_app/features/rally_capture/data/rally_sync_repository.dart';

// Mock implementation for testing
class MockRallySyncRepository implements RallySyncRepository {
  final queueRallyForSyncCalls = <Map<String, dynamic>>[];
  final queueSpecialActionForSyncCalls = <Map<String, dynamic>>[];
  
  @override
  Future<void> init() async {}
  
  @override
  Future<void> queueRallyForSync({
    required String matchId,
    required String setId,
    required RallyRecord rallyRecord,
    required int rotation,
  }) async {
    queueRallyForSyncCalls.add({
      'matchId': matchId,
      'setId': setId,
      'rallyRecord': rallyRecord,
      'rotation': rotation,
    });
  }
  
  @override
  Future<void> queueSpecialActionForSync({
    required String setId,
    required String? rallyId,
    required RallyActionTypes actionType,
    required MatchPlayer? playerIn,
    required MatchPlayer? playerOut,
    required String? note,
  }) async {
    queueSpecialActionForSyncCalls.add({
      'setId': setId,
      'rallyId': rallyId,
      'actionType': actionType,
      'playerIn': playerIn,
      'playerOut': playerOut,
      'note': note,
    });
  }
  
  @override
  Future<SyncResult> syncPendingRallies() async {
    return SyncResult(success: true, synced: 0, failed: 0);
  }
  
  @override
  SyncStatus getSyncStatus() {
    return const SyncStatus();
  }
  
  @override
  int get pendingRalliesCount => 0;
  
  @override
  Future<void> clearPendingRallies() async {}
}

void main() {
  const player = MatchPlayer(
    id: 'player-1',
    name: 'Player One',
    jerseyNumber: 7,
    position: 'OH',
  );

  group('RallyCaptureSessionController', () {
    test('can create session controller with proper initial state', () async {
      final mockSyncRepo = MockRallySyncRepository();
      
      final controller = RallyCaptureSessionController(
        matchId: 'match-1',
        setId: 'set-1',
        syncRepository: mockSyncRepo,
      );

      expect(controller.state.currentRallyNumber, 1);
      expect(controller.state.currentEvents, isEmpty);
      expect(controller.state.canUndo, isFalse);
      expect(controller.state.canRedo, isFalse);
    });
    
    test('completeRally returns false when no actions are logged', () async {
      final controller = RallyCaptureSessionController(
        matchId: 'match-2',
        setId: 'set-2',
        syncRepository: MockRallySyncRepository(),
      );
      expect(await controller.completeRally(), isFalse);
      expect(controller.state.completedRallies, isEmpty);
      expect(controller.state.currentRallyNumber, 1);
    });
  });
}
