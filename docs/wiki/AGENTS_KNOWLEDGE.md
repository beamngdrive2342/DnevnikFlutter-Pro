# Знания для ИИ-агентов (критичные грабли)

Короткие уроки, которые дорого переоткрывать. Проверяй актуальность перед применением.

---

## Тестирование (Flutter)

### `flutter_dotenv 6.0.1` — нет `testLoad()`
- ❌ `dotenv.testLoad(fileInput: '...')` — **не существует** в 6.0.1 (метод из старых версий/устаревших гайдов).
- ✅ Для тестов: `dotenv.loadFromString(envString: 'FIREBASE_WEB_API_KEY=test')`.
- Проявляется как `The method 'testLoad' isn't defined for the type 'DotEnv'` в `flutter analyze`.

### `ClassSchedule` — глобальная мутабельная статика, течёт между тестами
- Любой тест, трогающий `ClassSchedule` (`loadFromFirestoreDoc`, `load`, геттеры), ОБЯЗАН делать `ClassSchedule.reset()` в `setUp` и `tearDown`. Иначе состояние протекает в соседние тесты.
- Это же — основная мотивация Фазы 2 (перевод глобальной статики на Riverpod).

### widget_test для `DnevnikApp`
- `DnevnikApp` — `ConsumerWidget`, требует `ProviderScope` сверху, иначе падает.
- При `SharedPreferences.setMockInitialValues({})` путь `AuthNotifier._checkSession` (classId == null) НЕ ходит в сеть и НЕ трогает `flutter_secure_storage` — тест детерминирован.
- ❌ Не использовать `pumpAndSettle`: на splash-экране (`AuthGate`) крутится бесконечный `CircularProgressIndicator` → вечное ожидание. Один `pump()` + `expect(find.byType(MaterialApp), findsOneWidget)`.

---

## Общее
- Рабочая директория Flutter-проекта — `src/`. Все команды `flutter ...` запускать оттуда.
- `flutter analyze` возвращает ненулевой код при наличии любых `info` (не только ошибок). Смотреть на суть, а не только на exit code.
