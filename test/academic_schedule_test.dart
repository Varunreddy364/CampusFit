import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfit/academic_schedule_page.dart';

void main() {
  testWidgets('AcademicSchedulePage renders correctly and opens Add Class sheet', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AcademicSchedulePage(userId: 1),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify App Bar
    expect(find.text('Academic Schedule'), findsOneWidget);

    // Verify Add Class FloatingActionButton
    expect(find.widgetWithText(FloatingActionButton, 'Add Class'), findsOneWidget);

    // Tap the Add Class button to open sheet
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Class'));
    await tester.pumpAndSettle();

    // Verify sheet elements
    expect(find.text('Add New Class'), findsOneWidget);
    expect(find.text('Subject Name'), findsOneWidget);
    expect(find.text('Day of the Week'), findsOneWidget);
    expect(find.text('Start Time'), findsOneWidget);
    expect(find.text('End Time'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Save Class'), findsOneWidget);

    // Verify Day Dropdown has 'Monday'
    expect(find.text('Monday'), findsWidgets);

    // Try submitting empty subject
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Class'));
    await tester.pump();

    // Should display validation error
    expect(find.text('Subject Name is required'), findsOneWidget);
  });
}
