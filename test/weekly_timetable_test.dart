import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfit/weekly_timetable_page.dart';

void main() {
  testWidgets('WeeklyTimetablePage renders day columns, 8 AM - 8 PM rows, and Add Class modal', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WeeklyTimetablePage(userId: 1),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify Title and Subtitle
    expect(find.text('Weekly Timetable'), findsOneWidget);
    expect(find.text('College Timetable (8 AM - 8 PM)'), findsOneWidget);

    // Verify day headers
    expect(find.text('Monday'), findsOneWidget);
    expect(find.text('Tuesday'), findsOneWidget);
    expect(find.text('Wednesday'), findsOneWidget);
    expect(find.text('Thursday'), findsOneWidget);
    expect(find.text('Friday'), findsOneWidget);
    expect(find.text('Saturday'), findsOneWidget);
    expect(find.text('Sunday'), findsOneWidget);

    // Verify hourly rows from 8 AM to 8 PM
    expect(find.text('8 AM'), findsOneWidget);
    expect(find.text('9 AM'), findsOneWidget);
    expect(find.text('10 AM'), findsOneWidget);
    expect(find.text('11 AM'), findsOneWidget);
    expect(find.text('12 PM'), findsOneWidget);

    // Verify Floating Action Button
    expect(find.widgetWithText(FloatingActionButton, 'Add Class'), findsOneWidget);

    // Tap Add Class button
    await tester.tap(find.widgetWithText(FloatingActionButton, 'Add Class'));
    await tester.pumpAndSettle();

    // Verify Add Class modal elements
    expect(find.text('Add Academic Class'), findsOneWidget);
    expect(find.text('Subject Name'), findsOneWidget);
    expect(find.text('Day of the Week'), findsOneWidget);
    expect(find.text('Start Time'), findsOneWidget);
    expect(find.text('End Time'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Save Class'), findsOneWidget);
  });
}
