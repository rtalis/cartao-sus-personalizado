// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cns_personalizado/main.dart';

void main() {
  testWidgets(
    'Test CnsPersonalizado widget',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: CnsPersonalizado(),
      ));

      // Check if the initial text is displayed
      expect(find.text('Insert Data into Picture'), findsOneWidget);

      // Trigger taps on buttons
      await tester.tap(find.text('Selecione uma imagem'));
      await tester.pump();

      // Ensure that the image is displayed after selecting an image
      expect(find.byType(Image), findsOneWidget);

      // Trigger the Print PDF button
      await tester.tap(find.text('Print PDF'));
      await tester.pump();
      expect(find.text('ss'), findsOneWidget);

      // Add more test cases as needed to verify the widget's behavior

      /*// Build our app and trigger a frame.
    await tester.pumpWidget(MyApp());

    // Verify that our counter starts at 0.
    //expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  */
    },
  );
}
