import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfit/nutrition_page.dart';

void main() {
  testWidgets('NutritionPage renders brand header, metrics, insights, and handles empty state gracefully', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NutritionPage(userId: 101),
      ),
    );

    // Initial pump
    await tester.pump();

    // Verify AppBar Title
    expect(find.text('Nutrition & Wellness'), findsWidgets);

    // Wait for async futures to complete/settle
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Brand Header Subtitle
    expect(find.text('Fuel your mind & body for peak campus performance'), findsOneWidget);

    // Verify Daily Target & Calories Ring section
    expect(find.text('Daily Target'), findsOneWidget);
    expect(find.text('Macronutrients Breakdown'), findsOneWidget);
    expect(find.text('Protein'), findsOneWidget);
    expect(find.text('Carbohydrates'), findsOneWidget);
    expect(find.text('Healthy Fats'), findsOneWidget);

    // Verify Personalized Insights Header
    expect(find.text('Personalized Nutrition Insights'), findsOneWidget);

    // Verify Weekly Trend Chart Card
    expect(find.text('Weekly Calorie Intake Trend'), findsOneWidget);

    // Verify Floating Action Button to Log Meal
    expect(find.text('Log Meal'), findsWidgets);

    // Verify empty state text when no meals logged
    expect(find.text('No meals logged today yet'), findsOneWidget);
  });

  testWidgets('NutritionPage opens meal logging modal bottom sheet upon tapping Log Meal', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NutritionPage(userId: 101),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));

    // Tap FloatingActionButton
    final fab = find.widgetWithText(FloatingActionButton, 'Log Meal');
    expect(fab, findsOneWidget);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Verify Bottom Sheet elements
    expect(find.text('Log a Meal'), findsOneWidget);
    expect(find.text('Meal Category'), findsOneWidget);
    expect(find.text('Breakfast'), findsWidgets);
    expect(find.text('Lunch'), findsWidgets);
    expect(find.text('Dinner'), findsWidgets);
    expect(find.text('Snacks'), findsWidgets);
    expect(find.text('Food Name *'), findsOneWidget);
    expect(find.text('Calories (kcal) *'), findsOneWidget);
    expect(find.text('Auto-Est'), findsOneWidget);
    expect(find.text('Save Meal Log'), findsOneWidget);
  });
}
