import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:dnevnik_app/main.dart';

void main() {
  testWidgets('App стартует внутри ProviderScope без падения', (tester) async {
    // Пустые prefs -> сессии нет -> AuthNotifier не ходит в сеть/secure storage.
    SharedPreferences.setMockInitialValues({});
    // main() грузит .env через dotenv; в тесте подменяем тестовым значением.
    dotenv.loadFromString(envString: 'FIREBASE_WEB_API_KEY=test');

    await tester.pumpWidget(const ProviderScope(child: DnevnikApp()));
    // Один кадр: показывается splash (AuthStatus.initial). Не используем
    // pumpAndSettle — на экране бесконечный CircularProgressIndicator.
    await tester.pump();

    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
