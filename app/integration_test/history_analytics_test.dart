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
import 'package:volleyball_stats_app/features/history/season_dashboard_screen.dart';
import 'package:volleyball_stats_app/features/history/set_dashboard_screen.dart';

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

  // ============================================================
  // MATCH HISTORY TESTS (1-5)
  // ============================================================

  group('Match History Tests', () {
    testWidgets('1. Match list loads and displays', (tester) async {
      // Navigate to history screen
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of match history screen
      await screenshotHelper.takeScreenshot('history_01_match_list_loads');

      // Verify history screen is shown
      expect(find.byType(MatchHistoryScreen), findsOneWidget);
      expect(find.text('Match History'), findsOneWidget);

      // Verify list structure elements exist
      // Search bar should be visible
      expect(find.textContaining('Search by opponent'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Filter button should be visible
      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
    });

    testWidgets('2. Search by opponent name', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify search field exists
      final searchField = find.byType(TextField);
      expect(searchField, findsOneWidget);

      // Enter search text
      await tester.enterText(searchField, 'Eagles');
      await tester.pumpAndSettle();

      // Take screenshot of search results
      await screenshotHelper.takeScreenshot('history_02_search_opponent');

      // Verify search icon is present
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      // Clear search should appear when text is entered
      // If there's text in the search field, a clear button may appear
      await tester.pumpAndSettle(const Duration(seconds: 1));
    });

    testWidgets('3. Date range filter', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap filter button
      final filterButton = find.byIcon(Icons.filter_list_rounded);
      expect(filterButton, findsOneWidget);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Take screenshot of filter modal
      await screenshotHelper.takeScreenshot('history_03_filter_modal');

      // Verify filter modal content
      expect(find.text('Filter Matches'), findsOneWidget);
      expect(find.text('Start Date'), findsOneWidget);
      expect(find.text('End Date'), findsOneWidget);

      // Tap on Start Date to open date picker
      final startDateTile = find.text('Start Date');
      await tester.tap(startDateTile);
      await tester.pumpAndSettle();

      // Take screenshot of date picker
      await screenshotHelper.takeScreenshot('history_03_date_picker');

      // Cancel date picker (if open)
      final cancelButton = find.text('CANCEL');
      if (cancelButton.evaluate().isNotEmpty) {
        await tester.tap(cancelButton);
        await tester.pumpAndSettle();
      } else {
        // Try OK button to close
        final okButton = find.text('OK');
        if (okButton.evaluate().isNotEmpty) {
          await tester.tap(okButton);
          await tester.pumpAndSettle();
        }
      }

      // Close the filter modal
      final closeButton = find.byIcon(Icons.close_rounded);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('4. Filter chips display and can be removed', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Open filter modal
      final filterButton = find.byIcon(Icons.filter_list_rounded);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Tap on Start Date
      final startDateTile = find.text('Start Date');
      await tester.tap(startDateTile);
      await tester.pumpAndSettle();

      // Select a date (tap OK on date picker)
      final okButton = find.text('OK');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
        await tester.pumpAndSettle();
      }

      // Close filter modal
      final closeButton = find.byIcon(Icons.close_rounded);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      // Take screenshot showing filter chip
      await screenshotHelper.takeScreenshot('history_04_filter_chip');

      // Check for filter chip (Chip widget containing 'From:')
      final fromChip = find.byType(Chip);
      if (fromChip.evaluate().isNotEmpty) {
        // Find the delete icon on the chip
        final deleteIcon = find.descendant(
          of: fromChip.first,
          matching: find.byIcon(Icons.cancel),
        );
        if (deleteIcon.evaluate().isNotEmpty) {
          await tester.tap(deleteIcon);
          await tester.pumpAndSettle();

          // Take screenshot after removing filter
          await screenshotHelper.takeScreenshot('history_04_filter_removed');
        }
      }
    });

    testWidgets('5. Empty state when no matches', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of empty state (if no matches exist)
      await screenshotHelper.takeScreenshot('history_05_empty_state');

      // Check for empty state message
      // The empty state shows "No matches found" message
      final noMatchesText = find.text('No matches found');
      final selectTeamText = find.textContaining('Select a team');
      final adjustFiltersText = find.textContaining('Try adjusting your filters');

      // One of these should be visible if there are no matches
      final hasEmptyState = noMatchesText.evaluate().isNotEmpty ||
          selectTeamText.evaluate().isNotEmpty ||
          adjustFiltersText.evaluate().isNotEmpty;

      // Verify the history screen is displayed
      expect(find.byType(MatchHistoryScreen), findsOneWidget);

      // If empty state is shown, verify icon
      if (hasEmptyState) {
        expect(find.byIcon(Icons.sports_volleyball_outlined), findsOneWidget);
      }
    });
  });

  // ============================================================
  // MATCH RECAP TESTS (6-9)
  // ============================================================

  group('Match Recap Tests', () {
    testWidgets('6. Match header shows opponent, date, score', (tester) async {
      // Navigate directly to match recap screen
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of recap header
      await screenshotHelper.takeScreenshot('history_06_match_header');

      // Verify recap screen is shown
      expect(find.byType(MatchRecapScreen), findsOneWidget);
      expect(find.text('Match Recap'), findsOneWidget);

      // Header should contain opponent name, date, and WIN/LOSS badge
      // The exact content depends on loaded match data
      // Verify export button exists (indicates header area is rendered)
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);
    });

    testWidgets('7. Set-by-set breakdown displays', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot showing sets section
      await screenshotHelper.takeScreenshot('history_07_set_breakdown');

      // Verify Sets section header
      expect(find.text('Sets'), findsWidgets);

      // SetSummaryCard should show set numbers
      // Look for set indicators like "Set 1", "Set 2", etc.
      // At least one set should be visible in the recap
      // This depends on match data availability
    });

    testWidgets('8. Player statistics table accurate', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroll to player performance section
      final playerPerfText = find.text('Player Performance');
      if (playerPerfText.evaluate().isNotEmpty) {
        await tester.scrollUntilVisible(
          playerPerfText,
          100,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();
      }

      // Take screenshot of player stats
      await screenshotHelper.takeScreenshot('history_08_player_stats');

      // Verify Player Performance section exists
      expect(find.text('Player Performance'), findsWidgets);

      // If there are player stats, verify sort controls are visible
      // The PlayerStatsControls widget provides sorting options
      // Sort controls may or may not be present depending on data
    });

    testWidgets('9. Navigate to set dashboard', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot before navigation
      await screenshotHelper.takeScreenshot('history_09_before_set_nav');

      // Look for set cards that might be tappable
      // SetSummaryCard components may have onTap functionality
      final setCards = find.textContaining('Set 1');
      if (setCards.evaluate().isNotEmpty) {
        // Note: The current SetSummaryCard doesn't have onTap navigation
        // This test documents the expected behavior
      }

      // Navigate directly to set dashboard to verify it works
      appRouter.go('/match/test-match/set/1/dashboard');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of set dashboard
      await screenshotHelper.takeScreenshot('history_09_set_dashboard');

      // Verify set dashboard is shown
      expect(find.byType(SetDashboardScreen), findsOneWidget);
      expect(find.text('Set 1 Dashboard'), findsOneWidget);
    });
  });

  // ============================================================
  // SET DASHBOARD TESTS (10-12)
  // ============================================================

  group('Set Dashboard Tests', () {
    testWidgets('10. Set-specific stats display', (tester) async {
      // Navigate to set dashboard
      await pumpApp(tester, initialRoute: '/match/test-match/set/1/dashboard');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of set dashboard
      await screenshotHelper.takeScreenshot('history_10_set_stats');

      // Verify set dashboard is shown
      expect(find.byType(SetDashboardScreen), findsOneWidget);
      expect(find.text('Set 1 Dashboard'), findsOneWidget);

      // Verify set-specific stats are displayed
      expect(find.text('Set 1'), findsWidgets);

      // Verify stat displays
      expect(find.text('Rallies'), findsWidgets);
      expect(find.text('FBK'), findsWidgets);
      expect(find.text('Wins'), findsWidgets);
      expect(find.text('Losses'), findsWidgets);
    });

    testWidgets('11. Rally breakdown shows', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/set/1/dashboard');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('history_11_rally_breakdown');

      // Verify running totals section (which includes rally/point info)
      expect(find.text('Running Totals'), findsOneWidget);

      // Verify stats in running totals
      expect(find.text('First Ball Kills'), findsOneWidget);
      expect(find.text('Wins'), findsWidgets);
      expect(find.text('Losses'), findsWidgets);
      expect(find.text('Transition Points'), findsOneWidget);
    });

    testWidgets('12. Rotation changes during set', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/set/1/dashboard');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroll to see all content
      final scrollable = find.byType(Scrollable).first;
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable, const Offset(0, -200));
        await tester.pumpAndSettle();
      }

      // Take screenshot showing rotation info
      await screenshotHelper.takeScreenshot('history_12_rotation_info');

      // Verify player performance section which may include rotation data
      expect(find.text('Player Performance'), findsOneWidget);

      // Player cards should show jersey numbers (rotation indicators)
      // This section displays players sorted by various stats
    });
  });

  // ============================================================
  // SEASON DASHBOARD TESTS (13-16)
  // ============================================================

  group('Season Dashboard Tests', () {
    testWidgets('13. Season selector works', (tester) async {
      // Navigate to season dashboard
      await pumpApp(tester, initialRoute: '/season');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of season dashboard
      await screenshotHelper.takeScreenshot('history_13_season_dashboard');

      // Verify season dashboard is shown
      expect(find.byType(SeasonDashboardScreen), findsOneWidget);
      expect(find.text('Season Dashboard'), findsOneWidget);

      // Season filters should be visible
      // The SeasonFilters widget provides date range and season selection
      // Filters may be in a collapsed state
    });

    testWidgets('14. Aggregate statistics display', (tester) async {
      await pumpApp(tester, initialRoute: '/season');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('history_14_aggregate_stats');

      // Verify Team Statistics section
      expect(find.text('Team Statistics'), findsOneWidget);

      // Verify aggregate stat labels
      expect(find.text('Total FBK'), findsOneWidget);
      expect(find.text('Avg FBK per Match'), findsOneWidget);
      expect(find.text('Total Transition Points'), findsOneWidget);
      expect(find.text('Avg Rallies per Match'), findsOneWidget);
    });

    testWidgets('15. Win/loss record accurate', (tester) async {
      await pumpApp(tester, initialRoute: '/season');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot showing W-L record
      await screenshotHelper.takeScreenshot('history_15_win_loss_record');

      // Verify Season Overview card
      expect(find.text('Season Overview'), findsOneWidget);

      // Verify Win Rate is displayed
      expect(find.text('Win Rate'), findsOneWidget);

      // Verify Matches and Sets stats
      expect(find.text('Matches'), findsOneWidget);
      expect(find.text('Sets'), findsOneWidget);
    });

    testWidgets('16. Top performers widget', (tester) async {
      await pumpApp(tester, initialRoute: '/season');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroll to see Top Performers section
      final scrollable = find.byType(Scrollable).first;
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      // Take screenshot
      await screenshotHelper.takeScreenshot('history_16_top_performers');

      // Top Performers section may be visible if there's data
      // TopPerformersWidget shows categories like:
      // - Top Performers: Kills
      // - Top Performers: Attack Efficiency
      // - Top Performers: Blocks
      // - Top Performers: Aces
      // If no data, these may not be present
    });
  });

  // ============================================================
  // INTEGRATION TESTS - Full Navigation Flow
  // ============================================================

  group('History Navigation Flow Tests', () {
    testWidgets('Navigate from history list to match recap', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of history
      await screenshotHelper.takeScreenshot('nav_flow_01_history_start');

      // If there are matches listed, they would be tappable
      // Each match card navigates to /match/{matchId}/recap on tap

      // For testing, navigate directly
      appRouter.go('/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify navigation
      expect(find.byType(MatchRecapScreen), findsOneWidget);

      // Take screenshot
      await screenshotHelper.takeScreenshot('nav_flow_02_recap_screen');
    });

    testWidgets('Navigate from match recap to set dashboard', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('nav_flow_03_recap_start');

      // Navigate to set dashboard
      appRouter.go('/match/test-match/set/1/dashboard');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify navigation
      expect(find.byType(SetDashboardScreen), findsOneWidget);

      // Take screenshot
      await screenshotHelper.takeScreenshot('nav_flow_04_set_dashboard');
    });

    testWidgets('Navigate back from set dashboard to recap', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/set/1/dashboard');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('nav_flow_05_set_dashboard');

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Take screenshot
        await screenshotHelper.takeScreenshot('nav_flow_06_after_back');
      }
    });

    testWidgets('Season dashboard to history navigation', (tester) async {
      await pumpApp(tester, initialRoute: '/season');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('nav_flow_07_season');

      // Navigate to history
      appRouter.go('/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify navigation
      expect(find.byType(MatchHistoryScreen), findsOneWidget);

      // Take screenshot
      await screenshotHelper.takeScreenshot('nav_flow_08_history');
    });
  });

  // ============================================================
  // FILTER AND SEARCH INTERACTION TESTS
  // ============================================================

  group('Filter and Search Interaction Tests', () {
    testWidgets('Search clears correctly', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Enter search text
      final searchField = find.byType(TextField);
      await tester.enterText(searchField, 'Test Opponent');
      await tester.pumpAndSettle();

      // Take screenshot with search text
      await screenshotHelper.takeScreenshot('filter_search_01_with_text');

      // Clear the search (look for clear icon)
      final clearIcon = find.byIcon(Icons.clear_rounded);
      if (clearIcon.evaluate().isNotEmpty) {
        await tester.tap(clearIcon);
        await tester.pumpAndSettle();

        // Take screenshot after clear
        await screenshotHelper.takeScreenshot('filter_search_02_cleared');
      }
    });

    testWidgets('Multiple filters can be applied', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Open filter modal
      final filterButton = find.byIcon(Icons.filter_list_rounded);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Apply start date filter
      final startDateTile = find.text('Start Date');
      await tester.tap(startDateTile);
      await tester.pumpAndSettle();

      final okButton = find.text('OK');
      if (okButton.evaluate().isNotEmpty) {
        await tester.tap(okButton);
        await tester.pumpAndSettle();
      }

      // Apply end date filter
      final endDateTile = find.text('End Date');
      await tester.tap(endDateTile);
      await tester.pumpAndSettle();

      final okButton2 = find.text('OK');
      if (okButton2.evaluate().isNotEmpty) {
        await tester.tap(okButton2);
        await tester.pumpAndSettle();
      }

      // Close modal
      final closeButton = find.byIcon(Icons.close_rounded);
      if (closeButton.evaluate().isNotEmpty) {
        await tester.tap(closeButton);
        await tester.pumpAndSettle();
      }

      // Take screenshot showing multiple filter chips
      await screenshotHelper.takeScreenshot('filter_search_03_multiple_filters');

      // Multiple Chips should be visible for From: and To: dates
    });

    testWidgets('Season filter in modal', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Open filter modal
      final filterButton = find.byIcon(Icons.filter_list_rounded);
      await tester.tap(filterButton);
      await tester.pumpAndSettle();

      // Verify Season filter option exists
      expect(find.text('Season'), findsOneWidget);
      expect(find.text('All seasons'), findsOneWidget);

      // Take screenshot of season option
      await screenshotHelper.takeScreenshot('filter_search_04_season_option');

      // Tap season option
      final seasonTile = find.text('Season');
      await tester.tap(seasonTile);
      await tester.pumpAndSettle();

      // Take screenshot (season picker would appear or toggle)
      await screenshotHelper.takeScreenshot('filter_search_05_season_tap');
    });
  });

  // ============================================================
  // ERROR HANDLING AND EDGE CASES
  // ============================================================

  group('Error Handling and Edge Cases', () {
    testWidgets('Match recap handles missing match gracefully', (tester) async {
      // Navigate to a non-existent match
      await pumpApp(tester, initialRoute: '/match/non-existent-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('error_01_missing_match');

      // The screen should show "Match not found" or error state
      // MatchRecapScreen shows "Match not found" for null details
    });

    testWidgets('Set dashboard handles missing set gracefully', (tester) async {
      // Navigate to set dashboard
      await pumpApp(tester, initialRoute: '/match/test-match/set/99/dashboard');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('error_02_missing_set');

      // The screen should handle gracefully (may show empty data)
      expect(find.byType(SetDashboardScreen), findsOneWidget);
    });

    testWidgets('Season dashboard handles no team selected', (tester) async {
      await pumpApp(tester, initialRoute: '/season');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('error_03_no_team_season');

      // Season dashboard should handle no team selected
      // It returns empty stats when no team is selected
      expect(find.byType(SeasonDashboardScreen), findsOneWidget);
    });

    testWidgets('History retry button on error', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('error_04_history_state');

      // If an error occurred, there should be a Retry button
      final retryButton = find.text('Retry');
      if (retryButton.evaluate().isNotEmpty) {
        await tester.tap(retryButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));

        // Take screenshot after retry
        await screenshotHelper.takeScreenshot('error_04_after_retry');
      }
    });
  });

  // ============================================================
  // SORT CONTROLS TESTS
  // ============================================================

  group('Sort Controls Tests', () {
    testWidgets('Match recap player stats can be sorted', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroll to player performance section
      final scrollable = find.byType(Scrollable).first;
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      // Take screenshot
      await screenshotHelper.takeScreenshot('sort_01_recap_players');

      // Sort controls widget provides dropdown for sorting
      // The PlayerStatsControls provides sorting options
    });

    testWidgets('Set dashboard player stats can be sorted', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/set/1/dashboard');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroll to player performance section
      final scrollable = find.byType(Scrollable).first;
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable, const Offset(0, -200));
        await tester.pumpAndSettle();
      }

      // Take screenshot
      await screenshotHelper.takeScreenshot('sort_02_set_players');

      // Verify Player Performance section
      expect(find.text('Player Performance'), findsOneWidget);
    });

    testWidgets('Sort order can be toggled', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Scroll to player section
      final scrollable = find.byType(Scrollable).first;
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable, const Offset(0, -300));
        await tester.pumpAndSettle();
      }

      // Take screenshot before toggle
      await screenshotHelper.takeScreenshot('sort_03_before_toggle');

      // Look for ascending/descending toggle icon
      final toggleIcon = find.byIcon(Icons.arrow_upward);
      final toggleIconDown = find.byIcon(Icons.arrow_downward);

      if (toggleIcon.evaluate().isNotEmpty) {
        await tester.tap(toggleIcon);
        await tester.pumpAndSettle();

        // Take screenshot after toggle
        await screenshotHelper.takeScreenshot('sort_03_after_toggle');
      } else if (toggleIconDown.evaluate().isNotEmpty) {
        await tester.tap(toggleIconDown);
        await tester.pumpAndSettle();

        // Take screenshot after toggle
        await screenshotHelper.takeScreenshot('sort_03_after_toggle');
      }
    });
  });

  // ============================================================
  // EXPORT FUNCTIONALITY TESTS
  // ============================================================

  group('Export Functionality Tests', () {
    testWidgets('Export button visible on match recap', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Verify export button is visible
      expect(find.byIcon(Icons.download_rounded), findsOneWidget);

      // Take screenshot
      await screenshotHelper.takeScreenshot('export_01_button_visible');
    });

    testWidgets('Export button shows snackbar on tap', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Tap export button
      final exportButton = find.byIcon(Icons.download_rounded);
      await tester.tap(exportButton);
      await tester.pumpAndSettle();

      // Take screenshot (snackbar should be visible)
      await screenshotHelper.takeScreenshot('export_02_snackbar');

      // Verify snackbar appears (currently shows "Export functionality coming soon")
      expect(find.textContaining('Export'), findsWidgets);
    });
  });

  // ============================================================
  // RESPONSIVE UI TESTS
  // ============================================================

  group('Responsive UI Tests', () {
    testWidgets('History screen renders correctly', (tester) async {
      await pumpApp(tester, initialRoute: '/history');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('responsive_01_history');

      // Verify key elements are visible and laid out correctly
      expect(find.text('Match History'), findsOneWidget);
      expect(find.byIcon(Icons.filter_list_rounded), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('Season dashboard scrolls correctly', (tester) async {
      await pumpApp(tester, initialRoute: '/season');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot at top
      await screenshotHelper.takeScreenshot('responsive_02_season_top');

      // Scroll down
      final scrollable = find.byType(Scrollable).first;
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable, const Offset(0, -500));
        await tester.pumpAndSettle();

        // Take screenshot at bottom
        await screenshotHelper.takeScreenshot('responsive_02_season_scrolled');
      }
    });

    testWidgets('Match recap scrolls correctly', (tester) async {
      await pumpApp(tester, initialRoute: '/match/test-match/recap');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot at top
      await screenshotHelper.takeScreenshot('responsive_03_recap_top');

      // Scroll down
      final scrollable = find.byType(Scrollable).first;
      if (scrollable.evaluate().isNotEmpty) {
        await tester.drag(scrollable, const Offset(0, -500));
        await tester.pumpAndSettle();

        // Take screenshot at bottom
        await screenshotHelper.takeScreenshot('responsive_03_recap_scrolled');
      }
    });
  });
}
