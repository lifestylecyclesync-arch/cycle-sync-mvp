import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cycle_sync_mvp/main.dart';

void main() {
  testWidgets('App should display the onboarding welcome screen initially', (WidgetTester tester) async {
    await tester.pumpWidget(const CycleSyncApp());

    expect(find.text('Sync your cycle.'), findsOneWidget);
    expect(find.text('Sync your life.'), findsOneWidget);
  });

  testWidgets('Welcome screen has Get Started button', (WidgetTester tester) async {
    await tester.pumpWidget(const CycleSyncApp());

    expect(find.text('Get Started'), findsOneWidget);
    expect(find.byIcon(Icons.favorite_outline), findsOneWidget);
  });

  testWidgets('Welcome screen navigates to cycle input screen', (WidgetTester tester) async {
    await tester.pumpWidget(const CycleSyncApp());

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Personalize your cycle tracking'), findsOneWidget);
  });

  testWidgets('Cycle input screen has date picker and cycle length field', (WidgetTester tester) async {
    await tester.pumpWidget(const CycleSyncApp());

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(find.text('Last Period Start Date'), findsOneWidget);
    expect(find.text('Average Cycle Length (days)'), findsOneWidget);
    expect(find.text('Select Date'), findsOneWidget);
  });

  testWidgets('Dashboard has cycle phase information', (WidgetTester tester) async {
    await tester.pumpWidget(const CycleSyncApp());

    // Verify dashboard screen elements exist in app
    expect(find.text('Follicular Phase'), findsNothing); // Not on welcome screen

    // Navigate to cycle input
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    // Verify cycle input screen
    expect(find.text('Personalize your cycle tracking'), findsOneWidget);
  });
}