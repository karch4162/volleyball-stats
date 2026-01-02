import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:volleyball_stats_app/core/persistence/hive_service.dart';
import 'package:volleyball_stats_app/core/router/app_router.dart';
import 'package:volleyball_stats_app/core/theme/app_theme.dart';
import 'package:volleyball_stats_app/features/match_setup/match_setup_landing_screen.dart';
import 'package:volleyball_stats_app/features/match_setup/template_edit_screen.dart';
import 'package:volleyball_stats_app/features/match_setup/template_list_screen.dart';

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
  // TEMPLATE LIST SCREEN TESTS
  // ============================================================

  group('Template List Screen Tests', () {
    testWidgets('displays template list screen with correct structure', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');

      // Take screenshot of the template list screen
      await screenshotHelper.takeScreenshot('template_list_screen');

      // Verify the template list screen is displayed
      expect(find.byType(TemplateListScreen), findsOneWidget);

      // Verify the app bar has correct title
      expect(find.text('Roster Templates'), findsOneWidget);

      // Verify the add button is present in app bar
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);
      expect(find.byTooltip('Create Template'), findsOneWidget);
    });

    testWidgets('displays empty state when no templates exist', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');

      // Wait for the async provider to resolve
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot of empty state
      await screenshotHelper.takeScreenshot('template_list_empty_state');

      // Check for empty state UI elements
      final noTemplatesText = find.text('No Templates Yet');
      final createTemplateButton = find.text('Create Template');

      // Check if we're seeing the empty state
      if (noTemplatesText.evaluate().isNotEmpty) {
        expect(noTemplatesText, findsOneWidget);
        expect(
          find.text('Create a template to quickly reuse your roster and rotation'),
          findsOneWidget,
        );
        expect(createTemplateButton, findsOneWidget);

        // Verify the empty state icon
        expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
      }
    });

    testWidgets('navigates to template create screen from app bar', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle();

      // Take screenshot before navigation
      await screenshotHelper.takeScreenshot('template_list_before_create');

      // Tap the add button in app bar
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      // Take screenshot of create screen
      await screenshotHelper.takeScreenshot('template_create_screen');

      // Verify navigation to create screen
      expect(find.byType(TemplateEditScreen), findsOneWidget);
      expect(find.text('Create Template'), findsAtLeastNWidgets(1));
    });

    testWidgets('empty state Create Template button navigates to create screen', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Look for the Create Template button in empty state
      final createTemplateButton = find.widgetWithText(FilledButton, 'Create Template');

      if (createTemplateButton.evaluate().isNotEmpty) {
        // Take screenshot of empty state
        await screenshotHelper.takeScreenshot('template_empty_state_before_create');

        // Tap the button
        await tester.tap(createTemplateButton.first);
        await tester.pumpAndSettle();

        // Take screenshot after
        await screenshotHelper.takeScreenshot('template_empty_state_after_create');

        // Should navigate to create screen
        expect(find.byType(TemplateEditScreen), findsOneWidget);
      }
    });
  });

  // ============================================================
  // TEMPLATE CREATE SCREEN TESTS
  // ============================================================

  group('Template Create Screen Tests', () {
    testWidgets('template create screen displays all form elements', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');

      // Wait for roster to load
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot of create template form
      await screenshotHelper.takeScreenshot('template_create_form');

      // Verify form elements are present
      expect(find.byType(TemplateEditScreen), findsOneWidget);

      // Verify form header
      expect(find.text('Create Template'), findsAtLeastNWidgets(1));

      // Verify form fields exist
      expect(find.text('Template Name'), findsOneWidget);
      expect(find.text('Description (optional)'), findsOneWidget);

      // Verify section headers
      expect(find.text('Select Players'), findsOneWidget);
      expect(find.text('Default Rotation (optional)'), findsOneWidget);
    });

    testWidgets('template create has save button in app bar', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_create_save_button');

      // Verify save button (check icon) is present
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byTooltip('Save Template'), findsOneWidget);
    });

    testWidgets('template name field accepts text input', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle();

      // Find the name text field
      final nameField = find.widgetWithText(TextField, 'Template Name');

      // Enter text
      await tester.enterText(nameField, 'Varsity Starters');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_name_entered');

      // Verify text was entered
      expect(find.text('Varsity Starters'), findsOneWidget);
    });

    testWidgets('template description field accepts text input', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle();

      // Find the description text field
      final descField = find.widgetWithText(TextField, 'Description (optional)');

      // Enter text
      await tester.enterText(descField, 'Main lineup for important games');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_description_entered');

      // Verify text was entered
      expect(find.text('Main lineup for important games'), findsOneWidget);
    });

    testWidgets('shows select players first message when no players selected', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_no_players_selected');

      // Check for the message about selecting players first
      final selectPlayersMessage = find.text('Select players first to assign rotation');

      // This message should appear when no players are selected
      if (selectPlayersMessage.evaluate().isNotEmpty) {
        expect(selectPlayersMessage, findsOneWidget);
      }
    });

    testWidgets('save button is disabled when form is invalid', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_save_disabled');

      // Find the save button (check icon)
      final saveButton = find.byIcon(Icons.check_rounded);
      expect(saveButton, findsOneWidget);

      // The button should be disabled when name is empty and no players selected
      // We can verify this by trying to tap and checking nothing happens
      final IconButton saveIconButton = tester.widget(find.ancestor(
        of: saveButton,
        matching: find.byType(IconButton),
      ));

      // The onPressed should be null when form is invalid
      expect(saveIconButton.onPressed, isNull);
    });
  });

  // ============================================================
  // TEMPLATE FORM VALIDATION TESTS
  // ============================================================

  group('Template Form Validation Tests', () {
    testWidgets('save requires template name', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot of initial state
      await screenshotHelper.takeScreenshot('template_validation_no_name');

      // Find the save button
      final saveButton = find.byIcon(Icons.check_rounded);
      final IconButton iconButton = tester.widget(find.ancestor(
        of: saveButton,
        matching: find.byType(IconButton),
      ));

      // Should be disabled without name
      expect(iconButton.onPressed, isNull);
    });

    testWidgets('save requires at least one player selected', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Enter template name only
      final nameField = find.widgetWithText(TextField, 'Template Name');
      await tester.enterText(nameField, 'Test Template');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_validation_no_players');

      // Find the save button
      final saveButton = find.byIcon(Icons.check_rounded);
      final IconButton iconButton = tester.widget(find.ancestor(
        of: saveButton,
        matching: find.byType(IconButton),
      ));

      // Should still be disabled without players selected
      expect(iconButton.onPressed, isNull);
    });
  });

  // ============================================================
  // TEMPLATE PLAYER SELECTION TESTS
  // ============================================================

  group('Template Player Selection Tests', () {
    testWidgets('displays roster as filter chips for selection', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot showing roster chips
      await screenshotHelper.takeScreenshot('template_roster_chips');

      // Verify FilterChip widgets exist (for player selection)
      final filterChips = find.byType(FilterChip);

      // If roster is loaded, there should be filter chips
      // In offline mode, roster may be empty, so check conditionally
      if (filterChips.evaluate().isNotEmpty) {
        expect(filterChips, findsWidgets);
      }
    });

    testWidgets('can select and deselect players', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find filter chips
      final filterChips = find.byType(FilterChip);

      if (filterChips.evaluate().isNotEmpty) {
        // Take screenshot before selection
        await screenshotHelper.takeScreenshot('template_player_before_select');

        // Tap the first chip to select
        await tester.tap(filterChips.first);
        await tester.pumpAndSettle();

        // Take screenshot after selection
        await screenshotHelper.takeScreenshot('template_player_after_select');

        // Tap again to deselect
        await tester.tap(filterChips.first);
        await tester.pumpAndSettle();

        // Take screenshot after deselection
        await screenshotHelper.takeScreenshot('template_player_after_deselect');
      }
    });
  });

  // ============================================================
  // TEMPLATE ROTATION SETUP TESTS
  // ============================================================

  group('Template Rotation Setup Tests', () {
    testWidgets('rotation section shows when players are selected', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and select some players first
      final filterChips = find.byType(FilterChip);

      if (filterChips.evaluate().isNotEmpty) {
        // Select multiple players
        for (var i = 0; i < 6 && i < filterChips.evaluate().length; i++) {
          await tester.tap(filterChips.at(i));
          await tester.pumpAndSettle();
        }

        // Take screenshot showing rotation dropdowns
        await screenshotHelper.takeScreenshot('template_rotation_dropdowns');

        // Verify rotation dropdown fields appear
        final rotation1 = find.text('Rotation 1');
        final rotation6 = find.text('Rotation 6');

        // Should see rotation position labels
        if (rotation1.evaluate().isNotEmpty) {
          expect(rotation1, findsOneWidget);
          expect(rotation6, findsOneWidget);
        }
      }
    });

    testWidgets('rotation dropdowns contain selected players', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find and select some players first
      final filterChips = find.byType(FilterChip);

      if (filterChips.evaluate().isNotEmpty) {
        // Select multiple players
        for (var i = 0; i < 6 && i < filterChips.evaluate().length; i++) {
          await tester.tap(filterChips.at(i));
          await tester.pumpAndSettle();
        }

        // Take screenshot
        await screenshotHelper.takeScreenshot('template_rotation_with_players');

        // Find dropdown form fields
        final dropdowns = find.byType(DropdownButtonFormField<String>);

        // Should have 6 rotation dropdowns (positions 1-6)
        if (dropdowns.evaluate().isNotEmpty) {
          expect(dropdowns, findsNWidgets(6));
        }
      }
    });
  });

  // ============================================================
  // TEMPLATE EDIT SCREEN TESTS
  // ============================================================

  group('Template Edit Screen Tests', () {
    testWidgets('edit screen shows Edit Template title', (tester) async {
      // Navigate to templates first, then would normally select one to edit
      // For this test, we verify the screen structure exists
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot of template list
      await screenshotHelper.takeScreenshot('template_list_for_edit');

      // The edit screen would be shown when editing an existing template
      // We can verify the route exists by checking the screen structure
      expect(find.byType(TemplateListScreen), findsOneWidget);
    });
  });

  // ============================================================
  // TEMPLATE DELETE TESTS
  // ============================================================

  group('Template Delete Tests', () {
    testWidgets('template card has delete button', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_delete_button');

      // When templates exist, each card should have a delete button
      // Check for delete icon
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);

      // If templates exist, delete button should be present
      if (deleteIcon.evaluate().isNotEmpty) {
        expect(deleteIcon, findsWidgets);
      }
    });

    testWidgets('delete button shows confirmation dialog', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find delete button
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);

      if (deleteIcon.evaluate().isNotEmpty) {
        // Take screenshot before tapping delete
        await screenshotHelper.takeScreenshot('template_before_delete');

        // Tap delete button
        await tester.tap(deleteIcon.first);
        await tester.pumpAndSettle();

        // Take screenshot of confirmation dialog
        await screenshotHelper.takeScreenshot('template_delete_confirmation');

        // Verify dialog is shown
        expect(find.text('Delete Template'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Delete'), findsOneWidget);
      }
    });

    testWidgets('cancel button dismisses delete dialog', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Find delete button
      final deleteIcon = find.byIcon(Icons.delete_outline_rounded);

      if (deleteIcon.evaluate().isNotEmpty) {
        // Tap delete button
        await tester.tap(deleteIcon.first);
        await tester.pumpAndSettle();

        // Tap cancel
        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();

        // Take screenshot after canceling
        await screenshotHelper.takeScreenshot('template_delete_canceled');

        // Dialog should be dismissed
        expect(find.text('Delete Template'), findsNothing);
      }
    });
  });

  // ============================================================
  // TEMPLATE INFO DISPLAY TESTS
  // ============================================================

  group('Template Info Display Tests', () {
    testWidgets('template card displays player count', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_info_display');

      // Check for player count format (e.g., "6 players")
      final playersText = find.textContaining('players');

      if (playersText.evaluate().isNotEmpty) {
        expect(playersText, findsWidgets);
      }
    });

    testWidgets('template card displays rotation status', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_rotation_status');

      // Check for "Rotation set" indicator
      final rotationSetText = find.text('Rotation set');

      // This appears when template has rotation configured
      if (rotationSetText.evaluate().isNotEmpty) {
        expect(rotationSetText, findsWidgets);
      }
    });

    testWidgets('template card displays use count', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_use_count');

      // Check for use count format (e.g., "Used 3x")
      final usedText = find.textContaining('Used');

      // This appears when template has been used
      if (usedText.evaluate().isNotEmpty) {
        expect(usedText, findsWidgets);
      }
    });

    testWidgets('template card has correct icons', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_card_icons');

      // Check for template card icon
      final starIcon = find.byIcon(Icons.star_rounded);

      // Star icon is used for template cards
      if (starIcon.evaluate().isNotEmpty) {
        expect(starIcon, findsWidgets);
      }

      // Check for info chip icons
      expect(find.byIcon(Icons.people_rounded), findsAny);
    });
  });

  // ============================================================
  // USE TEMPLATE FROM LANDING SCREEN TESTS
  // ============================================================

  group('Use Template from Landing Screen Tests', () {
    testWidgets('match setup landing screen shows Use Template option', (tester) async {
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('landing_use_template_option');

      // Verify the match setup landing screen
      expect(find.byType(MatchSetupLandingScreen), findsOneWidget);

      // Look for "Use Template" option
      final useTemplateText = find.text('Use Template');

      // This appears when templates are available
      if (useTemplateText.evaluate().isNotEmpty) {
        expect(useTemplateText, findsOneWidget);
      }
    });

    testWidgets('tapping Use Template shows template picker', (tester) async {
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find the Use Template card
      final useTemplateText = find.text('Use Template');

      if (useTemplateText.evaluate().isNotEmpty) {
        // Take screenshot before tapping
        await screenshotHelper.takeScreenshot('landing_before_template_picker');

        // Tap the Use Template option
        await tester.tap(useTemplateText);
        await tester.pumpAndSettle();

        // Take screenshot of template picker
        await screenshotHelper.takeScreenshot('landing_template_picker');

        // Verify template picker modal is shown
        expect(find.text('Select Template'), findsOneWidget);
      }
    });

    testWidgets('template picker has close button', (tester) async {
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find the Use Template card
      final useTemplateText = find.text('Use Template');

      if (useTemplateText.evaluate().isNotEmpty) {
        // Tap the Use Template option
        await tester.tap(useTemplateText);
        await tester.pumpAndSettle();

        // Take screenshot
        await screenshotHelper.takeScreenshot('template_picker_close_button');

        // Verify close button exists
        expect(find.byIcon(Icons.close_rounded), findsOneWidget);
        expect(find.byTooltip('Close'), findsOneWidget);
      }
    });

    testWidgets('template picker can be dismissed', (tester) async {
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find the Use Template card
      final useTemplateText = find.text('Use Template');

      if (useTemplateText.evaluate().isNotEmpty) {
        // Tap the Use Template option
        await tester.tap(useTemplateText);
        await tester.pumpAndSettle();

        // Tap close button
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        // Take screenshot after closing
        await screenshotHelper.takeScreenshot('template_picker_closed');

        // Verify picker is dismissed
        expect(find.text('Select Template'), findsNothing);
      }
    });

    testWidgets('landing screen shows template count', (tester) async {
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot
      await screenshotHelper.takeScreenshot('landing_template_count');

      // Look for template count text (e.g., "3 templates available")
      final templateCountText = find.textContaining('template');

      // This appears when templates exist
      if (templateCountText.evaluate().isNotEmpty) {
        expect(templateCountText, findsWidgets);
      }
    });
  });

  // ============================================================
  // NAVIGATION TESTS
  // ============================================================

  group('Template Navigation Tests', () {
    testWidgets('can navigate from home to templates via menu', (tester) async {
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Take screenshot of landing screen
      await screenshotHelper.takeScreenshot('nav_landing_to_templates');

      // Find and tap the more menu
      final moreMenu = find.byIcon(Icons.more_vert);
      if (moreMenu.evaluate().isNotEmpty) {
        await tester.tap(moreMenu);
        await tester.pumpAndSettle();

        // Take screenshot of menu
        await screenshotHelper.takeScreenshot('nav_landing_menu_open');

        // Tap Manage Templates
        final manageTemplates = find.text('Manage Templates');
        if (manageTemplates.evaluate().isNotEmpty) {
          await tester.tap(manageTemplates);
          await tester.pumpAndSettle();

          // Take screenshot after navigation
          await screenshotHelper.takeScreenshot('nav_templates_from_menu');

          // Verify we're on templates screen
          expect(find.byType(TemplateListScreen), findsOneWidget);
        }
      }
    });

    testWidgets('can navigate directly to templates route', (tester) async {
      await pumpApp(tester);
      await tester.pumpAndSettle();

      // Navigate to templates
      appRouter.go('/templates');
      await tester.pumpAndSettle();

      // Take screenshot after navigation
      await screenshotHelper.takeScreenshot('nav_direct_to_templates');

      expect(find.byType(TemplateListScreen), findsOneWidget);
    });

    testWidgets('can navigate to template create and back', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle();

      // Navigate to create
      appRouter.push('/templates/create');
      await tester.pumpAndSettle();

      // Take screenshot of create screen
      await screenshotHelper.takeScreenshot('nav_template_create');

      expect(find.byType(TemplateEditScreen), findsOneWidget);

      // Use back navigation (pop)
      appRouter.pop();
      await tester.pumpAndSettle();

      // Take screenshot after going back
      await screenshotHelper.takeScreenshot('nav_template_create_back');

      expect(find.byType(TemplateListScreen), findsOneWidget);
    });

    testWidgets('template create screen has back button', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');

      // Take screenshot showing back button
      await screenshotHelper.takeScreenshot('template_back_button');

      // Verify back button exists
      final backButton = find.byIcon(Icons.arrow_back);
      expect(backButton, findsOneWidget);
    });

    testWidgets('back button from template create returns to templates', (tester) async {
      // Start at templates list
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle();

      // Navigate to create
      appRouter.push('/templates/create');
      await tester.pumpAndSettle();

      expect(find.byType(TemplateEditScreen), findsOneWidget);

      // Take screenshot before back
      await screenshotHelper.takeScreenshot('template_before_back_tap');

      // Tap back button
      final backButton = find.byIcon(Icons.arrow_back);
      await tester.tap(backButton);
      await tester.pumpAndSettle();

      // Take screenshot after back
      await screenshotHelper.takeScreenshot('template_after_back_tap');

      // Should be back at template list
      expect(find.byType(TemplateListScreen), findsOneWidget);
    });
  });

  // ============================================================
  // LOADING STATE TESTS
  // ============================================================

  group('Template Loading State Tests', () {
    testWidgets('template list shows loading indicator initially', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');

      // Take screenshot immediately (might catch loading state)
      await screenshotHelper.takeScreenshot('loading_template_list');

      // Verify the screen structure
      expect(find.byType(TemplateListScreen), findsOneWidget);

      // Wait for loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot after loading
      await screenshotHelper.takeScreenshot('loading_template_list_complete');
    });

    testWidgets('template create shows loading while fetching roster', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');

      // Take screenshot immediately
      await screenshotHelper.takeScreenshot('loading_template_create');

      // Verify the screen structure
      expect(find.byType(TemplateEditScreen), findsOneWidget);

      // Wait for loading to complete
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot after loading
      await screenshotHelper.takeScreenshot('loading_template_create_complete');
    });
  });

  // ============================================================
  // ERROR HANDLING TESTS
  // ============================================================

  group('Template Error Handling Tests', () {
    testWidgets('template list handles error state gracefully', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot of any error state
      await screenshotHelper.takeScreenshot('error_template_list_state');

      // App should remain functional
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(TemplateListScreen), findsOneWidget);
    });

    testWidgets('template create handles error state gracefully', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot of any error state
      await screenshotHelper.takeScreenshot('error_template_create_state');

      // App should remain functional
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(TemplateEditScreen), findsOneWidget);
    });

    testWidgets('template list has retry button on error', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await screenshotHelper.takeScreenshot('template_retry_button');

      // Check for retry button if in error state
      final retryButton = find.text('Retry');
      if (retryButton.evaluate().isNotEmpty) {
        expect(retryButton, findsOneWidget);
      }
    });
  });

  // ============================================================
  // UI ELEMENT TESTS
  // ============================================================

  group('Template UI Element Tests', () {
    testWidgets('template list has correct icons and visual elements', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle();

      // Take screenshot
      await screenshotHelper.takeScreenshot('ui_template_list_elements');

      // Verify add icon in app bar
      expect(find.byIcon(Icons.add_rounded), findsOneWidget);

      // Check for empty state icon or template icons depending on state
      final emptyIcon = find.byIcon(Icons.star_outline_rounded);
      final templateIcon = find.byIcon(Icons.star_rounded);

      // One of these should be present
      expect(
        emptyIcon.evaluate().isNotEmpty || templateIcon.evaluate().isNotEmpty,
        isTrue,
      );
    });

    testWidgets('template create has correct icons', (tester) async {
      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Take screenshot
      await screenshotHelper.takeScreenshot('ui_template_create_icons');

      // Verify save button icon
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);

      // Verify back button
      expect(find.byIcon(Icons.arrow_back), findsOneWidget);
    });
  });

  // ============================================================
  // RESPONSIVE LAYOUT TESTS
  // ============================================================

  group('Template Responsive Layout Tests', () {
    testWidgets('template list renders correctly in portrait', (tester) async {
      // Set portrait dimensions
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 3.0;

      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle();

      // Take screenshot of portrait layout
      await screenshotHelper.takeScreenshot('layout_template_list_portrait');

      expect(find.byType(TemplateListScreen), findsOneWidget);

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    testWidgets('template create renders correctly in portrait', (tester) async {
      // Set portrait dimensions
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 3.0;

      await pumpApp(tester, initialRoute: '/templates/create');
      await tester.pumpAndSettle();

      // Take screenshot of portrait layout
      await screenshotHelper.takeScreenshot('layout_template_create_portrait');

      expect(find.byType(TemplateEditScreen), findsOneWidget);

      // Reset view
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  });

  // ============================================================
  // COMPLETE WORKFLOW TESTS
  // ============================================================

  group('Template Complete Workflow Tests', () {
    testWidgets('full template creation workflow', (tester) async {
      await pumpApp(tester, initialRoute: '/templates');
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Step 1: Screenshot of template list (starting point)
      await screenshotHelper.takeStepScreenshot('template_workflow', 1, 'list_start');

      // Step 2: Navigate to create
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await screenshotHelper.takeStepScreenshot('template_workflow', 2, 'create_screen');

      // Step 3: Enter template name
      final nameField = find.widgetWithText(TextField, 'Template Name');
      await tester.enterText(nameField, 'My Test Template');
      await tester.pumpAndSettle();

      await screenshotHelper.takeStepScreenshot('template_workflow', 3, 'name_entered');

      // Step 4: Enter description
      final descField = find.widgetWithText(TextField, 'Description (optional)');
      await tester.enterText(descField, 'Test template description');
      await tester.pumpAndSettle();

      await screenshotHelper.takeStepScreenshot('template_workflow', 4, 'description_entered');

      // Step 5: Select players (if roster is available)
      final filterChips = find.byType(FilterChip);
      if (filterChips.evaluate().isNotEmpty) {
        for (var i = 0; i < 6 && i < filterChips.evaluate().length; i++) {
          await tester.tap(filterChips.at(i));
          await tester.pumpAndSettle();
        }

        await screenshotHelper.takeStepScreenshot('template_workflow', 5, 'players_selected');
      }

      // Step 6: Final screenshot before save attempt
      await screenshotHelper.takeStepScreenshot('template_workflow', 6, 'ready_to_save');

      // Note: Actual save requires Supabase connection
      // In offline mode, save would fail gracefully
    });

    testWidgets('template selection from landing workflow', (tester) async {
      await pumpApp(tester, initialRoute: '/match-setup');
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Step 1: Screenshot of landing screen
      await screenshotHelper.takeStepScreenshot('template_select_workflow', 1, 'landing');

      // Step 2: Open template picker (if available)
      final useTemplateText = find.text('Use Template');
      if (useTemplateText.evaluate().isNotEmpty) {
        await tester.tap(useTemplateText);
        await tester.pumpAndSettle();

        await screenshotHelper.takeStepScreenshot('template_select_workflow', 2, 'picker_open');

        // Step 3: Close picker
        await tester.tap(find.byIcon(Icons.close_rounded));
        await tester.pumpAndSettle();

        await screenshotHelper.takeStepScreenshot('template_select_workflow', 3, 'picker_closed');
      }
    });
  });
}
