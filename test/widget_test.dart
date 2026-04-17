import 'package:flutter_test/flutter_test.dart';

import 'package:dnevnik_app/main.dart';
import 'package:dnevnik_app/screens/auth_gate.dart';

void main() {
  testWidgets('App shows role selector on launch', (WidgetTester tester) async {
    await tester.pumpWidget(const DnevnikApp());
    await tester.pump();

    expect(find.byType(AuthGate), findsOneWidget);
  });
}
