import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfit/academic_tasks_page.dart';

void main() {
  testWidgets('AcademicTasksPage renders quick add buttons and opens modal for each type', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AcademicTasksPage(userId: 1),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify Title
    expect(find.text('Academic Tasks'), findsOneWidget);

    // Verify dedicated Quick Add buttons:
    expect(find.text('Add Assignment'), findsOneWidget);
    expect(find.text('Add Exam'), findsOneWidget);
    expect(find.text('Add Project'), findsOneWidget);
    expect(find.text('Add Lab Task'), findsOneWidget);

    // Tap "Add Assignment"
    await tester.tap(find.text('Add Assignment'));
    await tester.pumpAndSettle();

    // Verify modal elements
    expect(find.text('Add ASSIGNMENT'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('Task Type'), findsOneWidget);
    expect(find.text('Deadline'), findsOneWidget);
    expect(find.text('Est. Hours'), findsOneWidget);
    expect(find.text('Priority'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Save Task'), findsOneWidget);

    // Test validation on empty title
    await tester.tap(find.widgetWithText(ElevatedButton, 'Save Task'));
    await tester.pump();

    expect(find.text('Task title is required'), findsOneWidget);
  });
}
