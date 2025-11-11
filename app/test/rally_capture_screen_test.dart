import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volleyball_stats_app/features/match_setup/constants.dart';
import 'package:volleyball_stats_app/features/match_setup/data/data.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_draft.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart';
import 'package:volleyball_stats_app/features/match_setup/providers.dart';
import 'package:volleyball_stats_app/features/rally_capture/providers.dart';
import 'package:volleyball_stats_app/features/rally_capture/rally_capture_screen.dart';

void main() {
  testWidgets('RallyCaptureScreen shows roster and placeholders', (tester) async {
    final fakeRoster = [
      const MatchPlayer(id: 'player-1', name: 'Player One', jerseyNumber: 1, position: 'S'),
      const MatchPlayer(id: 'player-2', name: 'Player Two', jerseyNumber: 2, position: 'OH'),
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
        ],
        child: const MaterialApp(
          home: RallyCaptureScreen(matchId: defaultMatchDraftId),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.textContaining('Rally Controls'), findsOneWidget);
    expect(find.text('Active Roster'), findsOneWidget);
    expect(find.text('Rotation Tracker'), findsOneWidget);
    expect(find.text('#1 Player One'), findsWidgets);
  });
}

