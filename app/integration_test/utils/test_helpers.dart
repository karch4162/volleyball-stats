import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/core/persistence/hive_service.dart';
import 'package:volleyball_stats_app/core/router/app_router.dart';
import 'package:volleyball_stats_app/core/theme/app_theme.dart';

/// Helper to pump the app and wait for it to settle
Future<void> pumpAppAndSettle(WidgetTester tester, {List<Override>? overrides}) async {
  // Initialize Hive for tests
  await HiveService.initialize();

  final app = ProviderScope(
    overrides: overrides ?? [],
    child: MaterialApp.router(
      title: 'Volleyball Stats',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routerConfig: appRouter,
    ),
  );

  await tester.pumpWidget(app);
  await tester.pumpAndSettle();
}

/// Navigate to a specific route
Future<void> navigateTo(WidgetTester tester, String route) async {
  appRouter.go(route);
  await tester.pumpAndSettle();
}

/// Wait for a widget to appear with timeout
Future<void> waitForWidget(
  WidgetTester tester,
  Finder finder, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final endTime = DateTime.now().add(timeout);

  while (DateTime.now().isBefore(endTime)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) {
      return;
    }
  }

  // Final check to let the test fail with a good error message
  expect(finder, findsOneWidget);
}

/// Tap a widget and wait for animations to settle
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

/// Find widget by key
Finder findByKey(String key) => find.byKey(Key(key));

/// Find widget by text
Finder findByText(String text) => find.text(text);

/// Find widget by type
Finder findByType<T extends Widget>() => find.byType(T);

/// Find widget by icon
Finder findByIcon(IconData icon) => find.byIcon(icon);

/// Enter text in a text field found by key
Future<void> enterTextByKey(
  WidgetTester tester,
  String key,
  String text,
) async {
  final finder = find.byKey(Key(key));
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Enter text in a text field found by the finder
Future<void> enterText(
  WidgetTester tester,
  Finder finder,
  String text,
) async {
  await tester.enterText(finder, text);
  await tester.pumpAndSettle();
}

/// Scroll until a widget is visible
Future<void> scrollUntilVisible(
  WidgetTester tester,
  Finder finder, {
  Finder? scrollable,
  double delta = 100.0,
}) async {
  final scrollableFinder = scrollable ?? find.byType(Scrollable).first;

  await tester.scrollUntilVisible(
    finder,
    delta,
    scrollable: scrollableFinder,
  );
  await tester.pumpAndSettle();
}

/// Check if a widget is visible
bool isWidgetVisible(WidgetTester tester, Finder finder) {
  return finder.evaluate().isNotEmpty;
}

/// Clean up after tests
Future<void> cleanUpTests() async {
  await HiveService.closeAll();
}
