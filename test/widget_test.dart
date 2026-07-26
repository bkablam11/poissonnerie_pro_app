import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_poissonnerie_pro/main.dart';

void main() {
  testWidgets('PoissonnerieApp test build smoke test',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: PoissonnerieApp(),
      ),
    );

    expect(find.text('POISSONNERIE PRO'), findsOneWidget);
  });
}
