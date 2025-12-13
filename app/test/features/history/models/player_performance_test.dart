import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/features/history/models/player_performance.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart';

void main() {
  group('PlayerPerformance', () {
    group('Calculated Properties', () {
      test('attackEfficiency calculates correctly with attempts', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Test Player',
          jerseyNumber: 10,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 15,
          errors: 3,
          attempts: 25,
          blocks: 0,
          aces: 0,
        );

        // (15 - 3) / 25 = 0.48
        expect(performance.attackEfficiency, closeTo(0.48, 0.001));
      });

      test('attackEfficiency returns 0 when no attempts', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Test Player',
          jerseyNumber: 10,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 0,
          errors: 0,
          attempts: 0,
          blocks: 0,
          aces: 0,
        );

        expect(performance.attackEfficiency, equals(0.0));
      });

      test('killPercentage calculates correctly', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Test Player',
          jerseyNumber: 10,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 12,
          errors: 3,
          attempts: 20,
          blocks: 0,
          aces: 0,
        );

        // 12 / 20 = 0.6
        expect(performance.killPercentage, closeTo(0.6, 0.001));
      });

      test('acePercentage calculates correctly', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Test Player',
          jerseyNumber: 10,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 0,
          errors: 0,
          attempts: 0,
          blocks: 0,
          aces: 3,
          serveErrors: 1,
          totalServes: 12,
        );

        // 3 / 12 = 0.25
        expect(performance.acePercentage, closeTo(0.25, 0.001));
      });

      test('servicePressure calculates correctly with positive pressure', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Test Player',
          jerseyNumber: 10,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 0,
          errors: 0,
          attempts: 0,
          blocks: 0,
          aces: 5,
          serveErrors: 2,
          totalServes: 15,
        );

        // (5 - 2) / 15 = 0.2
        expect(performance.servicePressure, closeTo(0.2, 0.001));
      });

      test('servicePressure calculates correctly with negative pressure', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Test Player',
          jerseyNumber: 10,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 0,
          errors: 0,
          attempts: 0,
          blocks: 0,
          aces: 2,
          serveErrors: 5,
          totalServes: 15,
        );

        // (2 - 5) / 15 = -0.2
        expect(performance.servicePressure, closeTo(-0.2, 0.001));
      });

      test('servicePressure returns 0 when no serves', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Test Player',
          jerseyNumber: 10,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 0,
          errors: 0,
          attempts: 0,
          blocks: 0,
          aces: 0,
          serveErrors: 0,
          totalServes: 0,
        );

        expect(performance.servicePressure, equals(0.0));
      });

      test('totalPoints calculates correctly', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Test Player',
          jerseyNumber: 10,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 15,
          errors: 3,
          attempts: 25,
          blocks: 5,
          aces: 3,
        );

        // 15 + 5 + 3 = 23
        expect(performance.totalPoints, equals(23));
      });
    });

    group('Formatted Display Strings', () {
      test('attackSummary formats correctly', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Test Player',
          jerseyNumber: 10,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 15,
          errors: 3,
          attempts: 25,
          blocks: 0,
          aces: 0,
        );

        expect(performance.attackSummary, equals('15-3 / 25 (60.0%)'));
      });

      test('serveSummary formats correctly', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Test Player',
          jerseyNumber: 10,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 0,
          errors: 0,
          attempts: 0,
          blocks: 0,
          aces: 3,
          serveErrors: 1,
          totalServes: 12,
        );

        expect(performance.serveSummary, equals('3-1 / 12 (25.0%)'));
      });
    });

    group('Factory Constructors', () {
      test('fromPlayerStats creates instance with all fields', () {
        const player = MatchPlayer(
          id: '123',
          name: 'Jane Doe',
          jerseyNumber: 15,
          position: 'MB',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 10,
          errors: 2,
          attempts: 20,
          blocks: 7,
          aces: 2,
          digs: 8,
          assists: 15,
          fbk: 3,
          serveErrors: 1,
          totalServes: 10,
        );

        expect(performance.playerId, equals('123'));
        expect(performance.playerName, equals('Jane Doe'));
        expect(performance.jerseyNumber, equals(15));
        expect(performance.kills, equals(10));
        expect(performance.errors, equals(2));
        expect(performance.attempts, equals(20));
        expect(performance.blocks, equals(7));
        expect(performance.aces, equals(2));
        expect(performance.digs, equals(8));
        expect(performance.assists, equals(15));
        expect(performance.fbk, equals(3));
        expect(performance.serveErrors, equals(1));
        expect(performance.totalServes, equals(10));
      });

      test('fromPlayerStats uses default values for optional fields', () {
        const player = MatchPlayer(
          id: '123',
          name: 'Jane Doe',
          jerseyNumber: 15,
          position: 'MB',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 10,
          errors: 2,
          attempts: 20,
          blocks: 7,
          aces: 2,
        );

        expect(performance.digs, equals(0));
        expect(performance.assists, equals(0));
        expect(performance.fbk, equals(0));
        expect(performance.serveErrors, equals(0));
        expect(performance.totalServes, equals(2)); // Calculated from aces if not provided
      });

      test('fromMap creates instance correctly', () {
        final map = {
          'player_id': '456',
          'player_name': 'John Smith',
          'jersey_number': 8,
          'kills': 12,
          'errors': 3,
          'attempts': 22,
          'blocks': 4,
          'aces': 1,
          'digs': 10,
          'assists': 20,
          'fbk': 5,
          'serve_errors': 2,
          'total_serves': 15,
        };

        final performance = PlayerPerformance.fromMap(map);

        expect(performance.playerId, equals('456'));
        expect(performance.playerName, equals('John Smith'));
        expect(performance.jerseyNumber, equals(8));
        expect(performance.kills, equals(12));
        expect(performance.digs, equals(10));
        expect(performance.assists, equals(20));
        expect(performance.fbk, equals(5));
        expect(performance.totalServes, equals(15));
      });

      test('fromMap calculates totalServes when not provided', () {
        final map = {
          'player_id': '456',
          'player_name': 'John Smith',
          'jersey_number': 8,
          'kills': 12,
          'errors': 3,
          'attempts': 22,
          'blocks': 4,
          'aces': 3,
          'digs': 10,
          'assists': 20,
          'fbk': 5,
          'serve_errors': 2,
          // total_serves not provided
        };

        final performance = PlayerPerformance.fromMap(map);

        // Should calculate from aces + serveErrors
        expect(performance.totalServes, equals(5));
      });

      test('fromMap handles missing optional fields', () {
        final map = {
          'player_id': '456',
          'player_name': 'John Smith',
          'jersey_number': 8,
          'kills': 0,
          'errors': 0,
          'attempts': 0,
          'blocks': 0,
          'aces': 0,
        };

        final performance = PlayerPerformance.fromMap(map);

        expect(performance.digs, equals(0));
        expect(performance.assists, equals(0));
        expect(performance.fbk, equals(0));
        expect(performance.serveErrors, equals(0));
        expect(performance.totalServes, equals(0));
      });
    });

    group('Edge Cases', () {
      test('handles player with no stats (did not play)', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Bench Player',
          jerseyNumber: 99,
          position: 'L',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 0,
          errors: 0,
          attempts: 0,
          blocks: 0,
          aces: 0,
        );

        expect(performance.totalPoints, equals(0));
        expect(performance.attackEfficiency, equals(0.0));
        expect(performance.servicePressure, equals(0.0));
      });

      test('handles extremely high efficiency (all kills, no errors)', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Perfect Player',
          jerseyNumber: 1,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 20,
          errors: 0,
          attempts: 20,
          blocks: 0,
          aces: 0,
        );

        expect(performance.attackEfficiency, equals(1.0));
        expect(performance.killPercentage, equals(1.0));
      });

      test('handles negative efficiency (more errors than kills)', () {
        const player = MatchPlayer(
          id: '1',
          name: 'Struggling Player',
          jerseyNumber: 2,
          position: 'OH',
        );

        final performance = PlayerPerformance.fromPlayerStats(
          player: player,
          kills: 2,
          errors: 8,
          attempts: 15,
          blocks: 0,
          aces: 0,
        );

        // (2 - 8) / 15 = -0.4
        expect(performance.attackEfficiency, closeTo(-0.4, 0.001));
      });
    });
  });
}
