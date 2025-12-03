import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volleyball_stats_app/features/match_setup/constants.dart';
import 'package:volleyball_stats_app/features/match_setup/data/data.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_draft.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart';
import 'package:volleyball_stats_app/features/match_setup/providers.dart';
import 'package:volleyball_stats_app/features/rally_capture/rally_capture_screen.dart';
import 'package:volleyball_stats_app/features/rally_capture/providers.dart';
import 'package:volleyball_stats_app/features/rally_capture/data/rally_sync_repository.dart';
import 'package:volleyball_stats_app/features/rally_capture/models/rally_models.dart' as rally_models;
import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart' as match_setup_models;

// Mock implementation for testing
class MockRallySyncRepository implements RallySyncRepository {
  @override
  Future<void> init() async {}
  
  @override
  Future<void> queueRallyForSync({
    required String matchId,
    required String setId,
    required rally_models.RallyRecord rallyRecord,
    required int rotation,
  }) async {}
  
  @override
  Future<void> queueSpecialActionForSync({
    required String setId,
    required String? rallyId,
    required rally_models.RallyActionTypes actionType,
    required match_setup_models.MatchPlayer? playerIn,
    required match_setup_models.MatchPlayer? playerOut,
    required String? note,
  }) async {}
  
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
  testWidgets('RallyCaptureScreen records actions and updates recent rallies',
      (tester) async {
    final fakeRoster = [
      const MatchPlayer(id: 'player-1', name: 'Player One', jerseyNumber: 1, position: 'S'),
      const MatchPlayer(id: 'player-2', name: 'Player Two', jerseyNumber: 2, position: 'OH'),
      const MatchPlayer(id: 'player-3', name: 'Player Three', jerseyNumber: 3, position: 'MB'),
      const MatchPlayer(id: 'player-4', name: 'Player Four', jerseyNumber: 4, position: 'L'),
      const MatchPlayer(id: 'player-5', name: 'Player Five', jerseyNumber: 5, position: 'OPP'),
      const MatchPlayer(id: 'player-6', name: 'Player Six', jerseyNumber: 6, position: 'DS'),
      const MatchPlayer(id: 'player-7', name: 'Player Seven', jerseyNumber: 7, position: 'MB'),
    ];

    final selectedPlayers = fakeRoster.take(6).map((p) => p.id).toSet();
    final rotation = <int, String>{
      for (var i = 0; i < 6; i++) i + 1: fakeRoster[i].id,
    };

    final fakeDraft = MatchDraft(
      opponent: 'Opponent',
      matchDate: DateTime(2025, 1, 1),
      location: 'Home',
      seasonLabel: '2025',
      selectedPlayerIds: selectedPlayers,
      startingRotation: rotation,
    );

    final repository = InMemoryMatchSetupRepository(
      seedRoster: {defaultTeamId: fakeRoster},
      seedDrafts: {defaultMatchDraftId: fakeDraft},
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          matchDraftCacheProvider.overrideWithValue(InMemoryMatchDraftCache()),
          matchSetupRepositoryProvider.overrideWithValue(repository),
          rallySyncRepositoryProvider.overrideWithValue(MockRallySyncRepository()),
        ],
        child: const MaterialApp(
          home: RallyCaptureScreen(matchId: defaultMatchDraftId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Recent Rallies'), findsOneWidget);
    expect(find.text('No rallies yet'), findsOneWidget);

    final aceButton = find.descendant(
      of: find.byKey(const ValueKey('player-player-1')),
      matching: find.text('Ace'),
    );
    await tester.ensureVisible(aceButton);
    await tester.tap(aceButton);
    await tester.pumpAndSettle();

    expect(find.text('No rallies yet'), findsNothing);
    expect(find.text('Serve Ace by Player One'), findsOneWidget);
  });
}
