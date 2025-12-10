import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:volleyball_stats_app/features/history/widgets/player_stats_controls.dart';

void main() {
  group('PlayerStatsControls', () {
    testWidgets('displays sort dropdown with current value', (tester) async {
      String sortBy = 'efficiency';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerStatsControls(
              currentSortBy: sortBy,
              onSortChanged: (value) => sortBy = value,
            ),
          ),
        ),
      );

      expect(find.text('Sort by:'), findsOneWidget);
      expect(find.byType(DropdownButton<String>), findsOneWidget);
    });

    testWidgets('calls onSortChanged when sort option selected', (tester) async {
      String sortBy = 'efficiency';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerStatsControls(
              currentSortBy: sortBy,
              onSortChanged: (value) => sortBy = value,
            ),
          ),
        ),
      );

      // Tap dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Select "Kills" option
      await tester.tap(find.text('Kills').last);
      await tester.pumpAndSettle();

      expect(sortBy, equals('kills'));
    });

    testWidgets('displays all sort options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerStatsControls(
              currentSortBy: 'efficiency',
              onSortChanged: (value) {},
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Check all options are present
      expect(find.text('Total Points'), findsWidgets);
      expect(find.text('Attack Efficiency'), findsWidgets);
      expect(find.text('Kills'), findsWidgets);
      expect(find.text('Blocks'), findsWidgets);
      expect(find.text('Aces'), findsWidgets);
      expect(find.text('Service Pressure'), findsWidgets);
      expect(find.text('Digs'), findsWidgets);
      expect(find.text('Assists'), findsWidgets);
      expect(find.text('First Ball Kills'), findsWidgets);
      expect(find.text('Jersey Number'), findsWidgets);
    });

    testWidgets('shows ascending/descending toggle when provided', (tester) async {
      bool ascending = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerStatsControls(
              currentSortBy: 'efficiency',
              onSortChanged: (value) {},
              ascending: ascending,
              onAscendingChanged: (value) => ascending = value,
            ),
          ),
        ),
      );

      // Should show arrow icon button
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
    });

    testWidgets('toggles sort order on icon button tap', (tester) async {
      bool ascending = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PlayerStatsControls(
                  currentSortBy: 'efficiency',
                  onSortChanged: (value) {},
                  ascending: ascending,
                  onAscendingChanged: (value) {
                    setState(() => ascending = value);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially descending
      expect(find.byIcon(Icons.arrow_downward), findsOneWidget);

      // Tap to toggle
      await tester.tap(find.byIcon(Icons.arrow_downward));
      await tester.pumpAndSettle();

      // Now ascending
      expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
      expect(ascending, isTrue);
    });

    testWidgets('hides ascending toggle when callback not provided', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerStatsControls(
              currentSortBy: 'efficiency',
              onSortChanged: (value) {},
              ascending: false,
              // onAscendingChanged not provided
            ),
          ),
        ),
      );

      // Should not show arrow icon
      expect(find.byIcon(Icons.arrow_downward), findsNothing);
      expect(find.byIcon(Icons.arrow_upward), findsNothing);
    });

    testWidgets('shows view toggle when showViewToggle is true', (tester) async {
      bool isTableView = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerStatsControls(
              currentSortBy: 'efficiency',
              onSortChanged: (value) {},
              showViewToggle: true,
              isTableView: isTableView,
              onViewModeChanged: (value) => isTableView = value,
            ),
          ),
        ),
      );

      // Should show both view mode buttons
      expect(find.byIcon(Icons.view_list), findsOneWidget);
      expect(find.byIcon(Icons.table_chart), findsOneWidget);
    });

    testWidgets('hides view toggle when showViewToggle is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerStatsControls(
              currentSortBy: 'efficiency',
              onSortChanged: (value) {},
              showViewToggle: false,
            ),
          ),
        ),
      );

      // Should not show view mode buttons
      expect(find.byIcon(Icons.view_list), findsNothing);
      expect(find.byIcon(Icons.table_chart), findsNothing);
    });

    testWidgets('toggles view mode on button tap', (tester) async {
      bool isTableView = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return PlayerStatsControls(
                  currentSortBy: 'efficiency',
                  onSortChanged: (value) {},
                  showViewToggle: true,
                  isTableView: isTableView,
                  onViewModeChanged: (value) {
                    setState(() => isTableView = value);
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially card view (isTableView = false)
      expect(isTableView, isFalse);

      // Tap table view button
      await tester.tap(find.byIcon(Icons.table_chart));
      await tester.pumpAndSettle();

      expect(isTableView, isTrue);

      // Tap card view button
      await tester.tap(find.byIcon(Icons.view_list));
      await tester.pumpAndSettle();

      expect(isTableView, isFalse);
    });

    testWidgets('displays tooltips on view mode buttons', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerStatsControls(
              currentSortBy: 'efficiency',
              onSortChanged: (value) {},
              showViewToggle: true,
              isTableView: false,
              onViewModeChanged: (value) {},
            ),
          ),
        ),
      );

      // Find tooltip widgets
      final cardViewTooltip = find.ancestor(
        of: find.byIcon(Icons.view_list),
        matching: find.byType(Tooltip),
      );
      final tableViewTooltip = find.ancestor(
        of: find.byIcon(Icons.table_chart),
        matching: find.byType(Tooltip),
      );

      expect(cardViewTooltip, findsOneWidget);
      expect(tableViewTooltip, findsOneWidget);
    });

    testWidgets('dropdown has correct number of options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerStatsControls(
              currentSortBy: 'efficiency',
              onSortChanged: (value) {},
            ),
          ),
        ),
      );

      // Open dropdown
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();

      // Count dropdown menu items (each option appears twice in the widget tree)
      expect(find.byType(DropdownMenuItem<String>), findsAtLeastNWidgets(10));
    });
  });
}
