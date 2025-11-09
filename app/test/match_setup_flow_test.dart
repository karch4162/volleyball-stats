import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volleyball_stats_app/features/match_setup/match_setup_flow.dart';

Future<void> _configureLargeWindow(WidgetTester tester) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  binding.window.physicalSizeTestValue = const Size(1080, 1920);
  binding.window.devicePixelRatioTestValue = 1.0;
  addTearDown(() {
    binding.window.clearPhysicalSizeTestValue();
    binding.window.clearDevicePixelRatioTestValue();
  });
}

void main() {
  testWidgets('renders match metadata step by default', (tester) async {
    await _configureLargeWindow(tester);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MatchSetupFlow(),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Match'), findsOneWidget);
    expect(find.byType(Stepper), findsOneWidget);
    expect(find.text('Select match date'), findsOneWidget);
  });

  testWidgets('requires at least six players before advancing past roster', (tester) async {
    await _configureLargeWindow(tester);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MatchSetupFlow(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fill metadata minimal requirements.
    await tester.enterText(find.byType(TextField).at(0), 'Ridgeview Hawks');
    await tester.tap(find.text('Select match date'));
    await tester.pumpAndSettle();
    final today = DateTime.now().day.toString();
    await tester.tap(find.text(today).first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Proceed to roster step.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Attempt to continue without enough players.
    await tester.tap(find.text('Continue'));
    await tester.pump();

    expect(
      find.text('Select at least six players for your match roster.'),
      findsOneWidget,
    );
  });

  testWidgets('requires full rotation assignments before summary', (tester) async {
    await _configureLargeWindow(tester);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: MatchSetupFlow(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Fill metadata.
    await tester.enterText(find.byType(TextField).at(0), 'Summit Bears');
    await tester.tap(find.text('Select match date'));
    await tester.pumpAndSettle();
    final today = DateTime.now().day.toString();
    await tester.tap(find.text(today).first);
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Continue to roster.
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Select six players.
    final rosterChips = find.byType(FilterChip);
    for (var i = 0; i < 6; i++) {
      await tester.tap(rosterChips.at(i));
      await tester.pump();
    }

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Attempt to continue without assigning rotation.
    final continueButton = find.widgetWithText(FilledButton, 'Continue');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    await tester.pump();

    expect(
      find.text('Assign all six rotation spots before continuing.'),
      findsOneWidget,
    );
  });
}

