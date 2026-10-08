import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfit/study_plan_page.dart';

void main() {
  testWidgets('StudyPlanPage renders header banner, Generate Plan button, and empty state', (WidgetTester tester) async {
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

    // Verify Empty State elements
    expect(find.text('No Study Plan Yet'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Generate Plan Now'), findsOneWidget);
  });
}
