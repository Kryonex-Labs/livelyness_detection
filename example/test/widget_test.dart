// Minimal smoke test for the example app.

import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Example app renders the detect button', (tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Detect Livelyness'), findsOneWidget);
  });
}
