

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:fieldnote_pos/main.dart' as pos;

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('POS dashboard opens checkout', (WidgetTester tester) async {
    await tester.pumpWidget(const pos.CounterApp());
    for (var attempt = 0;
        attempt < 20 && find.text('NET SALES · TODAY').evaluate().isEmpty;
        attempt++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }

    expect(find.text('FreshBuy'), findsOneWidget);
    expect(find.text('NET SALES · TODAY'), findsOneWidget);
    expect(find.text('Tuesday, October 27'), findsOneWidget);
    expect(find.text('Good morning'), findsNothing);

    await tester.tap(find.text('Sell'));
    await tester.pumpAndSettle();

    expect(find.text('New sale'), findsOneWidget);
    expect(find.text('Fresh bread'), findsOneWidget);
    expect(find.text('Rwenzori water'), findsOneWidget);
    expect(find.text('💧'), findsNWidgets(2));

    await tester.tap(find.byIcon(Icons.people_outline));
    await tester.pumpAndSettle();

    expect(find.text('Namiro Zainah'), findsOneWidget);
    expect(find.text('Kato Jerome'), findsOneWidget);
    expect(find.text('Ashanti Ada'), findsOneWidget);
    expect(find.text('ashanti.a@gmail.com'), findsOneWidget);
  });
}
