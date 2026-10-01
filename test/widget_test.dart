import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:locadora_veiculos/main.dart';

void main() {
  testWidgets('Lista exibe as locações iniciais', (WidgetTester tester) async {
    await tester.pumpWidget(const LocadoraApp());

    await tester.tap(find.text('Locações'));
    await tester.pumpAndSettle();

    expect(find.byType(Card), findsNWidgets(2));
    expect(find.text('Contrato nº 1001'), findsOneWidget);
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
