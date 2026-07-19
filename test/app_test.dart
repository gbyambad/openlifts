import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:openlifts/app.dart';
import 'package:openlifts/core/app_bootstrap.dart';
import 'package:openlifts/features/home/application/today_providers.dart';

void main() {
  testWidgets('app boots to the nav shell once startup completes',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Skip real asset seeding and DB reads in the widget test.
          bootstrapProvider.overrideWith((ref) async {}),
          todayProvider.overrideWith((ref) => null),
        ],
        child: const OpenLiftsApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Today'), findsWidgets);
  });
}
