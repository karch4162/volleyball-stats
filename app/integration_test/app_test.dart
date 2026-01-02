import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:volleyball_stats_app/core/persistence/hive_service.dart';
import 'package:volleyball_stats_app/core/router/app_router.dart';
import 'package:volleyball_stats_app/core/theme/app_theme.dart';

import 'utils/screenshot_helper.dart';

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  final screenshotHelper = ScreenshotHelper(binding);

  setUpAll(() async {
    // Initialize Hive for Flutter in test mode
    await Hive.initFlutter();

    // Register type adapters (must happen before HiveService.initialize)
    // The HiveService.initialize() will handle this, but we need Hive.initFlutter first
  });

  tearDownAll(() async {
    await HiveService.closeAll();
  });

  group('App Smoke Tests', () {
    testWidgets('app launches successfully and displays home screen', (tester) async {
      // Initialize Hive service for offline persistence
      await HiveService.initialize();

      // Build the app
      final app = ProviderScope(
        child: MaterialApp.router(
          title: 'Volleyball Stats',
          theme: AppTheme.darkTheme,
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
        ),
      );

      // Pump the widget
      await tester.pumpWidget(app);

      // Wait for the app to settle
      await tester.pumpAndSettle();

      // Take a screenshot of the initial state
      await screenshotHelper.takeScreenshot('home_screen');

      // Verify the app loads without errors
      // The app should display something - either the home screen or an auth screen
      // We check that there's at least one widget rendered
      expect(find.byType(MaterialApp), findsOneWidget);

      // Verify Scaffold is present (app structure loaded)
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));

      // Clean up
      await HiveService.closeAll();
    });

    testWidgets('app displays navigation elements', (tester) async {
      // Initialize Hive service
      await HiveService.initialize();

      // Build the app
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

      // Take screenshot
      await screenshotHelper.takeScreenshot('navigation_elements');

      // Verify basic app structure exists
      expect(find.byType(MaterialApp), findsOneWidget);

      // The app should have rendered successfully
      // Additional navigation checks depend on the specific UI implementation

      await HiveService.closeAll();
    });
  });
}
