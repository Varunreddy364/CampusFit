import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:campusfit/bmi_page.dart';

void main() {
  testWidgets('BMIPage renders Health Insights Dashboard components and recalculates', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: BMIPage(),
      ),
    );

    await tester.pump();

    // Verify Title
    expect(find.text('Health Insights & BMI'), findsOneWidget);

    // Verify Daily Motivation
    expect(find.text('DAILY MOTIVATION'), findsOneWidget);

    // Verify Weekly Health Focus
    expect(find.text("THIS WEEK'S HEALTH FOCUS"), findsOneWidget);

    // Verify Biometric Input
    expect(find.text('Biometric Input'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Height'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Weight'), findsOneWidget);

    // Verify Primary KPI cards
    expect(find.text('BMI SCORE'), findsOneWidget);
    expect(find.text('HEALTH SCORE'), findsOneWidget);

    // Verify 10-tier scale & Gauge
    expect(find.text('Visual BMI Gauge'), findsOneWidget);
    expect(find.text('10 Health Zones'), findsOneWidget);

    // Verify Ideal Weight & Calorie Targets
    expect(find.text('Ideal Weight Estimator & Calories'), findsOneWidget);
    expect(find.text('Estimated Daily Calorie Targets (TDEE)'), findsOneWidget);

    // Verify Goal-oriented recommendations
    expect(find.text('Goal-Oriented Recommendations'), findsOneWidget);

    // Verify Medical Disclaimer
    expect(find.textContaining('IMPORTANT DISCLAIMER: This module provides educational health guidance'), findsOneWidget);

    // Test calculation: enter height = 180, weight = 81 (BMI = 81 / (1.8 * 1.8) = 25.0 -> Slightly Above Optimal)
    final heightField = find.widgetWithText(TextField, 'Height');
    final weightField = find.widgetWithText(TextField, 'Weight');

    await tester.enterText(heightField, '180');
    await tester.enterText(weightField, '81');
    await tester.tap(find.text('Recalculate'));
    await tester.pump();

    expect(find.text('25.0'), findsOneWidget);
    expect(find.text('Slightly Above Optimal'), findsWidgets);
  });
}
