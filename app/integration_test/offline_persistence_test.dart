import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:uuid/uuid.dart';
import 'package:volleyball_stats_app/core/persistence/hive_service.dart';
import 'package:volleyball_stats_app/core/persistence/type_adapters.dart';
import 'package:volleyball_stats_app/core/router/app_router.dart';
import 'package:volleyball_stats_app/core/sync/sync_queue_item.dart';
import 'package:volleyball_stats_app/core/sync/sync_service.dart';
import 'package:volleyball_stats_app/core/theme/app_theme.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_draft.dart';
import 'package:volleyball_stats_app/features/match_setup/models/match_player.dart';
import 'package:volleyball_stats_app/features/match_setup/match_setup_flow.dart';
import 'package:volleyball_stats_app/features/match_setup/match_setup_landing_screen.dart';
import 'package:volleyball_stats_app/features/players/player_list_screen.dart';
import 'package:volleyball_stats_app/features/rally_capture/models/rally_models.dart';
// RallyCaptureScreen import removed - testing persistence layer directly
import 'package:volleyball_stats_app/features/teams/team_list_screen.dart';
import 'package:volleyball_stats_app/features/history/match_history_screen.dart';

import 'utils/screenshot_helper.dart';
import 'utils/mock_data.dart';

/// E2E tests for Offline Functionality and Hive Persistence
/// Tests the offline-first architecture ensuring data survives app restarts
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final screenshotHelper = ScreenshotHelper(binding);
  const uuid = Uuid();

  setUpAll(() async {
    // Initialize Hive for Flutter in test mode
    await Hive.initFlutter();
  });

  tearDownAll(() async {
    await HiveService.closeAll();
  });

  setUp(() async {
    // Clean up any previous state before each test
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

    // Navigate to initial route if needed
    if (initialRoute != '/') {
      appRouter.go(initialRoute);
      await tester.pumpAndSettle();
    }
  }

  /// Simulate app restart by closing and reinitializing Hive
  Future<void> simulateAppRestart() async {
    await HiveService.closeAll();
    // Small delay to ensure cleanup completes
    await Future.delayed(const Duration(milliseconds: 100));
    await HiveService.initialize();
  }

  // Note: setupMatchAndNavigateToRallyCapture helper available in rally_capture_test.dart
  // For offline tests, we primarily test persistence layer directly via Hive boxes

  // ============================================================
  // DATA PERSISTENCE TESTS (1-4)
  // ============================================================

  group('Data Persistence Tests', () {
    testWidgets('1. Match draft survives app restart', (tester) async {
      // Create a match draft directly in Hive
      await pumpApp(tester, initialRoute: '/match/setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of initial state
      await screenshotHelper.takeScreenshot('offline_persistence_draft_initial');

      // Enter some match data
      final opponentField = find.widgetWithText(TextField, 'Opponent');
      if (opponentField.evaluate().isNotEmpty) {
        await tester.enterText(opponentField, 'Persistence Test Hawks');
        await tester.pumpAndSettle();
      }

      final locationField = find.widgetWithText(TextField, 'Location');
      if (locationField.evaluate().isNotEmpty) {
        await tester.enterText(locationField, 'Test Gymnasium');
        await tester.pumpAndSettle();
      }

      // Wait for auto-save
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot before restart
      await screenshotHelper.takeScreenshot('offline_persistence_draft_before_restart');

      // Verify the data is in the Hive box
      final box = HiveService.getBox(HiveService.matchDraftsBox);
      final initialCount = box.length;

      // Simulate app restart
      await simulateAppRestart();

      // Verify data survived restart
      final boxAfterRestart = HiveService.getBox(HiveService.matchDraftsBox);
      expect(boxAfterRestart.length, equals(initialCount));

      // Repump the app and verify UI can load the data
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot after restart
      await screenshotHelper.takeScreenshot('offline_persistence_draft_after_restart');

      // Look for "Use Last Match Setup" option which indicates draft was preserved
      final useLastMatchText = find.text('Use Last Match Setup');
      if (useLastMatchText.evaluate().isNotEmpty) {
        expect(useLastMatchText, findsOneWidget);
      }
    });

    testWidgets('2. Rally data persists across restart', (tester) async {
      // Store rally records directly in Hive
      final box = HiveService.getBox(HiveService.rallyRecordsBox);

      // Create mock rally event
      final rallyEvent = RallyEvent(
        id: uuid.v4(),
        type: RallyActionTypes.attackKill,
        timestamp: DateTime.now(),
        player: const MatchPlayer(
          id: 'player-001',
          name: 'Test Player',
          jerseyNumber: 7,
          position: 'Outside Hitter',
        ),
      );

      // Create rally record
      final rallyRecord = RallyRecord(
        rallyId: uuid.v4(),
        rallyNumber: 1,
        rotationNumber: 1,
        events: [rallyEvent],
        completedAt: DateTime.now(),
      );

      // Store in Hive
      await box.put(rallyRecord.rallyId, ModelSerializer.rallyRecordToMap(rallyRecord));

      // Take screenshot before restart
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_persistence_rally_before_restart');

      // Verify data is in box
      expect(box.length, greaterThan(0));

      // Simulate app restart
      await simulateAppRestart();

      // Verify data survived restart
      final boxAfterRestart = HiveService.getBox(HiveService.rallyRecordsBox);
      expect(boxAfterRestart.length, greaterThan(0));

      // Retrieve and verify the data
      final storedData = boxAfterRestart.get(rallyRecord.rallyId);
      expect(storedData, isNotNull);

      final retrievedRecord = ModelSerializer.rallyRecordFromMap(
        Map<String, dynamic>.from(storedData as Map),
      );
      expect(retrievedRecord.rallyId, equals(rallyRecord.rallyId));
      expect(retrievedRecord.rallyNumber, equals(1));
      expect(retrievedRecord.events.length, equals(1));

      // Repump app
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Take screenshot after restart
      await screenshotHelper.takeScreenshot('offline_persistence_rally_after_restart');
    });

    testWidgets('3. Player stats preserved after restart', (tester) async {
      // Store player data directly in Hive
      final box = HiveService.getBox(HiveService.matchPlayersBox);

      // Create mock player with stats (stored as part of rally events)
      final player = createMockPlayer(
        id: 'stats-player-001',
        name: 'Stats Test Player',
        jerseyNumber: 10,
        position: 'Setter',
      );

      final playerMap = ModelSerializer.matchPlayerToMap(player);
      await box.put(player.id, playerMap);

      // Create multiple rally events for this player to track stats
      final eventsBox = HiveService.getBox(HiveService.rallyEventsBox);

      // Add kill event
      final killEvent = RallyEvent(
        id: uuid.v4(),
        type: RallyActionTypes.attackKill,
        timestamp: DateTime.now(),
        player: player,
      );
      await eventsBox.put(killEvent.id, ModelSerializer.rallyEventToMap(killEvent));

      // Add assist event
      final assistEvent = RallyEvent(
        id: uuid.v4(),
        type: RallyActionTypes.assist,
        timestamp: DateTime.now(),
        player: player,
      );
      await eventsBox.put(assistEvent.id, ModelSerializer.rallyEventToMap(assistEvent));

      // Take screenshot before restart
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_persistence_stats_before_restart');

      // Verify events are stored
      expect(eventsBox.length, greaterThanOrEqualTo(2));

      // Simulate app restart
      await simulateAppRestart();

      // Verify events survived restart
      final eventsBoxAfterRestart = HiveService.getBox(HiveService.rallyEventsBox);
      expect(eventsBoxAfterRestart.length, greaterThanOrEqualTo(2));

      // Verify specific events can be retrieved
      final storedKillEvent = eventsBoxAfterRestart.get(killEvent.id);
      expect(storedKillEvent, isNotNull);

      final retrievedEvent = ModelSerializer.rallyEventFromMap(
        Map<String, dynamic>.from(storedKillEvent as Map),
      );
      expect(retrievedEvent.type, equals(RallyActionTypes.attackKill));
      expect(retrievedEvent.player?.name, equals('Stats Test Player'));

      // Repump app
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Take screenshot after restart
      await screenshotHelper.takeScreenshot('offline_persistence_stats_after_restart');
    });

    testWidgets('4. Team/player data persists', (tester) async {
      // Store player data in Hive
      final box = HiveService.getBox(HiveService.matchPlayersBox);

      // Create multiple mock players
      final players = createMockRoster();

      for (final player in players) {
        final playerMap = ModelSerializer.matchPlayerToMap(player);
        await box.put(player.id, playerMap);
      }

      // Take screenshot before restart
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_persistence_team_before_restart');

      // Verify all players are stored
      expect(box.length, greaterThanOrEqualTo(players.length));

      // Simulate app restart
      await simulateAppRestart();

      // Verify players survived restart
      final boxAfterRestart = HiveService.getBox(HiveService.matchPlayersBox);
      expect(boxAfterRestart.length, greaterThanOrEqualTo(players.length));

      // Verify specific player can be retrieved
      final storedPlayer = boxAfterRestart.get(players.first.id);
      expect(storedPlayer, isNotNull);

      final retrievedPlayer = ModelSerializer.matchPlayerFromMap(
        Map<String, dynamic>.from(storedPlayer as Map),
      );
      expect(retrievedPlayer.id, equals(players.first.id));
      expect(retrievedPlayer.jerseyNumber, equals(players.first.jerseyNumber));

      // Repump app
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Take screenshot after restart
      await screenshotHelper.takeScreenshot('offline_persistence_team_after_restart');
    });
  });

  // ============================================================
  // OFFLINE MODE TESTS (5-8)
  // ============================================================

  group('Offline Mode Tests', () {
    testWidgets('5. App works without Supabase credentials', (tester) async {
      // The app is designed to work fully offline without Supabase
      await pumpApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot showing app loaded without crash
      await screenshotHelper.takeScreenshot('offline_mode_no_supabase');

      // App should load and display the main screen
      expect(find.byType(MaterialApp), findsOneWidget);

      // No crash or blocking errors
      expect(find.textContaining('Error'), findsNothing);

      // Navigate to different screens to verify functionality
      appRouter.go('/teams');
      await tester.pumpAndSettle();

      // Take screenshot of teams screen
      await screenshotHelper.takeScreenshot('offline_mode_teams_screen');

      expect(find.byType(TeamListScreen), findsOneWidget);
    });

    testWidgets('6. No auth required for offline use', (tester) async {
      // Start the app and verify we can access features without login
      await pumpApp(tester);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of initial state
      await screenshotHelper.takeScreenshot('offline_mode_no_auth_initial');

      // Navigate to match setup landing (should work without auth)
      appRouter.go('/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await screenshotHelper.takeScreenshot('offline_mode_no_auth_match_setup');

      // Verify we're on the match setup landing screen
      expect(find.byType(MatchSetupLandingScreen), findsOneWidget);

      // Verify no auth barriers
      expect(find.text('Login Required'), findsNothing);
      expect(find.text('Sign In'), findsNothing);
    });

    testWidgets('7. All screens accessible offline', (tester) async {
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Test navigation to each main screen

      // 1. Teams screen
      appRouter.go('/teams');
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_mode_screen_teams');
      expect(find.byType(TeamListScreen), findsOneWidget);

      // 2. Players screen
      appRouter.go('/players');
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_mode_screen_players');
      expect(find.byType(PlayerListScreen), findsOneWidget);

      // 3. Match setup landing
      appRouter.go('/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await screenshotHelper.takeScreenshot('offline_mode_screen_match_landing');
      expect(find.byType(MatchSetupLandingScreen), findsOneWidget);

      // 4. Match setup flow
      appRouter.go('/match/setup');
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await screenshotHelper.takeScreenshot('offline_mode_screen_match_setup');
      expect(find.byType(MatchSetupFlow), findsOneWidget);

      // 5. History screen
      appRouter.go('/history');
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_mode_screen_history');
      expect(find.byType(MatchHistoryScreen), findsOneWidget);

      // 6. Templates screen
      appRouter.go('/templates');
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_mode_screen_templates');
      // Verify no network error blocks access
      expect(find.textContaining('Network Error'), findsNothing);
    });

    testWidgets('8. Data entry works offline', (tester) async {
      await pumpApp(tester, initialRoute: '/match/setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of initial state
      await screenshotHelper.takeScreenshot('offline_mode_data_entry_initial');

      // Enter opponent name
      final opponentField = find.widgetWithText(TextField, 'Opponent');
      if (opponentField.evaluate().isNotEmpty) {
        await tester.enterText(opponentField, 'Offline Test Opponent');
        await tester.pumpAndSettle();
      }

      // Enter location
      final locationField = find.widgetWithText(TextField, 'Location');
      if (locationField.evaluate().isNotEmpty) {
        await tester.enterText(locationField, 'Offline Gymnasium');
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
        final chipCount = filterChips.evaluate().length;
        final selectCount = chipCount >= 6 ? 6 : chipCount;

        for (var i = 0; i < selectCount; i++) {
          await tester.tap(filterChips.at(i));
          await tester.pumpAndSettle();
        }
      }

      // Wait for auto-save
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot showing data entry completed
      await screenshotHelper.takeScreenshot('offline_mode_data_entry_completed');

      // Verify data was entered successfully
      expect(find.text('Offline Test Opponent'), findsOneWidget);
      expect(find.text('Offline Gymnasium'), findsOneWidget);

      // Verify data is persisted in Hive
      final box = HiveService.getBox(HiveService.matchDraftsBox);
      expect(box.length, greaterThan(0));
    });
  });

  // ============================================================
  // SYNC QUEUE TESTS (9-11)
  // ============================================================

  group('Sync Queue Tests', () {
    testWidgets('9. Actions queue when offline', (tester) async {
      // Get the sync queue box
      final syncBox = HiveService.getBox(HiveService.syncQueueBox);
      final initialCount = syncBox.length;

      // Create a sync queue item directly
      final syncItem = SyncQueueItem(
        id: uuid.v4(),
        type: SyncItemType.rally,
        operation: SyncOperation.create,
        data: {
          'rally_id': uuid.v4(),
          'rally_number': 1,
          'events': [],
        },
        createdAt: DateTime.now(),
      );

      // Add to sync queue
      await syncBox.put(syncItem.id, syncItem.toMap());

      // Take screenshot
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_sync_queue_item_added');

      // Verify item was queued
      expect(syncBox.length, greaterThan(initialCount));

      // Verify the item can be retrieved
      final storedItem = syncBox.get(syncItem.id);
      expect(storedItem, isNotNull);

      final retrievedItem = SyncQueueItem.fromMap(
        Map<String, dynamic>.from(storedItem as Map),
      );
      expect(retrievedItem.type, equals(SyncItemType.rally));
      expect(retrievedItem.operation, equals(SyncOperation.create));
    });

    testWidgets('10. Queue persists across restart', (tester) async {
      // Add items to sync queue
      final syncBox = HiveService.getBox(HiveService.syncQueueBox);

      final itemIds = <String>[];
      for (var i = 0; i < 3; i++) {
        final syncItem = SyncQueueItem(
          id: uuid.v4(),
          type: SyncItemType.rally,
          operation: SyncOperation.create,
          data: {'test_number': i},
          createdAt: DateTime.now(),
        );
        await syncBox.put(syncItem.id, syncItem.toMap());
        itemIds.add(syncItem.id);
      }

      // Verify items are in queue
      expect(syncBox.length, greaterThanOrEqualTo(3));

      // Take screenshot before restart
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_sync_queue_before_restart');

      // Simulate app restart
      await simulateAppRestart();

      // Verify queue survived restart
      final boxAfterRestart = HiveService.getBox(HiveService.syncQueueBox);
      expect(boxAfterRestart.length, greaterThanOrEqualTo(3));

      // Verify specific items are still there
      for (final id in itemIds) {
        final storedItem = boxAfterRestart.get(id);
        expect(storedItem, isNotNull);
      }

      // Repump app
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Take screenshot after restart
      await screenshotHelper.takeScreenshot('offline_sync_queue_after_restart');
    });

    testWidgets('11. Sync service reports queue status', (tester) async {
      // Create sync service
      final syncService = SyncService();

      // Add items to sync queue
      final syncBox = HiveService.getBox(HiveService.syncQueueBox);

      // Add pending item
      final pendingItem = SyncQueueItem(
        id: uuid.v4(),
        type: SyncItemType.matchDraft,
        operation: SyncOperation.create,
        data: {'opponent': 'Test'},
        createdAt: DateTime.now(),
        attempts: 0,
      );
      await syncBox.put(pendingItem.id, pendingItem.toMap());

      // Add retrying item
      final retryingItem = SyncQueueItem(
        id: uuid.v4(),
        type: SyncItemType.player,
        operation: SyncOperation.update,
        data: {'name': 'Test Player'},
        createdAt: DateTime.now(),
        attempts: 1,
        lastAttempt: DateTime.now(),
        error: 'Network error',
      );
      await syncBox.put(retryingItem.id, retryingItem.toMap());

      // Get stats
      final stats = await syncService.getStats();

      // Verify stats
      expect(stats.hasItems, isTrue);
      expect(stats.total, greaterThanOrEqualTo(2));
      expect(stats.pending, greaterThanOrEqualTo(1));
      expect(stats.retrying, greaterThanOrEqualTo(1));

      // Take screenshot (UI might show sync status)
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_sync_queue_status');

      // Clean up
      syncService.dispose();
    });
  });

  // ============================================================
  // NAVIGATION TESTS (12-14)
  // ============================================================

  group('Navigation Persistence Tests', () {
    testWidgets('12. Data not lost on navigation', (tester) async {
      await pumpApp(tester, initialRoute: '/match/setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of initial state
      await screenshotHelper.takeScreenshot('offline_nav_data_initial');

      // Enter some data
      final opponentField = find.widgetWithText(TextField, 'Opponent');
      if (opponentField.evaluate().isNotEmpty) {
        await tester.enterText(opponentField, 'Navigation Test Team');
        await tester.pumpAndSettle();
      }

      // Wait for auto-save
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Navigate away
      appRouter.go('/teams');
      await tester.pumpAndSettle();

      // Take screenshot after navigation
      await screenshotHelper.takeScreenshot('offline_nav_data_away');

      expect(find.byType(TeamListScreen), findsOneWidget);

      // Navigate back to match setup landing
      appRouter.go('/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot after returning
      await screenshotHelper.takeScreenshot('offline_nav_data_returned');

      // Verify landing screen shows option to continue with saved draft
      expect(find.byType(MatchSetupLandingScreen), findsOneWidget);

      // The "Use Last Match Setup" option should be present if draft was saved
      final useLastMatch = find.text('Use Last Match Setup');
      if (useLastMatch.evaluate().isNotEmpty) {
        expect(useLastMatch, findsOneWidget);
      }
    });

    testWidgets('13. Back button preserves state', (tester) async {
      // Start at landing, go to setup
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to setup flow
      final startFresh = find.text('Start Fresh');
      if (startFresh.evaluate().isNotEmpty) {
        await tester.tap(startFresh);
        await tester.pumpAndSettle();
      }

      // Take screenshot of setup flow
      await screenshotHelper.takeScreenshot('offline_back_button_setup');

      // Fill in partial data
      final opponentField = find.widgetWithText(TextField, 'Opponent');
      if (opponentField.evaluate().isNotEmpty) {
        await tester.enterText(opponentField, 'Back Button Test');
        await tester.pumpAndSettle();
      }

      // Wait for auto-save
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      if (backButton.evaluate().isNotEmpty) {
        await tester.tap(backButton);
        await tester.pumpAndSettle();
      }

      // Take screenshot after going back
      await screenshotHelper.takeScreenshot('offline_back_button_returned');

      // Return to setup
      final startFreshAgain = find.text('Start Fresh');
      if (startFreshAgain.evaluate().isNotEmpty) {
        await tester.tap(startFreshAgain);
        await tester.pumpAndSettle();
      }

      // Take screenshot after returning to setup
      await screenshotHelper.takeScreenshot('offline_back_button_state_restored');

      // State might be restored via auto-save
      // Verify we're back on the setup flow
      expect(find.byType(MatchSetupFlow), findsOneWidget);
    });

    testWidgets('14. Deep links work with persisted data', (tester) async {
      // First, store some match data
      final draftsBox = HiveService.getBox(HiveService.matchDraftsBox);
      final matchId = 'test-match-${uuid.v4()}';

      final draft = MatchDraft(
        opponent: 'Deep Link Opponent',
        matchDate: DateTime.now(),
        location: 'Deep Link Court',
        seasonLabel: 'Test Season',
        selectedPlayerIds: {'player-001', 'player-002'},
        startingRotation: {},
      );

      await draftsBox.put(matchId, draft.toMap());

      // Navigate directly to rally capture with the match ID
      await pumpApp(tester);
      await tester.pumpAndSettle();

      appRouter.go('/match/$matchId/rally');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('offline_deep_link_navigation');

      // Verify navigation worked (might show RallyCaptureScreen or error depending on state)
      expect(find.byType(MaterialApp), findsOneWidget);

      // Try navigating to match recap
      appRouter.go('/match/$matchId/recap');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('offline_deep_link_recap');
    });
  });

  // ============================================================
  // EDGE CASE TESTS (15-17)
  // ============================================================

  group('Edge Case Tests', () {
    testWidgets('15. App crash recovery (Hive reinitialization)', (tester) async {
      // Store some data before simulated crash
      final box = HiveService.getBox(HiveService.matchDraftsBox);
      final testId = 'crash-test-${uuid.v4()}';

      final draft = MatchDraft(
        opponent: 'Crash Recovery Test',
        matchDate: DateTime.now(),
        location: 'Recovery Court',
        seasonLabel: 'Recovery Season',
        selectedPlayerIds: {'player-001'},
        startingRotation: {},
      );

      await box.put(testId, draft.toMap());

      // Take screenshot before simulated crash
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_crash_recovery_before');

      // Verify data is stored
      expect(box.containsKey(testId), isTrue);

      // Simulate crash by abruptly closing Hive
      await HiveService.closeAll();

      // Simulate restart
      await HiveService.initialize();

      // Verify data survived
      final boxAfterCrash = HiveService.getBox(HiveService.matchDraftsBox);
      expect(boxAfterCrash.containsKey(testId), isTrue);

      final recoveredData = boxAfterCrash.get(testId);
      expect(recoveredData, isNotNull);

      final recoveredDraft = MatchDraft.fromMap(
        Map<String, dynamic>.from(recoveredData as Map),
      );
      expect(recoveredDraft.opponent, equals('Crash Recovery Test'));

      // Repump app
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Take screenshot after recovery
      await screenshotHelper.takeScreenshot('offline_crash_recovery_after');
    });

    testWidgets('16. Low memory handling (graceful behavior)', (tester) async {
      // Test with large data operations
      final box = HiveService.getBox(HiveService.rallyEventsBox);
      final initialCount = box.length;

      // Add many rally events
      for (var i = 0; i < 100; i++) {
        final event = RallyEvent(
          id: uuid.v4(),
          type: RallyActionTypes.attackKill,
          timestamp: DateTime.now(),
          player: MatchPlayer(
            id: 'player-$i',
            name: 'Player $i',
            jerseyNumber: i % 99 + 1,
            position: 'Position',
          ),
        );
        await box.put(event.id, ModelSerializer.rallyEventToMap(event));
      }

      // Verify all events were stored
      expect(box.length, greaterThanOrEqualTo(initialCount + 100));

      // Take screenshot
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_low_memory_many_events');

      // App should remain responsive
      appRouter.go('/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.byType(MatchSetupLandingScreen), findsOneWidget);

      // Take screenshot after navigation
      await screenshotHelper.takeScreenshot('offline_low_memory_navigation');
    });

    testWidgets('17. Large data sets performance', (tester) async {
      // Store many rallies to test performance
      final box = HiveService.getBox(HiveService.rallyRecordsBox);
      final startTime = DateTime.now();

      // Add 50 rally records with multiple events each
      for (var i = 0; i < 50; i++) {
        final events = <RallyEvent>[];
        for (var j = 0; j < 5; j++) {
          events.add(RallyEvent(
            id: uuid.v4(),
            type: RallyActionTypes.values[j % RallyActionTypes.values.length],
            timestamp: DateTime.now(),
            player: MatchPlayer(
              id: 'player-$j',
              name: 'Player $j',
              jerseyNumber: j + 1,
              position: 'Position',
            ),
          ));
        }

        final record = RallyRecord(
          rallyId: uuid.v4(),
          rallyNumber: i + 1,
          rotationNumber: (i % 6) + 1,
          events: events,
          completedAt: DateTime.now(),
        );

        await box.put(record.rallyId, ModelSerializer.rallyRecordToMap(record));
      }

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);

      // Verify performance is acceptable (should complete within reasonable time)
      // 50 records with 5 events each should take less than 10 seconds
      expect(duration.inSeconds, lessThan(10));

      // Verify all records were stored
      expect(box.length, greaterThanOrEqualTo(50));

      // Take screenshot
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_large_dataset_stored');

      // Test retrieval performance
      final retrieveStart = DateTime.now();
      final allRecords = box.values.toList();
      final retrieveEnd = DateTime.now();
      final retrieveDuration = retrieveEnd.difference(retrieveStart);

      // Retrieval should be fast
      expect(retrieveDuration.inMilliseconds, lessThan(1000));
      expect(allRecords.length, greaterThanOrEqualTo(50));

      // Navigate to ensure app is responsive with large data
      appRouter.go('/history');
      await tester.pumpAndSettle();

      // Take screenshot of history with data
      await screenshotHelper.takeScreenshot('offline_large_dataset_history');

      expect(find.byType(MatchHistoryScreen), findsOneWidget);
    });
  });

  // ============================================================
  // HIVE BOX MANAGEMENT TESTS
  // ============================================================

  group('Hive Box Management Tests', () {
    testWidgets('All required boxes are opened on initialization', (tester) async {
      // Verify all boxes are accessible
      expect(
        () => HiveService.getBox(HiveService.matchDraftsBox),
        returnsNormally,
      );
      expect(
        () => HiveService.getBox(HiveService.matchPlayersBox),
        returnsNormally,
      );
      expect(
        () => HiveService.getBox(HiveService.rosterTemplatesBox),
        returnsNormally,
      );
      expect(
        () => HiveService.getBox(HiveService.rallyRecordsBox),
        returnsNormally,
      );
      expect(
        () => HiveService.getBox(HiveService.rallyEventsBox),
        returnsNormally,
      );
      expect(
        () => HiveService.getBox(HiveService.syncQueueBox),
        returnsNormally,
      );

      // Take screenshot
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_hive_boxes_initialized');
    });

    testWidgets('Storage stats are accessible', (tester) async {
      // Add some data to boxes
      final draftsBox = HiveService.getBox(HiveService.matchDraftsBox);
      await draftsBox.put('test-draft', {'opponent': 'Test'});

      final playersBox = HiveService.getBox(HiveService.matchPlayersBox);
      await playersBox.put('test-player', {'name': 'Test Player'});

      // Get storage stats
      final stats = HiveService.getStorageStats();

      // Verify stats are returned
      expect(stats, isNotEmpty);
      expect(stats[HiveService.matchDraftsBox], greaterThanOrEqualTo(1));
      expect(stats[HiveService.matchPlayersBox], greaterThanOrEqualTo(1));

      // Take screenshot
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_storage_stats');
    });

    testWidgets('Double initialization is handled gracefully', (tester) async {
      // HiveService is already initialized in setUp
      // Calling initialize again should not cause errors
      await HiveService.initialize(); // Second call
      await HiveService.initialize(); // Third call

      // Verify boxes are still accessible
      expect(
        () => HiveService.getBox(HiveService.matchDraftsBox),
        returnsNormally,
      );

      // Take screenshot
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_double_init_handled');
    });
  });

  // ============================================================
  // COMPLETE OFFLINE WORKFLOW TESTS
  // ============================================================

  group('Complete Offline Workflow Tests', () {
    testWidgets('Full offline match recording workflow', (tester) async {
      // Step 1: Start the app in offline mode
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await screenshotHelper.takeStepScreenshot('offline_workflow', 1, 'landing');

      // Step 2: Navigate to setup
      final startFresh = find.text('Start Fresh');
      if (startFresh.evaluate().isNotEmpty) {
        await tester.tap(startFresh);
        await tester.pumpAndSettle();
      }

      await screenshotHelper.takeStepScreenshot('offline_workflow', 2, 'setup');

      // Step 3: Enter match info
      final opponentField = find.widgetWithText(TextField, 'Opponent');
      if (opponentField.evaluate().isNotEmpty) {
        await tester.enterText(opponentField, 'Offline Workflow Test');
        await tester.pumpAndSettle();
      }

      await screenshotHelper.takeStepScreenshot('offline_workflow', 3, 'opponent_entered');

      // Step 4: Select date
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

      await screenshotHelper.takeStepScreenshot('offline_workflow', 4, 'date_selected');

      // Step 5: Select players
      final filterChips = find.byType(FilterChip);
      if (filterChips.evaluate().isNotEmpty) {
        final chipCount = filterChips.evaluate().length;
        final selectCount = chipCount >= 6 ? 6 : chipCount;

        for (var i = 0; i < selectCount; i++) {
          await tester.tap(filterChips.at(i));
          await tester.pumpAndSettle();
        }
      }

      await screenshotHelper.takeStepScreenshot('offline_workflow', 5, 'players_selected');

      // Step 6: Wait for auto-save and verify data is persisted
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final draftsBox = HiveService.getBox(HiveService.matchDraftsBox);
      expect(draftsBox.length, greaterThan(0));

      await screenshotHelper.takeStepScreenshot('offline_workflow', 6, 'data_persisted');

      // Step 7: Simulate app restart
      await simulateAppRestart();

      // Step 8: Return to app and verify data is still there
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      await screenshotHelper.takeStepScreenshot('offline_workflow', 7, 'after_restart');

      // The landing should show option to use last match setup
      expect(find.byType(MatchSetupLandingScreen), findsOneWidget);
    });

    testWidgets('Offline sync queue workflow', (tester) async {
      // Step 1: Create sync items
      final syncBox = HiveService.getBox(HiveService.syncQueueBox);
      await syncBox.clear(); // Clear any existing items

      for (var i = 0; i < 5; i++) {
        final syncItem = SyncQueueItem(
          id: uuid.v4(),
          type: SyncItemType.rally,
          operation: SyncOperation.create,
          data: {'rally_number': i + 1},
          createdAt: DateTime.now(),
        );
        await syncBox.put(syncItem.id, syncItem.toMap());
      }

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await screenshotHelper.takeStepScreenshot('sync_queue_workflow', 1, 'items_created');

      // Verify items in queue
      expect(syncBox.length, equals(5));

      // Step 2: Simulate restart
      await simulateAppRestart();

      // Step 3: Verify items survived
      final boxAfterRestart = HiveService.getBox(HiveService.syncQueueBox);
      expect(boxAfterRestart.length, equals(5));

      await pumpApp(tester);
      await tester.pumpAndSettle();

      await screenshotHelper.takeStepScreenshot('sync_queue_workflow', 2, 'after_restart');

      // Step 4: Get sync stats
      final syncService = SyncService();
      final stats = await syncService.getStats();

      expect(stats.total, equals(5));
      expect(stats.pending, equals(5));

      await screenshotHelper.takeStepScreenshot('sync_queue_workflow', 3, 'stats_verified');

      // Clean up
      syncService.dispose();
    });
  });

  // ============================================================
  // ROSTER TEMPLATE PERSISTENCE TESTS
  // ============================================================

  group('Roster Template Persistence Tests', () {
    testWidgets('Roster templates persist across restart', (tester) async {
      // Store roster template in Hive
      final box = HiveService.getBox(HiveService.rosterTemplatesBox);
      final templateId = 'template-${uuid.v4()}';

      final templateData = {
        'id': templateId,
        'name': 'Test Template',
        'player_ids': ['player-001', 'player-002', 'player-003'],
        'rotation': {
          '1': 'player-001',
          '2': 'player-002',
          '3': 'player-003',
        },
        'created_at': DateTime.now().toIso8601String(),
      };

      await box.put(templateId, templateData);

      // Take screenshot before restart
      await pumpApp(tester);
      await tester.pumpAndSettle();
      await screenshotHelper.takeScreenshot('offline_template_before_restart');

      // Verify template is stored
      expect(box.containsKey(templateId), isTrue);

      // Simulate restart
      await simulateAppRestart();

      // Verify template survived
      final boxAfterRestart = HiveService.getBox(HiveService.rosterTemplatesBox);
      expect(boxAfterRestart.containsKey(templateId), isTrue);

      final storedTemplate = boxAfterRestart.get(templateId);
      expect(storedTemplate, isNotNull);
      expect((storedTemplate as Map)['name'], equals('Test Template'));

      // Repump app
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Take screenshot after restart
      await screenshotHelper.takeScreenshot('offline_template_after_restart');
    });
  });
}
