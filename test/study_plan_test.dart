import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfit/study_plan_page.dart';

void main() {
  testWidgets('StudyPlanPage renders header banner, Generate Plan button, Replan button, and empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StudyPlanPage(userId: 1),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify Title
    expect(find.text('Study Plan'), findsOneWidget);

    // Verify Header Banner
    expect(find.text('Study Plan Engine'), findsOneWidget);
    expect(find.text('Automated timetable-aware slot scheduling'), findsOneWidget);

    // Verify "Generate Study Plan" button
    expect(find.widgetWithText(ElevatedButton, 'Generate Study Plan'), findsOneWidget);

    // Verify "Couldn't Follow Your Plan? Replan" button
    expect(find.widgetWithText(OutlinedButton, "Couldn't Follow Your Plan? Replan"), findsOneWidget);

    // Verify Empty State elements
    expect(find.text('No Study Plan Yet'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Generate Plan Now'), findsOneWidget);
  });

  testWidgets('Tapping Replan button opens modal bottom sheet with pickers and analyze button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: StudyPlanPage(userId: 1),
      ),
    );

    await tester.pump();

    // Tap the Replan button
    final replanButton = find.widgetWithText(OutlinedButton, "Couldn't Follow Your Plan? Replan");
    expect(replanButton, findsOneWidget);
    await tester.tap(replanButton);
    await tester.pumpAndSettle();

    // Verify bottom sheet appears with title and description
    expect(find.text('Replan Missed Study Interval'), findsOneWidget);
    expect(find.textContaining('Enter the exact time interval you were unable to follow'), findsOneWidget);

    // Verify Date and Time interval input elements
    expect(find.text('Date of Missed Plan'), findsOneWidget);
    expect(find.text('Missed Time Interval'), findsOneWidget);
    expect(find.text('Missed From'), findsOneWidget);
    expect(find.text('Missed Until'), findsOneWidget);

    // Verify Analyze button
    expect(find.text('Analyze & Preview Replanning'), findsOneWidget);
  });
}

