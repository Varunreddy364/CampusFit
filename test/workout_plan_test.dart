import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfit/workout_plan_page.dart';

void main() {
  testWidgets('WorkoutPlanPage renders appbar, streak ribbon, and generate button on empty state', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: WorkoutPlanPage(userId: 101),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify Title
    expect(find.text('Workout Plan'), findsOneWidget);

    // After async load finishes (mocked/failed gracefully)
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Consistency & History ribbon
    expect(find.text('Workout Consistency & History'), findsOneWidget);
    expect(find.text('Streak'), findsOneWidget);
    expect(find.text('This Week'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Rate'), findsOneWidget);

    // Verify empty state generate plan prompt
    expect(find.text('No Workout Generated for Today'), findsOneWidget);
    expect(find.text("Generate Today's Workout Plan"), findsOneWidget);
  });
}
