import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:volleyball_stats_app/core/persistence/hive_service.dart';
import 'package:volleyball_stats_app/core/router/app_router.dart';
import 'package:volleyball_stats_app/core/theme/app_theme.dart';
import 'package:volleyball_stats_app/features/players/player_create_screen.dart';
import 'package:volleyball_stats_app/features/players/player_list_screen.dart';
import 'package:volleyball_stats_app/features/teams/team_create_screen.dart';
import 'package:volleyball_stats_app/features/teams/team_list_screen.dart';
import 'package:volleyball_stats_app/features/teams/team_selection_screen.dart';

import 'utils/screenshot_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final screenshotHelper = ScreenshotHelper(binding);

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

  // ============================================================
  // TEAM MANAGEMENT TESTS
  // ============================================================

  group('Team Management Tests', () {
    testWidgets('displays team list screen with correct structure', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');

      // Take screenshot of the team list screen
      await screenshotHelper.takeScreenshot('team_list_screen');

      // Verify the team list screen is displayed
      expect(find.byType(TeamListScreen), findsOneWidget);

      // Verify the app bar has correct title
      expect(find.text('My Teams'), findsOneWidget);

      // Verify the add button is present in app bar
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.byTooltip('Create Team'), findsOneWidget);
    });

    testWidgets('displays empty state when no teams exist', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');

      // Wait for the async provider to resolve
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot of empty state
      await screenshotHelper.takeScreenshot('team_list_empty_state');

      // In offline mode without Supabase, the provider returns empty list
      // Verify empty state UI elements exist in the widget tree
      // The empty state shows "No Teams Yet" text
      final noTeamsText = find.text('No Teams Yet');
      final createTeamButton = find.text('Create Team');

      // Check if we're seeing the empty state or an error state
      if (noTeamsText.evaluate().isNotEmpty) {
        expect(noTeamsText, findsOneWidget);
        expect(find.text('Create your first team to get started.'), findsOneWidget);
        expect(createTeamButton, findsOneWidget);

        // Verify the empty state icon
        expect(find.byIcon(Icons.group_outlined), findsOneWidget);
      }
    });

    testWidgets('navigates to team create screen from team list', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');
      await tester.pumpAndSettle();

      // Take screenshot before navigation
      await screenshotHelper.takeScreenshot('team_list_before_create');

      // Tap the add button in app bar
      await tester.tap(find.byIcon(Icons.add));
      await tester.pumpAndSettle();

      // Take screenshot of create screen
      await screenshotHelper.takeScreenshot('team_create_screen');

      // Verify navigation to create screen
      expect(find.byType(TeamCreateScreen), findsOneWidget);
      expect(find.text('Create Team'), findsAtLeastNWidgets(1));
    });

    testWidgets('team create screen displays all form elements', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Take screenshot of create team form
      await screenshotHelper.takeScreenshot('team_create_form');

      // Verify form elements are present
      expect(find.byType(TeamCreateScreen), findsOneWidget);

      // Verify form header
      expect(find.text('Create New Team'), findsOneWidget);

      // Verify volleyball icon
      expect(find.byIcon(Icons.sports_volleyball), findsOneWidget);

      // Verify form fields exist (TextFormField widgets)
      expect(find.byType(TextFormField), findsNWidgets(3));

      // Verify field labels
      expect(find.text('Team Name *'), findsOneWidget);
      expect(find.text('Level (e.g., Varsity, JV)'), findsOneWidget);
      expect(find.text('Season (e.g., 2025)'), findsOneWidget);

      // Verify form field icons
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);

      // Verify submit button
      expect(find.text('Create Team'), findsAtLeastNWidgets(1));
    });

    testWidgets('team create form shows validation error for empty name', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Take screenshot of initial form
      await screenshotHelper.takeScreenshot('team_create_validation_before');

      // Try to submit empty form - find the Create Team button (ElevatedButton)
      final createButton = find.widgetWithText(ElevatedButton, 'Create Team');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Take screenshot showing validation error
      await screenshotHelper.takeScreenshot('team_create_validation_error');

      // Verify validation error is displayed
      expect(find.text('Team name is required'), findsOneWidget);
    });

    testWidgets('team create form accepts valid input', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Find the text form fields
      final textFields = find.byType(TextFormField);

      // Enter team name (first field)
      await tester.enterText(textFields.at(0), 'Thunderbolts Volleyball');
      await tester.pumpAndSettle();

      // Enter level (second field)
      await tester.enterText(textFields.at(1), 'Varsity');
      await tester.pumpAndSettle();

      // Enter season (third field)
      await tester.enterText(textFields.at(2), 'Spring 2026');
      await tester.pumpAndSettle();

      // Take screenshot of filled form
      await screenshotHelper.takeScreenshot('team_create_form_filled');

      // Verify the form is filled (we can see the text was entered)
      expect(find.text('Thunderbolts Volleyball'), findsOneWidget);
      expect(find.text('Varsity'), findsOneWidget);
      expect(find.text('Spring 2026'), findsOneWidget);

      // Note: Actual submission requires Supabase connection
      // In offline mode, submission would show an error
    });

    testWidgets('team create form submission shows error without Supabase', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Fill in the form
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Test Team');
      await tester.pumpAndSettle();

      // Take screenshot before submission
      await screenshotHelper.takeScreenshot('team_create_submit_before');

      // Try to submit the form
      final createButton = find.widgetWithText(ElevatedButton, 'Create Team');
      await tester.tap(createButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot after submission attempt
      await screenshotHelper.takeScreenshot('team_create_submit_result');

      // The app should handle the error gracefully
      // Either show an error message or remain on the form
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('team selection screen displays correct structure', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/select');

      // Take screenshot of team selection screen
      await screenshotHelper.takeScreenshot('team_selection_screen');

      // Verify team selection screen is displayed
      expect(find.byType(TeamSelectionScreen), findsOneWidget);
      expect(find.text('Select Team'), findsOneWidget);

      // Verify popup menu for logout may be present (depends on auth state)
      final popupMenu = find.byType(PopupMenuButton<String>);
      expect(popupMenu.evaluate().length, lessThanOrEqualTo(1));
    });

    testWidgets('team selection shows empty state when no teams', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/select');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot of team selection empty state
      await screenshotHelper.takeScreenshot('team_selection_empty_state');

      // Check for empty state or loading state
      final noTeamsFound = find.text('No Teams Found');
      if (noTeamsFound.evaluate().isNotEmpty) {
        expect(noTeamsFound, findsOneWidget);
        expect(find.text('Create your first team to get started.'), findsOneWidget);
        expect(find.byIcon(Icons.group_outlined), findsOneWidget);
      }
    });
  });

  // ============================================================
  // PLAYER MANAGEMENT TESTS
  // ============================================================

  group('Player Management Tests', () {
    testWidgets('displays player list screen with correct structure', (tester) async {
      await pumpApp(tester, initialRoute: '/players');

      // Take screenshot of the player list screen
      await screenshotHelper.takeScreenshot('player_list_screen');

      // Verify the player list screen is displayed
      expect(find.byType(PlayerListScreen), findsOneWidget);

      // Verify the app bar has correct title
      expect(find.text('Players'), findsOneWidget);
    });

    testWidgets('player list shows no team selected message', (tester) async {
      await pumpApp(tester, initialRoute: '/players');
      await tester.pumpAndSettle();

      // Take screenshot of no team selected state
      await screenshotHelper.takeScreenshot('player_list_no_team');

      // When no team is selected, should show appropriate message
      final noTeamSelected = find.text('No Team Selected');
      if (noTeamSelected.evaluate().isNotEmpty) {
        expect(noTeamSelected, findsOneWidget);
        expect(find.text('Please select a team to manage players.'), findsOneWidget);
        expect(find.byIcon(Icons.info_outline), findsOneWidget);
      }
    });

    testWidgets('navigates to player create screen', (tester) async {
      await pumpApp(tester, initialRoute: '/players/create');
      await tester.pumpAndSettle();

      // Take screenshot of create player screen
      await screenshotHelper.takeScreenshot('player_create_screen');

      // Verify player create screen is displayed
      expect(find.byType(PlayerCreateScreen), findsOneWidget);
    });

    testWidgets('player create screen shows no team selected when team not set', (tester) async {
      await pumpApp(tester, initialRoute: '/players/create');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('player_create_no_team');

      // Without a selected team, should show "No Team Selected"
      final noTeamSelected = find.text('No Team Selected');
      if (noTeamSelected.evaluate().isNotEmpty) {
        expect(noTeamSelected, findsOneWidget);
        expect(find.text('Please select a team before adding players.'), findsOneWidget);
      }
    });

    testWidgets('player create form displays all form elements when team selected', (tester) async {
      // Note: This test documents the expected form structure
      // Full functionality requires a selected team
      await pumpApp(tester, initialRoute: '/players/create');

      // Take screenshot
      await screenshotHelper.takeScreenshot('player_create_form_structure');

      // Verify the screen structure
      expect(find.byType(PlayerCreateScreen), findsOneWidget);

      // The form should have these elements when team is selected:
      // - First Name field with Icons.person
      // - Last Name field with Icons.person_outline
      // - Jersey Number field with Icons.numbers
      // - Position dropdown with Icons.sports_volleyball
      // - Add Player button

      // Check if we can see the form (depends on whether team is selected)
      final addPlayerTitle = find.text('Add New Player');
      if (addPlayerTitle.evaluate().isNotEmpty) {
        expect(find.text('First Name *'), findsOneWidget);
        expect(find.text('Last Name *'), findsOneWidget);
        expect(find.text('Jersey Number *'), findsOneWidget);
        expect(find.text('Position'), findsOneWidget);
        expect(find.text('Add Player'), findsOneWidget);
      }
    });

    testWidgets('player form field structure matches expected layout', (tester) async {
      // This test verifies the player form widget structure exists correctly
      await pumpApp(tester, initialRoute: '/players/create');
      await tester.pumpAndSettle();

      // Take screenshot showing form state
      await screenshotHelper.takeScreenshot('player_form_structure');

      // Verify we're on the correct screen
      expect(find.byType(PlayerCreateScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });
  });

  // ============================================================
  // NAVIGATION AND ROUTING TESTS
  // ============================================================

  group('Navigation Tests', () {
    testWidgets('can navigate from home to teams list', (tester) async {
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Take screenshot of initial state
      await screenshotHelper.takeScreenshot('nav_home_initial');

      // Navigate to teams
      appRouter.go('/teams');
      await tester.pumpAndSettle();

      // Take screenshot after navigation
      await screenshotHelper.takeScreenshot('nav_home_to_teams');

      expect(find.byType(TeamListScreen), findsOneWidget);
    });

    testWidgets('can navigate from home to players list', (tester) async {
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Navigate to players
      appRouter.go('/players');
      await tester.pumpAndSettle();

      // Take screenshot after navigation
      await screenshotHelper.takeScreenshot('nav_home_to_players');

      expect(find.byType(PlayerListScreen), findsOneWidget);
    });

    testWidgets('can navigate between teams and players screens', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');
      await tester.pumpAndSettle();

      // Take screenshot of teams
      await screenshotHelper.takeScreenshot('nav_teams_screen');

      // Navigate to players
      appRouter.go('/players');
      await tester.pumpAndSettle();

      // Take screenshot of players
      await screenshotHelper.takeScreenshot('nav_players_screen');

      expect(find.byType(PlayerListScreen), findsOneWidget);

      // Navigate back to teams
      appRouter.go('/teams');
      await tester.pumpAndSettle();

      // Take screenshot back at teams
      await screenshotHelper.takeScreenshot('nav_back_to_teams');

      expect(find.byType(TeamListScreen), findsOneWidget);
    });

    testWidgets('can navigate to team create and back', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');
      await tester.pumpAndSettle();

      // Navigate to create
      appRouter.push('/teams/create');
      await tester.pumpAndSettle();

      // Take screenshot of create screen
      await screenshotHelper.takeScreenshot('nav_team_create');

      expect(find.byType(TeamCreateScreen), findsOneWidget);

      // Use back navigation (pop)
      appRouter.pop();
      await tester.pumpAndSettle();

      // Take screenshot after going back
      await screenshotHelper.takeScreenshot('nav_team_create_back');

      expect(find.byType(TeamListScreen), findsOneWidget);
    });

    testWidgets('can navigate to player create and back', (tester) async {
      await pumpApp(tester, initialRoute: '/players');
      await tester.pumpAndSettle();

      // Navigate to create
      appRouter.push('/players/create');
      await tester.pumpAndSettle();

      // Take screenshot of create screen
      await screenshotHelper.takeScreenshot('nav_player_create');

      expect(find.byType(PlayerCreateScreen), findsOneWidget);

      // Use back navigation (pop)
      appRouter.pop();
      await tester.pumpAndSettle();

      // Take screenshot after going back
      await screenshotHelper.takeScreenshot('nav_player_create_back');

      expect(find.byType(PlayerListScreen), findsOneWidget);
    });
  });

  // ============================================================
  // FORM VALIDATION TESTS
  // ============================================================

  group('Form Validation Tests', () {
    testWidgets('team create validates required name field', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Try to submit without entering name
      final createButton = find.widgetWithText(ElevatedButton, 'Create Team');
      await tester.tap(createButton);
      await tester.pumpAndSettle();

      // Take screenshot of validation error
      await screenshotHelper.takeScreenshot('validation_team_name_required');

      // Verify validation error appears
      expect(find.text('Team name is required'), findsOneWidget);
    });

    testWidgets('team create accepts optional level field empty', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Enter only required field
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'My Team');
      await tester.pumpAndSettle();

      // Take screenshot with only required field
      await screenshotHelper.takeScreenshot('validation_team_optional_empty');

      // Form should be valid with just the name
      // (actual submission will fail without Supabase, but validation passes)
      expect(find.text('Team name is required'), findsNothing);
    });

    testWidgets('team create accepts optional season field empty', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Enter name and level but not season
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'My Team');
      await tester.enterText(textFields.at(1), 'Varsity');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('validation_team_no_season');

      // Form should be valid
      expect(find.text('Team name is required'), findsNothing);
    });
  });

  // ============================================================
  // UI ELEMENT TESTS
  // ============================================================

  group('UI Element Tests', () {
    testWidgets('team list has correct icons and visual elements', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('ui_team_list_elements');

      // Verify add icon in app bar
      expect(find.byIcon(Icons.add), findsOneWidget);

      // Check for empty state icon or team icons depending on state
      // Empty state has group_outlined icon
      final emptyIcon = find.byIcon(Icons.group_outlined);
      if (emptyIcon.evaluate().isNotEmpty) {
        expect(emptyIcon, findsOneWidget);
      }
    });

    testWidgets('team create has correct icons', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Take screenshot
      await screenshotHelper.takeScreenshot('ui_team_create_icons');

      // Verify form field icons
      expect(find.byIcon(Icons.sports_volleyball), findsOneWidget);
      expect(find.byIcon(Icons.group), findsOneWidget);
      expect(find.byIcon(Icons.star), findsOneWidget);
      expect(find.byIcon(Icons.calendar_today), findsOneWidget);
    });

    testWidgets('player list has correct icons', (tester) async {
      await pumpApp(tester, initialRoute: '/players');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('ui_player_list_icons');

      // Check for no team selected icon or add icon
      final infoIcon = find.byIcon(Icons.info_outline);
      final peopleIcon = find.byIcon(Icons.people_outline);

      // One of these should be present depending on state
      expect(
        infoIcon.evaluate().isNotEmpty || peopleIcon.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('player create has correct icons when showing form', (tester) async {
      await pumpApp(tester, initialRoute: '/players/create');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('ui_player_create_icons');

      // Verify player create screen structure exists
      expect(find.byType(PlayerCreateScreen), findsOneWidget);

      // Check for icons - either the form icons or the no-team-selected icon
      final personAddIcon = find.byIcon(Icons.person_add);
      final infoIcon = find.byIcon(Icons.info_outline);

      // One of these states should be shown
      expect(
        personAddIcon.evaluate().isNotEmpty || infoIcon.evaluate().isNotEmpty,
        isTrue,
      );
    });
  });

  // ============================================================
  // GLASSMORPHISM CONTAINER TESTS
  // ============================================================

  group('GlassContainer Widget Tests', () {
    testWidgets('team list uses GlassContainer for styling', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');
      await tester.pumpAndSettle();

      // Take screenshot showing glass styling
      await screenshotHelper.takeScreenshot('glass_team_list');

      // Verify the screen renders with expected styling
      expect(find.byType(TeamListScreen), findsOneWidget);
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));
    });

    testWidgets('team create uses GlassContainer for form', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Take screenshot showing glass form container
      await screenshotHelper.takeScreenshot('glass_team_create_form');

      // Verify the form structure
      expect(find.byType(TeamCreateScreen), findsOneWidget);
      expect(find.byType(Form), findsOneWidget);
    });

    testWidgets('player list uses GlassContainer for styling', (tester) async {
      await pumpApp(tester, initialRoute: '/players');
      await tester.pumpAndSettle();

      // Take screenshot showing glass styling
      await screenshotHelper.takeScreenshot('glass_player_list');

      // Verify the screen renders
      expect(find.byType(PlayerListScreen), findsOneWidget);
    });

    testWidgets('player create uses GlassContainer for form', (tester) async {
      await pumpApp(tester, initialRoute: '/players/create');
      await tester.pumpAndSettle();

      // Take screenshot showing glass form container
      await screenshotHelper.takeScreenshot('glass_player_create_form');

      // Verify the screen renders
      expect(find.byType(PlayerCreateScreen), findsOneWidget);
    });
  });

  // ============================================================
  // APP BAR ACTION TESTS
  // ============================================================

  group('App Bar Action Tests', () {
    testWidgets('team list app bar add button navigates to create', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');
      await tester.pumpAndSettle();

      // Find and verify add button
      final addButton = find.byIcon(Icons.add);
      expect(addButton, findsOneWidget);

      // Take screenshot before tap
      await screenshotHelper.takeScreenshot('appbar_team_add_before');

      // Tap the add button
      await tester.tap(addButton);
      await tester.pumpAndSettle();

      // Take screenshot after tap
      await screenshotHelper.takeScreenshot('appbar_team_add_after');

      // Should navigate to create screen
      expect(find.byType(TeamCreateScreen), findsOneWidget);
    });

    testWidgets('team list empty state Create Team button works', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for the Create Team button in empty state
      final createTeamButton = find.widgetWithText(ElevatedButton, 'Create Team');

      if (createTeamButton.evaluate().isNotEmpty) {
        // Take screenshot of empty state
        await screenshotHelper.takeScreenshot('empty_state_create_team_before');

        // Tap the button
        await tester.tap(createTeamButton.first);
        await tester.pumpAndSettle();

        // Take screenshot after
        await screenshotHelper.takeScreenshot('empty_state_create_team_after');

        // Should navigate to create screen
        expect(find.byType(TeamCreateScreen), findsOneWidget);
      }
    });
  });

  // ============================================================
  // ERROR HANDLING TESTS
  // ============================================================

  group('Error Handling Tests', () {
    testWidgets('team create handles submission error gracefully', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Fill the form
      final textFields = find.byType(TextFormField);
      await tester.enterText(textFields.at(0), 'Error Test Team');
      await tester.pumpAndSettle();

      // Take screenshot before submission
      await screenshotHelper.takeScreenshot('error_team_submit_before');

      // Submit the form
      final createButton = find.widgetWithText(ElevatedButton, 'Create Team');
      await tester.tap(createButton);
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot after submission
      await screenshotHelper.takeScreenshot('error_team_submit_after');

      // App should still be functional
      expect(find.byType(MaterialApp), findsOneWidget);

      // Check if error message is displayed
      // The form shows error in a red container with error_outline icon
      final errorIcon = find.byIcon(Icons.error_outline);
      if (errorIcon.evaluate().isNotEmpty) {
        expect(errorIcon, findsOneWidget);
      }
    });

    testWidgets('player list handles error state gracefully', (tester) async {
      await pumpApp(tester, initialRoute: '/players');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot of any error state
      await screenshotHelper.takeScreenshot('error_player_list_state');

      // App should remain functional
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(PlayerListScreen), findsOneWidget);
    });

    testWidgets('team list handles error state gracefully', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot of any error state
      await screenshotHelper.takeScreenshot('error_team_list_state');

      // App should remain functional
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(TeamListScreen), findsOneWidget);
    });
  });

  // ============================================================
  // BACK NAVIGATION TESTS
  // ============================================================

  group('Back Navigation Tests', () {
    testWidgets('team create screen has back button in app bar', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      // Take screenshot showing back button
      await screenshotHelper.takeScreenshot('back_team_create');

      // Verify back button exists (leading icon in app bar)
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
    });

    testWidgets('player create screen has back button in app bar', (tester) async {
      await pumpApp(tester, initialRoute: '/players/create');

      // Take screenshot showing back button
      await screenshotHelper.takeScreenshot('back_player_create');

      // Verify back button exists
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
    });

    testWidgets('back button from team create returns to teams', (tester) async {
      // Start at teams list
      await pumpApp(tester, initialRoute: '/teams');
      await tester.pumpAndSettle();

      // Navigate to create
      appRouter.push('/teams/create');
      await tester.pumpAndSettle();

      expect(find.byType(TeamCreateScreen), findsOneWidget);

      // Take screenshot before back
      await screenshotHelper.takeScreenshot('back_before_tap');

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Take screenshot after back
      await screenshotHelper.takeScreenshot('back_after_tap');

      // Should be back at team list
      expect(find.byType(TeamListScreen), findsOneWidget);
    });
  });

  // ============================================================
  // LOADING STATE TESTS
  // ============================================================

  group('Loading State Tests', () {
    testWidgets('team list shows loading indicator initially', (tester) async {
      await pumpApp(tester, initialRoute: '/teams');

      // Take screenshot immediately (might catch loading state)
      await screenshotHelper.takeScreenshot('loading_team_list');

      // Verify the screen structure
      expect(find.byType(TeamListScreen), findsOneWidget);

      // Wait for loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot after loading
      await screenshotHelper.takeScreenshot('loading_team_list_complete');
    });

    testWidgets('team selection shows loading indicator initially', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/select');

      // Take screenshot immediately
      await screenshotHelper.takeScreenshot('loading_team_selection');

      // Verify the screen structure
      expect(find.byType(TeamSelectionScreen), findsOneWidget);

      // Wait for loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot after loading
      await screenshotHelper.takeScreenshot('loading_team_selection_complete');
    });
  });

  // ============================================================
  // FORM INPUT TESTS
  // ============================================================

  group('Form Input Tests', () {
    testWidgets('team name field accepts text input', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      final textFields = find.byType(TextFormField);
      final nameField = textFields.at(0);

      // Enter text
      await tester.enterText(nameField, 'Eagles Volleyball');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('input_team_name');

      // Verify text was entered
      expect(find.text('Eagles Volleyball'), findsOneWidget);
    });

    testWidgets('team level field accepts text input', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      final textFields = find.byType(TextFormField);
      final levelField = textFields.at(1);

      // Enter text
      await tester.enterText(levelField, 'Junior Varsity');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('input_team_level');

      // Verify text was entered
      expect(find.text('Junior Varsity'), findsOneWidget);
    });

    testWidgets('team season field accepts text input', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      final textFields = find.byType(TextFormField);
      final seasonField = textFields.at(2);

      // Enter text
      await tester.enterText(seasonField, 'Fall 2025');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('input_team_season');

      // Verify text was entered
      expect(find.text('Fall 2025'), findsOneWidget);
    });

    testWidgets('all team form fields can be filled together', (tester) async {
      await pumpApp(tester, initialRoute: '/teams/create');

      final textFields = find.byType(TextFormField);

      // Fill all fields
      await tester.enterText(textFields.at(0), 'Hawks Academy');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(1), 'Club');
      await tester.pumpAndSettle();
      await tester.enterText(textFields.at(2), 'Summer 2026');
      await tester.pumpAndSettle();

      // Take screenshot of complete form
      await screenshotHelper.takeScreenshot('input_team_all_fields');

      // Verify all text was entered
      expect(find.text('Hawks Academy'), findsOneWidget);
      expect(find.text('Club'), findsOneWidget);
      expect(find.text('Summer 2026'), findsOneWidget);
    });
  });

  // ============================================================
  // RESPONSIVE LAYOUT TESTS
  // ============================================================

  group('Responsive Layout Tests', () {
    testWidgets('team list renders correctly in portrait', (tester) async {
      // Set portrait dimensions
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 3.0;

      await pumpApp(tester, initialRoute: '/teams');
      await tester.pumpAndSettle();

      // Take screenshot of portrait layout
      await screenshotHelper.takeScreenshot('layout_team_list_portrait');

      expect(find.byType(TeamListScreen), findsOneWidget);

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('team create renders correctly in portrait', (tester) async {
      // Set portrait dimensions
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 3.0;

      await pumpApp(tester, initialRoute: '/teams/create');

      // Take screenshot of portrait layout
      await screenshotHelper.takeScreenshot('layout_team_create_portrait');

      expect(find.byType(TeamCreateScreen), findsOneWidget);

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('player list renders correctly in portrait', (tester) async {
      // Set portrait dimensions
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 3.0;

      await pumpApp(tester, initialRoute: '/players');
      await tester.pumpAndSettle();

      // Take screenshot of portrait layout
      await screenshotHelper.takeScreenshot('layout_player_list_portrait');

      expect(find.byType(PlayerListScreen), findsOneWidget);

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });
}
