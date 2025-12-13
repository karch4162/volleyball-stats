import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volleyball_stats_app/features/match_setup/match_setup_flow.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart';
import 'package:volleyball_stats_app/features/match_setup/providers.dart';

Future<void> _configureLargeWindow(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1080, 1920);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

const _testRoster = [
  MatchPlayer(id: 'p1', name: 'Ava Setter', jerseyNumber: 1, position: 'S'),
  MatchPlayer(id: 'p2', name: 'Brooke Opp', jerseyNumber: 2, position: 'OPP'),
  MatchPlayer(id: 'p3', name: 'Callie Middle', jerseyNumber: 9, position: 'MB'),
  MatchPlayer(id: 'p4', name: 'Dani Libero', jerseyNumber: 4, position: 'L'),
  MatchPlayer(id: 'p5', name: 'Emery Outside', jerseyNumber: 7, position: 'OH'),
  MatchPlayer(id: 'p6', name: 'Finley DS', jerseyNumber: 11, position: 'DS'),
  MatchPlayer(id: 'p7', name: 'Gia Setter', jerseyNumber: 12, position: 'S'),
  MatchPlayer(id: 'p8', name: 'Haven Middle', jerseyNumber: 15, position: 'MB'),
];

Future<void> _pumpMatchSetupFlow(WidgetTester tester) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        matchSetupRosterProvider.overrideWith((ref) async => _testRoster),
      ],
      child: const MaterialApp(
        home: MatchSetupFlow(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _togglePlayers(WidgetTester tester, List<int> indexes) async {
  for (final index in indexes) {
    await tester.tap(find.byType(FilterChip).at(index));
    await tester.pump();
  }
}

void main() {
  testWidgets('renders streamlined sections by default', (tester) async {
    await _configureLargeWindow(tester);
    await _pumpMatchSetupFlow(tester);

    expect(find.text('Match Info'), findsOneWidget);
    expect(find.text('Roster Selection'), findsOneWidget);
    expect(find.text('Starting Rotation'), findsOneWidget);
    expect(find.text('Select match date'), findsOneWidget);
    expect(find.byType(FilterChip), findsNWidgets(_testRoster.length));
  });

  testWidgets('shows roster warning until six players selected', (tester) async {
    await _configureLargeWindow(tester);
    await _pumpMatchSetupFlow(tester);

    await _togglePlayers(tester, [0, 1, 2]);

    expect(find.text('Select at least 6 players'), findsOneWidget);

    await _togglePlayers(tester, [3, 4, 5]);
    await tester.pump();

    expect(find.text('Select at least 6 players'), findsNothing);
  });

  testWidgets('shows rotation warning when roster ready but rotation empty', (tester) async {
    await _configureLargeWindow(tester);
    await _pumpMatchSetupFlow(tester);

    await _togglePlayers(tester, [0, 1, 2, 3, 4, 5]);

    expect(find.text('Assign all 6 rotation positions'), findsOneWidget);
  });
}

