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
  testWidgets('RallyCaptureScreen records actions and updates timeline',
      (tester) async {
    final fakeRoster = [
      const MatchPlayer(
          id: 'player-1', name: 'Player One', jerseyNumber: 1, position: 'S'),
      const MatchPlayer(
          id: 'player-2', name: 'Player Two', jerseyNumber: 2, position: 'OH'),
    ];

    final fakeDraft = MatchDraft(
      opponent: 'Opponent',
      matchDate: null,
      location: '',
      seasonLabel: '',
      selectedPlayerIds: fakeRoster.map((p) => p.id).toSet(),
      startingRotation: {
        1: fakeRoster[0].id,
        2: fakeRoster[1].id,
      },
    );

    final repository = InMemoryMatchSetupRepository(
      seedRoster: fakeRoster,
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

    expect(
        find.text(
            'No rallies recorded yet. Use the action buttons to start logging.'),
        findsOneWidget);

    await tester.ensureVisible(find.text('Serve Ace'));
    await tester.tap(find.text('Serve Ace'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('#1 Player One').last);
    await tester.pumpAndSettle();

    expect(find.text('Rally 1 (In Progress)'), findsOneWidget);
    expect(find.text('Serve Ace • #1 Player One'), findsOneWidget);

    await tester
        .ensureVisible(find.widgetWithText(FilledButton, 'Complete Rally'));
    await tester.tap(find.widgetWithText(FilledButton, 'Complete Rally'));
    await tester.pumpAndSettle();

    expect(find.text('Rally 1 (In Progress)'), findsNothing);
    expect(find.text('Rally 1'), findsOneWidget);
    expect(find.text('Serve Ace • #1 Player One'), findsOneWidget);
  });
}
