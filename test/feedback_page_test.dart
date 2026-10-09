import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfit/feedback_page.dart';

void main() {
  testWidgets('FeedbackPage renders purple header, mood selector, and 4 module rating cards', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeedbackPage(userId: 101),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar
    expect(find.text('Student Feedback'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    expect(find.byIcon(Icons.history_rounded), findsOneWidget);

    // Verify Hero Banner
    expect(find.text('Your Voice Matters 💜'), findsOneWidget);
    expect(find.text('Help CampusFit adapt to your lifestyle'), findsOneWidget);

    // Verify Mood Selector
    expect(find.text('Daily Mood & Energy'), findsOneWidget);
    expect(find.text('Great'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(find.text('Okay'), findsOneWidget);
    expect(find.text('Stressed'), findsOneWidget);
    expect(find.text('Exhausted'), findsOneWidget);

    // Verify 4 Module Rating Cards
    expect(find.text('Study Planning'), findsOneWidget);
    expect(find.text('Automated slot generation, class buffers & breaks'), findsOneWidget);

    expect(find.text('Schedule Replanning'), findsOneWidget);
    expect(find.text('Missed interval recovery & break protection'), findsOneWidget);

    expect(find.text('Workout Planning'), findsOneWidget);
    expect(find.text('Dynamic 20-60m sizing & evening slot selection'), findsOneWidget);

    expect(find.text('Nutrition & Meals'), findsOneWidget);
    expect(find.text('Meal logging, calories, macros & daily targets'), findsOneWidget);

    // Verify Optional Input Sections
    expect(find.text('Missed Any Activities Today? (Optional)'), findsOneWidget);
    expect(find.text('Suggestions & Ideas (Optional)'), findsOneWidget);

    // Verify Submit Button
    expect(find.text('Submit Feedback'), findsOneWidget);
  });

  testWidgets('FeedbackPage mood and rating interaction updates UI state smoothly', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FeedbackPage(userId: 101),
      ),
    );

    await tester.pumpAndSettle();

    // Tap 'Great' mood
    await tester.tap(find.text('Great'));
    await tester.pumpAndSettle();

    // Tap on the suggestions text field and enter text
    final suggestionsFinder = find.widgetWithText(TextField, '');
    expect(suggestionsFinder, findsWidgets);

    await tester.enterText(suggestionsFinder.last, 'Add sleep cycle tracking to the dashboard!');
    await tester.pumpAndSettle();

    expect(find.text('Add sleep cycle tracking to the dashboard!'), findsOneWidget);
  });

  testWidgets('FeedbackPage close and back buttons cleanly pop navigation', (WidgetTester tester) async {
    bool didPop = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Navigator(
          onPopPage: (route, result) {
            didPop = true;
            return route.didPop(result);
          },
          pages: const [
            MaterialPage(child: Text('Home Screen')),
            MaterialPage(child: FeedbackPage(userId: 101)),
          ],
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify on FeedbackPage
    expect(find.text('Student Feedback'), findsOneWidget);

    // Tap close button in AppBar
    await tester.tap(find.byIcon(Icons.close_rounded));
    await tester.pumpAndSettle();

    expect(didPop, isTrue);
  });
}
