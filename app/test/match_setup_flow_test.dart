import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:volleyball_stats_app/features/match_setup/match_setup_flow.dart';

void main() {
  testWidgets('renders match metadata step by default', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MatchSetupFlow(),
      ),
    );

    expect(find.text('Match'), findsOneWidget);
    expect(find.byType(Stepper), findsOneWidget);
    expect(find.text('Select match date'), findsOneWidget);
  });
}

