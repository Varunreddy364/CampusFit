import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfit/dashboard_page.dart';

void main() {
  testWidgets('DashboardPage renders header, carousel, progress cards, challenges, quick actions, and bottom nav', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardPage(userId: 101, userName: 'Madhesh'),
      ),
    );

    // Initial frame
    await tester.pump();

    // Verify AppBar Title and User Initial Avatar
    expect(find.text('CampusFit'), findsOneWidget);
    expect(find.text('M'), findsWidgets); // 'M' in avatar and header

    // Settle async timers and futures
    await tester.pump(const Duration(milliseconds: 600));

    // Verify Greeting Header
    expect(find.text('Madhesh 👋'), findsOneWidget);
    expect(find.text('“Small steps every day lead to big results.”'), findsOneWidget);

    // Verify Carousel content
    expect(find.text("Today's Motivation"), findsOneWidget);
    expect(find.text("Stay consistent.\nResults will follow."), findsOneWidget);

    // Verify Today's Progress Section & Cards
    expect(find.text("Today's Progress"), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Study Tasks'), findsOneWidget);
    expect(find.text('Water Intake'), findsOneWidget);

    // Verify Daily Challenges & Streak & Health Snapshot
    expect(find.text('Daily Challenges'), findsOneWidget);
    expect(find.text('Complete 20m exercise'), findsOneWidget);
    expect(find.text('Log at least 3 meals'), findsOneWidget);
    expect(find.text('Complete 2 study tasks'), findsOneWidget);
    expect(find.text('Drink 2.5 L of water'), findsOneWidget);

    expect(find.text('Days'), findsOneWidget);
    expect(find.text('Health Snapshot'), findsOneWidget);

    // Verify Quick Actions
    expect(find.text('Quick Actions'), findsOneWidget);
    expect(find.text('Log a Meal'), findsOneWidget);
    expect(find.text('Workout Plan'), findsOneWidget);
    expect(find.text('Study Plan'), findsOneWidget);
    expect(find.text('Academic Schedule'), findsOneWidget);
    expect(find.text('View Profile'), findsOneWidget);
    expect(find.text('Health & BMI'), findsOneWidget);
    expect(find.text('Academic Tasks'), findsOneWidget);
    expect(find.text('Feedback'), findsOneWidget);

    // Verify Today's Meals & Schedule cards
    expect(find.text("Today's Meals"), findsOneWidget);
    expect(find.text("Today's Schedule"), findsOneWidget);

    // Verify Bottom Navigation Bar
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Planner'), findsOneWidget);
    expect(find.text('Fitness'), findsOneWidget);
    expect(find.text('Nutrition'), findsOneWidget);
    expect(find.text('Analytics'), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
  });

  testWidgets('DashboardPage opens water intake dialog on tapping water card', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DashboardPage(userId: 101, userName: 'Madhesh'),
      ),
    );

    await tester.pump(const Duration(milliseconds: 600));

    // Find and tap the Water Intake card
    final waterCard = find.text('Water Intake');
    expect(waterCard, findsOneWidget);
    await tester.tap(waterCard);
    await tester.pumpAndSettle();

    // Verify modal dialog opened
    expect(find.text('Track Water Intake 💧'), findsOneWidget);
    expect(find.text('+250 ml'), findsOneWidget);
    expect(find.text('+500 ml'), findsOneWidget);
  });
}
