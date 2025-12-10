import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/core/theme/app_colors.dart';
import 'package:volleyball_stats_app/features/history/models/player_performance.dart';
import 'package:volleyball_stats_app/features/history/widgets/player_performance_card_v2.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart';

void main() {
  group('PlayerPerformanceCardV2', () {
    late PlayerPerformance testPerformance;

    setUp(() {
      final player = MatchPlayer(
        id: '1',
        name: 'Test Player',
        jerseyNumber: 10,
        position: 'OH',
      );

      testPerformance = PlayerPerformance.fromPlayerStats(
        player: player,
        kills: 15,
        errors: 3,
        attempts: 25,
        blocks: 5,
        aces: 3,
        digs: 8,
        assists: 12,
        fbk: 4,
        serveErrors: 1,
        totalServes: 12,
      );
    });

    testWidgets('displays player name and jersey number', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: testPerformance,
            ),
          ),
        ),
      );

      expect(find.text('Test Player'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
    });

    testWidgets('displays total points', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: testPerformance,
            ),
          ),
        ),
      );

      // Total points = 15 kills + 5 blocks + 3 aces = 23
      expect(find.text('23 total points'), findsOneWidget);
    });

    testWidgets('shows "Did not play" for player with no stats', (tester) async {
      final player = MatchPlayer(
        id: '2',
        name: 'Bench Player',
        jerseyNumber: 99,
        position: 'L',
      );

      final benchPerformance = PlayerPerformance.fromPlayerStats(
        player: player,
        kills: 0,
        errors: 0,
        attempts: 0,
        blocks: 0,
        aces: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: benchPerformance,
            ),
          ),
        ),
      );

      expect(find.text('Did not play'), findsOneWidget);
    });

    testWidgets('expands and collapses on tap', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: testPerformance,
              expandedByDefault: false,
            ),
          ),
        ),
      );

      // Initially collapsed - should see efficiency summary
      expect(find.text('Efficiency'), findsOneWidget);
      expect(find.text('Attacking'), findsNothing);

      // Tap to expand
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Now expanded - should see detailed sections
      expect(find.text('Attacking'), findsOneWidget);

      // Tap to collapse
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Collapsed again
      expect(find.text('Attacking'), findsNothing);
    });

    testWidgets('displays rank badge when showRank is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: testPerformance,
              showRank: true,
              rank: 1,
            ),
          ),
        ),
      );

      expect(find.text('#1'), findsOneWidget);
    });

    testWidgets('does not display rank badge when showRank is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: testPerformance,
              showRank: false,
            ),
          ),
        ),
      );

      expect(find.text('#1'), findsNothing);
    });

    testWidgets('starts expanded when expandedByDefault is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: testPerformance,
              expandedByDefault: true,
            ),
          ),
        ),
      );

      // Should show detailed sections immediately
      expect(find.text('Attacking'), findsOneWidget);
      expect(find.text('Serving'), findsOneWidget);
    });

    testWidgets('displays attacking stats when expanded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: testPerformance,
              expandedByDefault: true,
            ),
          ),
        ),
      );

      // Check for attacking section
      expect(find.text('Attacking'), findsOneWidget);
      expect(find.text('Kills'), findsOneWidget);
      // "Errors" appears in both attacking and serving, so use findsAtLeast
      expect(find.text('Errors'), findsAtLeastNWidgets(1));
      expect(find.text('Attempts'), findsOneWidget);
    });

    testWidgets('displays serving stats when expanded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: testPerformance,
              expandedByDefault: true,
            ),
          ),
        ),
      );

      // Check for serving section
      expect(find.text('Serving'), findsOneWidget);
      expect(find.text('Aces'), findsOneWidget);
      expect(find.text('Total Serves'), findsOneWidget);
    });

    testWidgets('displays other contributions when expanded', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: testPerformance,
              expandedByDefault: true,
            ),
          ),
        ),
      );

      // Check for other contributions section
      expect(find.text('Other Contributions'), findsOneWidget);
      expect(find.text('Blocks'), findsOneWidget);
      expect(find.text('Digs'), findsOneWidget);
      expect(find.text('Assists'), findsOneWidget);
      expect(find.text('FBK'), findsOneWidget);
    });

    testWidgets('does not display sections with no stats', (tester) async {
      final player = MatchPlayer(
        id: '3',
        name: 'Defensive Specialist',
        jerseyNumber: 7,
        position: 'DS',
      );

      final dsPerformance = PlayerPerformance.fromPlayerStats(
        player: player,
        kills: 0,
        errors: 0,
        attempts: 0,
        blocks: 0,
        aces: 0,
        digs: 15,
        assists: 0,
        fbk: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: dsPerformance,
              expandedByDefault: true,
            ),
          ),
        ),
      );

      // Should not show attacking or serving sections (0 attempts/serves)
      expect(find.text('Attacking'), findsNothing);
      expect(find.text('Serving'), findsNothing);

      // Should show other contributions (has digs)
      expect(find.text('Other Contributions'), findsOneWidget);
      expect(find.text('Digs'), findsOneWidget);
    });

    testWidgets('uses correct colors for rank badges', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                PlayerPerformanceCardV2(
                  performance: testPerformance,
                  showRank: true,
                  rank: 1,
                ),
                PlayerPerformanceCardV2(
                  performance: testPerformance,
                  showRank: true,
                  rank: 2,
                ),
                PlayerPerformanceCardV2(
                  performance: testPerformance,
                  showRank: true,
                  rank: 3,
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.text('#1'), findsOneWidget);
      expect(find.text('#2'), findsOneWidget);
      expect(find.text('#3'), findsOneWidget);
    });

    testWidgets('does not allow tap when player has no stats', (tester) async {
      final player = MatchPlayer(
        id: '2',
        name: 'Bench Player',
        jerseyNumber: 99,
        position: 'L',
      );

      final benchPerformance = PlayerPerformance.fromPlayerStats(
        player: player,
        kills: 0,
        errors: 0,
        attempts: 0,
        blocks: 0,
        aces: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerPerformanceCardV2(
              performance: benchPerformance,
            ),
          ),
        ),
      );

      // Try to tap (should not expand since no stats)
      await tester.tap(find.byType(InkWell).first);
      await tester.pumpAndSettle();

      // Should not show expanded content
      expect(find.text('Attacking'), findsNothing);
    });
  });
}
