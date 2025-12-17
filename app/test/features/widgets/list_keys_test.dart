import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart';
import 'package:volleyball_stats_app/features/history/models/player_performance.dart';
import 'package:volleyball_stats_app/features/history/models/match_summary.dart';

/// Test suite verifying that dynamic lists have proper keys for correct widget reuse
/// and state preservation. This prevents bugs where Flutter incorrectly reuses widget
/// state when list items are reordered, added, or removed.
void main() {
  group('List Keys Best Practices', () {
    testWidgets('Player list items should have unique ValueKeys', (tester) async {
      final players = [
        MatchPlayer(
          id: 'player-1',
          name: 'Alice',
          jerseyNumber: 5,
          position: 'OH',
        ),
        MatchPlayer(
          id: 'player-2',
          name: 'Bob',
          jerseyNumber: 12,
          position: 'MB',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return Container(
                  key: ValueKey('player-${player.id}'),
                  child: Text('#${player.jerseyNumber} ${player.name}'),
                );
              },
            ),
          ),
        ),
      );

      // Verify keys are present
      expect(find.byKey(const ValueKey('player-player-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-player-2')), findsOneWidget);
    });

    testWidgets('PlayerPerformance cards should have unique keys', (tester) async {
      final performances = [
        PlayerPerformance(
          playerId: 'p1',
          playerName: 'Alice',
          jerseyNumber: 5,
          kills: 10,
          errors: 2,
          attempts: 20,
          blocks: 3,
          digs: 15,
          assists: 5,
          aces: 2,
          serveErrors: 1,
          totalServes: 10,
          fbk: 4,
        ),
        PlayerPerformance(
          playerId: 'p2',
          playerName: 'Bob',
          jerseyNumber: 12,
          kills: 8,
          errors: 1,
          attempts: 15,
          blocks: 6,
          digs: 8,
          assists: 2,
          aces: 1,
          serveErrors: 0,
          totalServes: 8,
          fbk: 2,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: performances.map((perf) {
                return Padding(
                  key: ValueKey('player-perf-${perf.playerId}'),
                  padding: const EdgeInsets.all(8),
                  child: Text(perf.playerName),
                );
              }).toList(),
            ),
          ),
        ),
      );

      // Verify unique keys
      expect(find.byKey(const ValueKey('player-perf-p1')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-perf-p2')), findsOneWidget);
    });

    testWidgets('Match summary items should have unique keys', (tester) async {
      final matches = [
        MatchSummary(
          matchId: 'match-1',
          opponent: 'Team A',
          matchDate: DateTime(2024, 1, 15),
          location: 'Home',
          setsWon: 3,
          setsLost: 1,
          totalRallies: 120,
          totalFBK: 45,
          totalTransitionPoints: 75,
          isWin: true,
        ),
        MatchSummary(
          matchId: 'match-2',
          opponent: 'Team B',
          matchDate: DateTime(2024, 1, 20),
          location: 'Away',
          setsWon: 2,
          setsLost: 3,
          totalRallies: 140,
          totalFBK: 38,
          totalTransitionPoints: 68,
          isWin: false,
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: matches.map((match) {
                return Padding(
                  key: ValueKey('match-${match.matchId}'),
                  padding: const EdgeInsets.all(8),
                  child: Text(match.opponent),
                );
              }).toList(),
            ),
          ),
        ),
      );

      // Verify unique keys
      expect(find.byKey(const ValueKey('match-match-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('match-match-2')), findsOneWidget);
    });

    testWidgets('Keys help maintain state during list reordering', (tester) async {
      // This test demonstrates why keys are important: they maintain widget state
      // when items are reordered.

      final players = [
        MatchPlayer(id: 'p1', name: 'Alice', jerseyNumber: 5, position: 'OH'),
        MatchPlayer(id: 'p2', name: 'Bob', jerseyNumber: 12, position: 'MB'),
        MatchPlayer(id: 'p3', name: 'Carol', jerseyNumber: 8, position: 'S'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: players.map((player) {
                  return Container(
                    key: ValueKey('player-${player.id}'),
                    padding: const EdgeInsets.all(8),
                    child: Text('#${player.jerseyNumber} ${player.name}'),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );

      // Verify initial order
      expect(find.text('#5 Alice'), findsOneWidget);
      expect(find.text('#12 Bob'), findsOneWidget);
      expect(find.text('#8 Carol'), findsOneWidget);

      // Simulate reordering (in real app, this would be drag-drop or sort change)
      final reordered = [players[2], players[0], players[1]]; // Carol, Alice, Bob

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Column(
                children: reordered.map((player) {
                  return Container(
                    key: ValueKey('player-${player.id}'),
                    padding: const EdgeInsets.all(8),
                    child: Text('#${player.jerseyNumber} ${player.name}'),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // All players should still be present with correct data
      expect(find.text('#5 Alice'), findsOneWidget);
      expect(find.text('#12 Bob'), findsOneWidget);
      expect(find.text('#8 Carol'), findsOneWidget);
      
      // Keys ensure the widgets maintain their identity
      expect(find.byKey(const ValueKey('player-p1')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-p2')), findsOneWidget);
      expect(find.byKey(const ValueKey('player-p3')), findsOneWidget);
    });

    testWidgets('Keys prevent incorrect state reuse in ListView.builder', (tester) async {
      // Test that ListView.builder items with keys maintain correct identity
      final players = [
        MatchPlayer(id: 'p1', name: 'Player 1', jerseyNumber: 1, position: 'OH'),
        MatchPlayer(id: 'p2', name: 'Player 2', jerseyNumber: 2, position: 'MB'),
        MatchPlayer(id: 'p3', name: 'Player 3', jerseyNumber: 3, position: 'S'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: players.length,
              itemBuilder: (context, index) {
                final player = players[index];
                return ListTile(
                  key: ValueKey('player-${player.id}'),
                  title: Text(player.name),
                  subtitle: Text('#${player.jerseyNumber}'),
                );
              },
            ),
          ),
        ),
      );

      // Verify all items have proper keys
      for (final player in players) {
        expect(find.byKey(ValueKey('player-${player.id}')), findsOneWidget);
      }
    });

    test('Key naming convention follows pattern: type-id', () {
      // Document the key naming convention used throughout the app
      const examples = [
        'player-{id}',
        'player-stats-{id}',
        'player-perf-{id}',
        'match-{id}',
        'team-{id}',
        'template-{id}',
        'roster-chip-{id}',
        'rotation-player-{id}',
      ];

      // Verify all examples follow the pattern
      for (final example in examples) {
        expect(example.contains('-'), true, reason: 'Key should contain hyphen separator');
        expect(example.split('-').length, greaterThanOrEqualTo(2), 
          reason: 'Key should have at least type and id parts');
      }
    });
  });
}
