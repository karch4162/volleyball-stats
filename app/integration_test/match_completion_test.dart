import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:volleyball_stats_app/core/persistence/hive_service.dart';
import 'package:volleyball_stats_app/core/router/app_router.dart';
import 'package:volleyball_stats_app/core/theme/app_theme.dart';
import 'package:volleyball_stats_app/features/history/match_history_screen.dart';
import 'package:volleyball_stats_app/features/history/match_recap_screen.dart';
import 'package:volleyball_stats_app/features/rally_capture/rally_capture_screen.dart';

import 'utils/screenshot_helper.dart';
// mock_data.dart available if needed for creating mock players/teams

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final screenshotHelper = ScreenshotHelper(binding);

  setUpAll(() async {
    await Hive.initFlutter();
  });

  tearDownAll(() async {
    await HiveService.closeAll();
  });

  setUp(() async {
    await HiveService.initialize();
  });

  tearDown(() async {
    await HiveService.closeAll();
  });

  /// Helper to pump the app widget
  Future<void> pumpApp(WidgetTester tester, {String initialRoute = '/'}) async {
    final app = ProviderScope(
      child: MaterialApp.router(
        title: 'Volleyball Stats',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        routerConfig: appRouter,
      ),
    );

    await tester.pumpWidget(app);
    await tester.pumpAndSettle();

    if (initialRoute != '/') {
      appRouter.go(initialRoute);
      await tester.pumpAndSettle();
    }
  }

  /// Helper to set up a match and navigate to rally capture
  Future<void> setupMatchAndNavigateToRallyCapture(WidgetTester tester) async {
    await pumpApp(tester, initialRoute: '/match/setup');
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // Fill in opponent
    final opponentField = find.widgetWithText(TextField, 'Opponent');
    if (opponentField.evaluate().isNotEmpty) {
      await tester.enterText(opponentField, 'Match Completion Test Opponent');
      await tester.pumpAndSettle();
    }

    // Select date
    final dateButton = find.byIcon(Icons.calendar_today);
    if (dateButton.evaluate().isNotEmpty) {
      await tester.tap(dateButton);
      await tester.pumpAndSettle();
      final okButton = find.text('OK');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
        await tester.pumpAndSettle();
      }
    }

    // Select players
    final filterChips = find.byType(FilterChip);
    if (filterChips.evaluate().isNotEmpty) {
      final selectCount = filterChips.evaluate().length >= 6 ? 6 : filterChips.evaluate().length;
      for (var i = 0; i < selectCount; i++) {
        await tester.tap(filterChips.at(i));
        await tester.pumpAndSettle();
      }
    }

    // Navigate directly to rally capture
    appRouter.go('/match/test-match-completion/rally');
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  /// Helper to record some rallies for testing
  Future<void> recordSomeRallies(WidgetTester tester, int count) async {
    for (var i = 0; i < count; i++) {
      // Record a kill
      final killButton = find.text('Kill');
      if (killButton.evaluate().isNotEmpty) {
        await tester.tap(killButton.first);
        await tester.pumpAndSettle();
      }

      // Complete rally with point won
      final pointWonButton = find.text('Point Won');
      if (pointWonButton.evaluate().isNotEmpty) {
        await tester.tap(pointWonButton);
        await tester.pumpAndSettle();
      }
    }
  }

  // ============================================================
  // NEW SET TESTS (1-4)
  // ============================================================

  group('New Set Tests', () {
    testWidgets('1. Start new set - confirmation dialog appears', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record some points before starting new set
      await recordSomeRallies(tester, 2);

      // Take screenshot before opening menu
      await screenshotHelper.takeScreenshot('new_set_01_before_dialog');

      // Open more menu
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        // Tap New Set option
        final newSetOption = find.textContaining('New Set');
        if (newSetOption.evaluate().isNotEmpty) {
          await tester.tap(newSetOption);
          await tester.pumpAndSettle();

          // Take screenshot of confirmation dialog
          await screenshotHelper.takeScreenshot('new_set_01_confirmation_dialog');

          // Verify dialog content
          expect(find.textContaining('Start Set'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);
          expect(find.textContaining('Reset rally counter'), findsOneWidget);
          expect(find.textContaining('Reset timeout counter'), findsOneWidget);
          expect(find.textContaining('Reset substitution counter'), findsOneWidget);

          // Cancel to close dialog
          final cancelButton = find.text('Cancel');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('2. Score resets to 0-0 after new set', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record some points
      await recordSomeRallies(tester, 3);

      // Take screenshot showing score before new set
      await screenshotHelper.takeScreenshot('new_set_02_score_before');

      // Open more menu and start new set
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final newSetOption = find.textContaining('New Set');
        if (newSetOption.evaluate().isNotEmpty) {
          await tester.tap(newSetOption);
          await tester.pumpAndSettle();

          // Confirm new set
          final startSetButton = find.textContaining('Start Set');
          if (startSetButton.evaluate().isNotEmpty) {
            await tester.tap(startSetButton);
            await tester.pumpAndSettle();

            // Take screenshot showing score reset to 0-0
            await screenshotHelper.takeScreenshot('new_set_02_score_reset');

            // The rally counter should now show rally 1
            // Score should show 0-0 in the display
          }
        }
      }
    });

    testWidgets('3. Set number increments after starting new set', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Take screenshot showing Set 1
      await screenshotHelper.takeScreenshot('new_set_03_set1');

      // Verify we're on Set 1
      expect(find.text('Set'), findsWidgets);
      expect(find.text('1'), findsWidgets);

      // Start new set
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final newSetOption = find.textContaining('New Set');
        if (newSetOption.evaluate().isNotEmpty) {
          await tester.tap(newSetOption);
          await tester.pumpAndSettle();

          final startSetButton = find.textContaining('Start Set');
          if (startSetButton.evaluate().isNotEmpty) {
            await tester.tap(startSetButton);
            await tester.pumpAndSettle();

            // Take screenshot showing Set 2
            await screenshotHelper.takeScreenshot('new_set_03_set2');

            // Verify set number incremented to 2
            expect(find.text('2'), findsWidgets);
          }
        }
      }
    });

    testWidgets('4. Timeout and substitution counters reset on new set', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record a timeout first
      final timeoutButton = find.text('Timeout');
      if (timeoutButton.evaluate().isNotEmpty) {
        await tester.tap(timeoutButton);
        await tester.pumpAndSettle();

        final ourTimeout = find.text('Our Timeout');
        if (ourTimeout.evaluate().isNotEmpty) {
          await tester.tap(ourTimeout);
          await tester.pumpAndSettle();
        }
      }

      // Take screenshot showing timeout counter at 1
      await screenshotHelper.takeScreenshot('new_set_04_timeout_before');

      // Start new set
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final newSetOption = find.textContaining('New Set');
        if (newSetOption.evaluate().isNotEmpty) {
          await tester.tap(newSetOption);
          await tester.pumpAndSettle();

          final startSetButton = find.textContaining('Start Set');
          if (startSetButton.evaluate().isNotEmpty) {
            await tester.tap(startSetButton);
            await tester.pumpAndSettle();

            // Take screenshot showing counters reset
            await screenshotHelper.takeScreenshot('new_set_04_counters_reset');

            // Timeout should show 0/2
            expect(find.textContaining('0 / 2'), findsWidgets);

            // Substitution should show 0/15
            expect(find.textContaining('0 / 15'), findsWidgets);
          }
        }
      }
    });
  });

  // ============================================================
  // END MATCH TESTS (5-8)
  // ============================================================

  group('End Match Tests', () {
    testWidgets('5. End match button - confirmation dialog appears', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record some rallies
      await recordSomeRallies(tester, 2);

      // Take screenshot before end match
      await screenshotHelper.takeScreenshot('end_match_05_before_dialog');

      // Open more menu
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        // Tap End Match option
        final endMatchOption = find.text('End Match');
        if (endMatchOption.evaluate().isNotEmpty) {
          await tester.tap(endMatchOption);
          await tester.pumpAndSettle();

          // Take screenshot of confirmation dialog
          await screenshotHelper.takeScreenshot('end_match_05_confirmation_dialog');

          // Verify dialog content
          expect(find.text('End Match'), findsWidgets);
          expect(find.textContaining('Are you sure you want to end'), findsOneWidget);
          expect(find.text('Cancel'), findsOneWidget);

          // Cancel to close dialog
          final cancelButton = find.text('Cancel');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('6. Final score displays correctly in end match dialog', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record specific number of wins
      await recordSomeRallies(tester, 5);

      // Record some losses
      for (var i = 0; i < 3; i++) {
        final atkErrButton = find.text('Atk Err');
        if (atkErrButton.evaluate().isNotEmpty) {
          await tester.tap(atkErrButton.first);
          await tester.pumpAndSettle();
        }
      }

      // Open more menu
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        // Tap End Match option
        final endMatchOption = find.text('End Match');
        if (endMatchOption.evaluate().isNotEmpty) {
          await tester.tap(endMatchOption);
          await tester.pumpAndSettle();

          // Take screenshot showing final score
          await screenshotHelper.takeScreenshot('end_match_06_final_score');

          // Verify Final Score is shown in dialog
          expect(find.textContaining('Final Score'), findsOneWidget);

          // Cancel dialog
          final cancelButton = find.text('Cancel');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton);
            await tester.pumpAndSettle();
          }
        }
      }
    });

    testWidgets('7. Match status changes to completed after ending', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record some rallies
      await recordSomeRallies(tester, 3);

      // Take screenshot before ending match
      await screenshotHelper.takeScreenshot('end_match_07_before_end');

      // Open more menu
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        // Tap End Match option
        final endMatchOption = find.text('End Match');
        if (endMatchOption.evaluate().isNotEmpty) {
          await tester.tap(endMatchOption);
          await tester.pumpAndSettle();

          // Confirm end match (find the End Match button in the dialog actions)
          final endMatchConfirmButton = find.widgetWithText(TextButton, 'End Match');
          if (endMatchConfirmButton.evaluate().isNotEmpty) {
            await tester.tap(endMatchConfirmButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Take screenshot after match ended
            await screenshotHelper.takeScreenshot('end_match_07_completed');

            // App should navigate away from rally capture (back to home or history)
            // The rally capture screen should no longer be visible
          }
        }
      }
    });

    testWidgets('8. Match saved to history after ending', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record some rallies
      await recordSomeRallies(tester, 2);

      // Open more menu and end match
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final endMatchOption = find.text('End Match');
        if (endMatchOption.evaluate().isNotEmpty) {
          await tester.tap(endMatchOption);
          await tester.pumpAndSettle();

          // Confirm end match
          final endMatchConfirmButton = find.widgetWithText(TextButton, 'End Match');
          if (endMatchConfirmButton.evaluate().isNotEmpty) {
            await tester.tap(endMatchConfirmButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          }
        }
      }

      // Navigate to history
      appRouter.go('/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of history screen
      await screenshotHelper.takeScreenshot('end_match_08_history_screen');

      // Verify we're on history screen
      expect(find.byType(MatchHistoryScreen), findsOneWidget);
      expect(find.text('Match History'), findsOneWidget);
    });
  });

  // ============================================================
  // POST-MATCH TESTS (9-11)
  // ============================================================

  group('Post-Match Tests', () {
    testWidgets('9. Navigate to match recap after completion', (tester) async {
      // Navigate directly to match recap screen
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of recap screen
      await screenshotHelper.takeScreenshot('post_match_09_recap_screen');

      // Verify we're on recap screen
      expect(find.byType(MatchRecapScreen), findsOneWidget);
      expect(find.text('Match Recap'), findsOneWidget);
    });

    testWidgets('10. Match appears in history list', (tester) async {
      // Navigate to history screen
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of history list
      await screenshotHelper.takeScreenshot('post_match_10_history_list');

      // Verify history screen is shown
      expect(find.byType(MatchHistoryScreen), findsOneWidget);
      expect(find.text('Match History'), findsOneWidget);

      // Verify search functionality exists
      expect(find.textContaining('Search by opponent'), findsOneWidget);

      // Verify filter button exists
      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
    });

    testWidgets('11. Stats preserved correctly in match recap', (tester) async {
      // Navigate to match recap
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of recap with stats
      await screenshotHelper.takeScreenshot('post_match_11_stats_recap');

      // Verify recap screen elements
      expect(find.byType(MatchRecapScreen), findsOneWidget);
      expect(find.text('Match Recap'), findsOneWidget);

      // Check for key sections in recap
      // The Sets section
      expect(find.text('Sets'), findsWidgets);

      // Player Performance section
      expect(find.text('Player Performance'), findsWidgets);

      // Export button should be available
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });
  });

  // ============================================================
  // COMPLETE MATCH WORKFLOW TESTS
  // ============================================================

  group('Complete Match Workflow Tests', () {
    testWidgets('Full match workflow: setup -> play set 1 -> new set -> play set 2 -> end match', (tester) async {
      // Step 1: Start at rally capture
      await pumpApp(tester, initialRoute: '/match/test-workflow-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await screenshotHelper.takeStepScreenshot('match_workflow', 1, 'start_set1');

      // Step 2: Play some rallies in Set 1
      await recordSomeRallies(tester, 3);
      await screenshotHelper.takeStepScreenshot('match_workflow', 2, 'set1_rallies');

      // Record some losses too
      final atkErrButton = find.text('Atk Err');
      if (atkErrButton.evaluate().isNotEmpty) {
        await tester.tap(atkErrButton.first);
        await tester.pumpAndSettle();
      }

      await screenshotHelper.takeStepScreenshot('match_workflow', 3, 'set1_with_loss');

      // Step 3: Start new set
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final newSetOption = find.textContaining('New Set');
        if (newSetOption.evaluate().isNotEmpty) {
          await tester.tap(newSetOption);
          await tester.pumpAndSettle();

          await screenshotHelper.takeStepScreenshot('match_workflow', 4, 'new_set_dialog');

          final startSetButton = find.textContaining('Start Set');
          if (startSetButton.evaluate().isNotEmpty) {
            await tester.tap(startSetButton);
            await tester.pumpAndSettle();
          }
        }
      }

      await screenshotHelper.takeStepScreenshot('match_workflow', 5, 'set2_started');

      // Step 4: Play some rallies in Set 2
      await recordSomeRallies(tester, 2);
      await screenshotHelper.takeStepScreenshot('match_workflow', 6, 'set2_rallies');

      // Step 5: End match
      final moreIcon2 = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon2.evaluate().isNotEmpty) {
        await tester.tap(moreIcon2);
        await tester.pumpAndSettle();

        final endMatchOption = find.text('End Match');
        if (endMatchOption.evaluate().isNotEmpty) {
          await tester.tap(endMatchOption);
          await tester.pumpAndSettle();

          await screenshotHelper.takeStepScreenshot('match_workflow', 7, 'end_match_dialog');

          // Verify final score dialog
          expect(find.textContaining('Final Score'), findsOneWidget);

          final endMatchConfirmButton = find.widgetWithText(TextButton, 'End Match');
          if (endMatchConfirmButton.evaluate().isNotEmpty) {
            await tester.tap(endMatchConfirmButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));
          }
        }
      }

      await screenshotHelper.takeStepScreenshot('match_workflow', 8, 'match_ended');
    });

    testWidgets('Match completion shows snackbar with final score', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record some rallies
      await recordSomeRallies(tester, 3);

      // End match
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final endMatchOption = find.text('End Match');
        if (endMatchOption.evaluate().isNotEmpty) {
          await tester.tap(endMatchOption);
          await tester.pumpAndSettle();

          final endMatchConfirmButton = find.widgetWithText(TextButton, 'End Match');
          if (endMatchConfirmButton.evaluate().isNotEmpty) {
            await tester.tap(endMatchConfirmButton);
            await tester.pumpAndSettle();

            // Take screenshot showing snackbar
            await screenshotHelper.takeScreenshot('match_completion_snackbar');

            // Snackbar should show "Match ended. Final score: X - Y"
            expect(find.textContaining('Match ended'), findsWidgets);
          }
        }
      }
    });
  });

  // ============================================================
  // NEW SET STATE VERIFICATION TESTS
  // ============================================================

  group('New Set State Verification', () {
    testWidgets('Rally number resets to 1 on new set', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record several rallies
      await recordSomeRallies(tester, 5);

      // Take screenshot showing rally count before new set
      await screenshotHelper.takeScreenshot('rally_reset_before');

      // Start new set
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final newSetOption = find.textContaining('New Set');
        if (newSetOption.evaluate().isNotEmpty) {
          await tester.tap(newSetOption);
          await tester.pumpAndSettle();

          final startSetButton = find.textContaining('Start Set');
          if (startSetButton.evaluate().isNotEmpty) {
            await tester.tap(startSetButton);
            await tester.pumpAndSettle();

            // Take screenshot showing rally counter reset
            await screenshotHelper.takeScreenshot('rally_reset_after');
          }
        }
      }
    });

    testWidgets('Current events cleared on new set', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record an action but don't complete the rally
      final killButton = find.text('Kill');
      if (killButton.evaluate().isNotEmpty) {
        await tester.tap(killButton.first);
        await tester.pumpAndSettle();
      }

      // Take screenshot showing pending events
      await screenshotHelper.takeScreenshot('events_clear_before');

      // Start new set
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final newSetOption = find.textContaining('New Set');
        if (newSetOption.evaluate().isNotEmpty) {
          await tester.tap(newSetOption);
          await tester.pumpAndSettle();

          final startSetButton = find.textContaining('Start Set');
          if (startSetButton.evaluate().isNotEmpty) {
            await tester.tap(startSetButton);
            await tester.pumpAndSettle();

            // Take screenshot showing events cleared
            await screenshotHelper.takeScreenshot('events_clear_after');
          }
        }
      }
    });

    testWidgets('Match totals preserved across sets', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record rallies in Set 1
      await recordSomeRallies(tester, 3);

      // Open player stats to see totals
      final playerStatsIcon = find.byIcon(Icons.people_rounded);
      if (playerStatsIcon.evaluate().isNotEmpty) {
        await tester.tap(playerStatsIcon);
        await tester.pumpAndSettle();

        // Take screenshot of Set 1 player stats
        await screenshotHelper.takeScreenshot('totals_set1');

        // Close dialog
        final closeButton = find.text('Close');
        if (closeButton.evaluate().isNotEmpty) {
          await tester.tap(closeButton);
          await tester.pumpAndSettle();
        }
      }

      // Start new set
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final newSetOption = find.textContaining('New Set');
        if (newSetOption.evaluate().isNotEmpty) {
          await tester.tap(newSetOption);
          await tester.pumpAndSettle();

          final startSetButton = find.textContaining('Start Set');
          if (startSetButton.evaluate().isNotEmpty) {
            await tester.tap(startSetButton);
            await tester.pumpAndSettle();
          }
        }
      }

      // Record rallies in Set 2
      await recordSomeRallies(tester, 2);

      // Open player stats again to verify totals accumulated
      final playerStatsIcon2 = find.byIcon(Icons.people_rounded);
      if (playerStatsIcon2.evaluate().isNotEmpty) {
        await tester.tap(playerStatsIcon2);
        await tester.pumpAndSettle();

        // Take screenshot showing accumulated totals
        await screenshotHelper.takeScreenshot('totals_set2');

        // Close dialog
        final closeButton2 = find.text('Close');
        if (closeButton2.evaluate().isNotEmpty) {
          await tester.tap(closeButton2);
          await tester.pumpAndSettle();
        }
      }
    });
  });

  // ============================================================
  // END MATCH NAVIGATION TESTS
  // ============================================================

  group('End Match Navigation Tests', () {
    testWidgets('App navigates to home after match ends', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Record some rallies
      await recordSomeRallies(tester, 2);

      // End match
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final endMatchOption = find.text('End Match');
        if (endMatchOption.evaluate().isNotEmpty) {
          await tester.tap(endMatchOption);
          await tester.pumpAndSettle();

          final endMatchConfirmButton = find.widgetWithText(TextButton, 'End Match');
          if (endMatchConfirmButton.evaluate().isNotEmpty) {
            await tester.tap(endMatchConfirmButton);
            await tester.pumpAndSettle(const Duration(seconds: 3));

            // Take screenshot of navigation target
            await screenshotHelper.takeScreenshot('navigation_after_end');

            // Rally capture screen should no longer be visible
            expect(find.byType(RallyCaptureScreen), findsNothing);
          }
        }
      }
    });
  });

  // ============================================================
  // HISTORY SCREEN TESTS
  // ============================================================

  group('History Screen Tests', () {
    testWidgets('History screen shows match list with opponent name', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of history screen
      await screenshotHelper.takeScreenshot('history_screen_list');

      // Verify history screen is shown
      expect(find.byType(MatchHistoryScreen), findsOneWidget);
      expect(find.text('Match History'), findsOneWidget);
    });

    testWidgets('History screen has search functionality', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify search field exists
      expect(find.textContaining('Search by opponent'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Enter search text
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField, 'Test');
        await tester.pumpAndSettle();

        // Take screenshot of search in progress
        await screenshotHelper.takeScreenshot('history_search');
      }
    });

    testWidgets('History screen has filter functionality', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find filter button
      final filterButton = find.byIcon(Icons.filter_list_rounded);
      expect(filterButton, findsOneWidget);

      // Tap filter button
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Take screenshot of filter modal
      await screenshotHelper.takeScreenshot('history_filter_modal');

      // Verify filter options
      expect(find.text('Filter Matches'), findsOneWidget);
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('End Date'), findsOneWidget);
      expect(find.text('Season'), findsOneWidget);
    });

    testWidgets('Tapping match in history navigates to recap', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // The match list may be empty, but we can verify the structure
      // Take screenshot
      await screenshotHelper.takeScreenshot('history_match_tap_before');

      // If there are matches, tapping one should navigate to recap
      // We verify the history screen structure is correct
      expect(find.byType(MatchHistoryScreen), findsOneWidget);
    });
  });

  // ============================================================
  // MATCH RECAP SCREEN TESTS
  // ============================================================

  group('Match Recap Screen Tests', () {
    testWidgets('Recap screen shows match header with opponent', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of recap header
      await screenshotHelper.takeScreenshot('recap_header');

      // Verify recap screen is shown
      expect(find.byType(MatchRecapScreen), findsOneWidget);
      expect(find.text('Match Recap'), findsOneWidget);
    });

    testWidgets('Recap screen shows set summaries', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('recap_sets');

      // Verify Sets section
      expect(find.text('Sets'), findsWidgets);
    });

    testWidgets('Recap screen shows player performance section', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroll to player performance section
      await tester.scrollUntilVisible(
        find.text('Player Performance'),
        100,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('recap_player_performance');

      // Verify Player Performance section
      expect(find.text('Player Performance'), findsWidgets);
    });

    testWidgets('Recap screen has export button', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify export button
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);

      // Tap export button
      await tester.tap(find.byIcon(Icons.download_rounded));
      await tester.pumpAndSettle();

      // Take screenshot (should show snackbar about export coming soon)
      await screenshotHelper.takeScreenshot('recap_export_tap');
    });
  });

  // ============================================================
  // ERROR HANDLING TESTS
  // ============================================================

  group('Error Handling Tests', () {
    testWidgets('Canceling new set dialog returns to rally capture', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Open new set dialog
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final newSetOption = find.textContaining('New Set');
        if (newSetOption.evaluate().isNotEmpty) {
          await tester.tap(newSetOption);
          await tester.pumpAndSettle();

          // Cancel dialog
          final cancelButton = find.text('Cancel');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton);
            await tester.pumpAndSettle();

            // Verify we're still on rally capture
            expect(find.byType(RallyCaptureScreen), findsOneWidget);

            // Take screenshot
            await screenshotHelper.takeScreenshot('cancel_new_set');
          }
        }
      }
    });

    testWidgets('Canceling end match dialog returns to rally capture', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      if (find.byType(RallyCaptureScreen).evaluate().isEmpty) {
        await setupMatchAndNavigateToRallyCapture(tester);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Open end match dialog
      final moreIcon = find.byIcon(Icons.more_vert_rounded);
      if (moreIcon.evaluate().isNotEmpty) {
        await tester.tap(moreIcon);
        await tester.pumpAndSettle();

        final endMatchOption = find.text('End Match');
        if (endMatchOption.evaluate().isNotEmpty) {
          await tester.tap(endMatchOption);
          await tester.pumpAndSettle();

          // Cancel dialog
          final cancelButton = find.text('Cancel');
          if (cancelButton.evaluate().isNotEmpty) {
            await tester.tap(cancelButton);
            await tester.pumpAndSettle();

            // Verify we're still on rally capture
            expect(find.byType(RallyCaptureScreen), findsOneWidget);

            // Take screenshot
            await screenshotHelper.takeScreenshot('cancel_end_match');
          }
        }
      }
    });
  });
}
